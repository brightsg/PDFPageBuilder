//
//  TSPageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 12/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

/*
 
 Notes on element layout.
 
 Data map co-ordinates
 =====================
 
 1. Data map co-ordinates are in mm measured from the top left of the page.
 2. All dimensions default to mm. Caller must set self.geometryAttributeScale accordingly for other units.
 3. Fontsizes are in mm. Caller must set self.fontsizeAttributeScale accordingly for other units.
 4. Vertical alignment references and offsets such as Top and Bottom are not flipped.
 
 PageBuilder co-ordinates
 ========================
 
 1. PageBuilder uses a flipped invariant 72 dpi co-ordinate system.
 2. All dimensions are in points.
 3. Fontsizes are in points.
 
 NOTE:
 
 PDFPage natively uses a non flipped invariant 72 dpi co-ordinate system. See https://developer.apple.com/library/Mac/documentation/GraphicsImaging/Conceptual/PDFKitGuide/PDFKit_Prog_Conc/PDFKit_Prog_Conc.html#//apple_ref/doc/uid/TP40001863-CH201-CHDIGGFD
 
 */

#import "TSPageBuilder.h"
#import "TSPageDoubleAggregator.h"
#import "TSPageSpacingAggregator.h"

// categories
#import "NSString+PageBuilder.h"
#import "NSColor+PageBuilder.h"
#import "NSDate+PageBuilder.h"
#import "NSMutableArray+PageBuilder.h"
#import "NSRegularExpression+PageBuilder.h"
#import "NSXMLElement+PageBuilder.h"

// Uncomment TS_LOG_VERBOSE to enable verbose logging
//#define TS_LOG_VERBOSE

#define TSLogWarn(fmt,...) NSLog(fmt, ##__VA_ARGS__)
#ifdef TS_LOG_VERBOSE
#define TSLogVerbose(fmt,...) NSLog(fmt, ##__VA_ARGS__)
#else
#define TSLogVerbose(fmt,...)
#endif

NSString *TSKeyYIncrement = @"YIncrement";
NSString *TSKeyYSpacing = @"YSpacing";

NSString *TSKeyRotation = @"Rotation";
NSString *TSKeyBorderBrush = @"BorderBrush";
NSString *TSKeyBorderThickness = @"BorderThickness";
NSString *TSKeyBorderBackground = @"BorderBackground";
NSString *TSSKeyTextPadding = @"TextPadding";
NSString *TSKeyTextAlignment = @"TextAlignment";
NSString *TSKeyTextVerticalAlignment = @"TextVerticalAlignment";
NSString *TSKeyTextWrapping = @"TextWrapping";
NSString *TSKeyFontFamily = @"FontFamily";
NSString *TSKeyFontSize = @"FontSize";
NSString *TSKeyFontStretch = @"FontStretch";
NSString *TSKeyFontStyle = @"FontStyle";
NSString *TSKeyFontWeight = @"FontWeight";
NSString *TSKeyLineHeight = @"LineHeight";
NSString *TSKeyForeground = @"Foreground";
           
typedef NS_ENUM(NSInteger, TSStyleNameID) {
    TSStyleRotation,
    TSStyleBorderBrush,
    TSStyleBorderThickness,
    TSStyleBorderBackground,
    TSStyleTextPadding,
    TSStyleTextAlignment,
    TSStyleTextVerticalAlignment,
    TSStyleTextWrapping,
    TSStyleFontFamily,
    TSStyleFontSize,
    TSStyleFontStretch,
    TSStyleFontStyle,
    TSStyleFontWeight,
    TSStyleLineHeight,
    TSStyleForeground,
};

@interface TSPageBuilder ()
@property (strong) NSMutableDictionary *stacks;
@property (strong) NSMutableArray *pageItems;
@property (strong,nonatomic) NSRegularExpression *propertyRegex;
@property (assign) BOOL gcIsLoaded;
@property (strong,readwrite) NSDictionary *constantElementDictionary;
@property (strong, nonatomic) NSMutableDictionary *constantElements;
@end

@implementation TSPageBuilder

#pragma mark -
#pragma mark Styling support

+ (NSDictionary *)styleInfo
{
    static NSDictionary *styles = nil;
    if (!styles) {
        styles = @{TSKeyRotation : @(TSStyleRotation),
                   TSKeyBorderBrush : @(TSStyleBorderBrush),
                   TSKeyBorderThickness : @(TSStyleBorderThickness),
                   TSKeyBorderBackground : @(TSStyleBorderBackground),
                   TSSKeyTextPadding : @(TSStyleTextPadding),
                   TSKeyTextAlignment : @(TSStyleTextAlignment),
                   TSKeyTextVerticalAlignment : @(TSStyleTextVerticalAlignment),
                   TSKeyTextWrapping : @(TSStyleTextWrapping),
                   TSKeyFontFamily : @(TSStyleFontFamily),
                   TSKeyFontSize : @(TSStyleFontSize),
                   TSKeyFontStretch : @(TSStyleFontStretch),
                   TSKeyFontStyle : @(TSStyleFontStyle),
                   TSKeyFontWeight : @(TSStyleFontWeight),
                   TSKeyLineHeight : @(TSStyleLineHeight),
                   TSKeyForeground : @(TSStyleForeground)
                   };
    }
    
    return styles;
}

+ (NSArray *)styleAttributeNames
{
    static NSArray *styleNames = nil;
    if (!styleNames) {
        styleNames = [self styleInfo].allKeys;
    }
    
    return styleNames;
}

#pragma mark -
#pragma mark Numeric support

+ (NSNumberFormatter *)decimalNumberFormatter
{
    static NSNumberFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    return formatter;
}

#pragma mark -
#pragma mark Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        
        _highlightPageItemContainerRects = NO;
        
        // identify the stacks
        // all the attribute styles have matching stacks.
        NSMutableArray *stackNames = [NSMutableArray arrayWithArray:[[self class] styleAttributeNames]];
        [stackNames addObject:TSKeyYIncrement];
        [stackNames addObject:TSKeyYSpacing];
        
        // allocate the stacks.
        self.stacks = [NSMutableDictionary dictionaryWithCapacity:stackNames.count];
        for (NSString *styleName in stackNames) {
            self.stacks[styleName] = [NSMutableArray arrayWithCapacity:5];
        }
        
        // initialise collections
        self.pageItems = [NSMutableArray arrayWithCapacity:20];
        
        // set font size scale.
        // the default font size is in millimetres so scale millimeters to points.
        // clients can modify if want to say specify fontsize in points.
        self.fontSizeAttributeScale = TSPB_SCALE_MM_TO_PTS;
        
        // set geometry scale
        // the default input map geometry data is in millimetres so scale millimeters to points
        self.geometryAttributeScale = TSPB_SCALE_MM_TO_PTS;

    }
    
    return self;
}

#pragma mark -
#pragma mark Element parsing

- (void)parseConstantElement:(NSXMLElement *)xe withObject:(id)object
{
    // contract
    NSAssert(object, @"object is nil");
    NSAssert(xe, @"element is nil");
    NSAssert([xe.name isEqualToString:@"Constant"], @"element name is invalid");
    
    // get the key
    NSString *key = [[xe attributeForName:@"Name"] stringValue];
    if (!key) {
        TSLogWarn(@"Missing Name attribute : %@", xe);
        return;
    }
    
    // get the value
    NSString *value =[ [xe attributeForName:@"Value"] stringValue];
    if (!value) {
        TSLogWarn(@"Missing Value attribute : %@", xe);
        return;
    }
    
    // the page builder does not utilise the constants directly but the client or
    // subclasses may interrogate the constants to customise behaviour or page layout.
    self.constantElements[key] = value;
}

- (void)parseConditionsForElement:(NSXMLElement *)xeParent withObject:(id)object
{
    //
    // Process the conditions to remove child elements that do not pass the condition test
    // note that in this pass we remove all conditions in the entire DOM.
    //
    NSError *error = nil;
    NSArray *xnConditions = [xeParent nodesForXPath:@"child::Condition|descendant::Condition[ancestor::Text]" error:&error];
    for (NSXMLNode *xnCondition in xnConditions) {
        
        BOOL expressionResult = NO;
        
        // confirm element type
        if ([xnCondition kind] != NSXMLElementKind) {
            TSLogWarn(@"Unexpected node kind : %li", xnCondition.kind);
            continue;
        }
        NSXMLElement *xeCondition = (id)xnCondition;
        
        // get the expression element
        NSXMLNode *expressionAttribute = [xeCondition attributeForName:@"Expression"];
        NSString *expression = [expressionAttribute stringValue];
        
        //
        // expression may take the form (!){key} (AND|OR) (!){key} ...
        // so we pull out key values and evaluate the boolean expression
        //
        // note: this is a very simple parser!
        //
        NSRegularExpression *booleanRegex = [NSRegularExpression regularExpressionWithPattern:@" (AND|OR) " options:0 error:nil];
        NSArray *regexResults = [booleanRegex  matchesInString:expression options:0 range:NSMakeRange(0, expression.length)];

        NSUInteger location = 0;
        NSString *operationString = nil;

        // iterate over expression variables
        for (NSUInteger varIndex = 0; varIndex <= regexResults.count; varIndex++) {

            // use variable regex match if available
            NSTextCheckingResult *regexResult = nil;
            if (varIndex < regexResults.count) {
                regexResult = regexResults[varIndex];
            }

            // pull out the variable that precedes the regex match.
            // if no regex match pull out the remainder of the expression
            NSUInteger length =  regexResult ? regexResult.range.location - location : expression.length - location;
            NSString *varName = [expression substringWithRange:NSMakeRange(location, length)];

            // sanitize the variable name
            varName = [varName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            // a !prefix signifies negation
            BOOL isInverse = NO;
            if ([[varName substringToIndex:1] isEqualToString:@"!"]) {
                isInverse = YES;
                varName = [varName substringFromIndex:1];
            }

            // get boolean value for variable
            BOOL varResult = NO;
            id value = [object valueForKey:varName];
            if (value) {
                varResult = [value boolValue];
            }

            // negate variable
            if (isInverse) {
                varResult = !varResult;
            }

            // evaluate the current operation
            if (!operationString) {
                expressionResult = varResult;
            } else {
                
                if ([operationString isEqualToString:@" AND "]) {
                    
                    expressionResult &= varResult;
                    
                } else if ([operationString isEqualToString:@" OR "]) {
                    
                    expressionResult |= varResult;
                    
                } else {
                    NSAssert(@"invalid boolean operation : %@", operationString);
                }
            }

            // if we have a regex result then extract the matching operation
            if (regexResult) {
                
                operationString = [expression substringWithRange:regexResult.range];

                // increment the location to skip the current match location
                location = regexResult.range.location + regexResult.range.length;
            }

        }
        
        // get the condition parent
        NSXMLElement *xeConditionParent = xeCondition.parent.kind == NSXMLElementKind ? (id)xeCondition.parent : nil;
        if (!xeConditionParent) {
            TSLogWarn(@"Unexpected node kind : %li", xnCondition.kind);
            continue;
        }
        
        // we want to preserve the child nodes of the selected True or False node.
        // we do this be moving them up to the level of the condition node and thene deleting the condition node.
        NSString *nodeName = expressionResult ? @"True" : @"False";
        NSArray *xeMatching = [xeCondition elementsForName:nodeName];
        for (NSXMLElement *xeMatch in xeMatching) {
            
            // get the match node children
            NSArray *xnMatchChildren = [xeMatch nodesForXPath:@"*|text()" error:&error];
            
            // remove the match node
            [xeCondition tspb_removeChild:xeMatch];
            
            // re-insert the match node children at the index of the condition
            for (NSXMLNode *xnMatchChild in xnMatchChildren) {
                [xeMatch tspb_removeChild:xnMatchChild]; // cannot insert a child if it already has a parent
                [xeConditionParent insertChild:xnMatchChild atIndex:[xeConditionParent.children indexOfObject:xeCondition]]; // reinsert
            }
        }
        
        // remove the condition element
        [xeConditionParent removeChildAtIndex:[xeConditionParent.children indexOfObject:xeCondition]];
        
    }
    
    // contract, confirm all conditions dealt with
    xnConditions = [xeParent nodesForXPath:@"child::Condition|descendant::Condition[ancestor::Text]" error:&error];
    NSAssert(xnConditions.count == 0, @"Not all conditions have been parsed");

}

#pragma mark -
#pragma mark Page loading and layout

- (NSArray *)addLayoutForElement:(NSXMLElement *)xeRoot withObject:(id)object
{
    return [self processPageForElement:xeRoot withObject:object options:@{@"doLayout" : @YES}];
}

- (NSArray *)loadElement:(NSXMLElement *)xeRoot
{
    return [self processPageForElement:xeRoot withObject:@{} options:@{@"doLayout" : @NO}];
}

#pragma mark -
#pragma mark Page processing

- (void)preprocessPageForElement:(NSXMLElement *)xeParent withObject:(id)object
{
    // parse all conditions within the page
    [self parseConditionsForElement:xeParent withObject:object];
}

- (void)postprocessPageForElement:(NSXMLElement *)xeParent withObject:(id)object
{
    // make the constant elements accessible
    self.constantElementDictionary = self.constantElements;
}

- (NSArray *)processPageForElement:(NSXMLElement *)xeRoot withObject:(id)object options:(NSDictionary *)options
{
    @try{
        
        //
        // do pre process
        //
        [self preprocessPageForElement:xeRoot withObject:object];

        //
        // process elements starting at the DOM root
        //
        [self processElement:xeRoot withObject:object options:options];
        
        //
        // do post process
        //
        [self postprocessPageForElement:xeRoot withObject:object];
    
    } @catch(NSException *e) {
        
        // for now we just raise again
        [e raise];
    }
    
    return self.pageItems;
}

#pragma mark -
#pragma mark Element processing

- (void)processElement:(NSXMLElement *)xeParent withObject:(id)object options:(NSDictionary *)options
{
    BOOL doLayout = [options[@"doLayout"] boolValue];
    
    // process each child element
    for (NSXMLElement *xe in [xeParent children]) {
        
        // element validation
        if (xe.kind != NSXMLElementKind) {
            
            // We only want to process elements at this level
            continue;
        }
        
        // Push
        if ([xe.name isEqualToString:@"Push"] && [xe attributeForName:@"Property"] && [xe attributeForName:@"Value"]) {
            
            if (!doLayout) continue;
            
            id key = [[xe attributeForName:@"Property"] stringValue];
            id value = [[xe attributeForName:@"Value"] stringValue];
            
            [self pushMapKey:key value:value];
            continue;
        }
        
        // Pop
        if ([xe.name isEqualToString:@"Pop"] && [xe attributeForName:@"Property"]) {
            
            if (!doLayout) continue;
            
            id key = [[xe attributeForName:@"Property"] stringValue];
            
            [self popMapKey:key];
            continue;
        }
        
        // Text
        if ([xe.name isEqualToString:@"Text"]) {
            
            if (!doLayout) continue;
            
            [self layoutTextualElement:xe withObject:object];
            continue;
        }
        
        // Image
        if ([xe.name isEqualToString:@"Image"]) {
            
            if (!doLayout) continue;
            
            [self layoutImageElement:xe withObject:object];
            continue;
            
        }
        
        // ForEach
        if ([xe.name isEqualToString:@"ForEach"]) {
            
            if (!doLayout) continue;
            
            [self layoutForeachElement:xe withObject:object];
            continue;
        }
        
        // Constant
        if ([xe.name isEqualToString:@"Constant"]) {
            
            [self parseConstantElement:xe withObject:object];
            continue;
        }
        
        // Hmm...
        TSLogWarn(@"Don't know what to do with this element: %@", xe);
    }
}

#pragma mark -
#pragma mark Element layout

- (void)layoutForeachElement:(NSXMLElement *)xe withObject:(id)object
{
    // contract
    NSAssert(object, @"object is nil");
    NSAssert(xe, @"element is nil");
    NSAssert([xe.name isEqualToString:@"ForEach"], @"element name is invalid");
    
    //
    // get a map object to iterate the ForEach tag over
    //
    NSString *objectKey = [[xe attributeForName:@"Enumerable"] stringValue];
    if (!objectKey) return;
    id objEnumerable = [object valueForKey:objectKey];
    
    NSMutableArray *objectArray = nil;
    
    //
    // get an object we can iterate over
    //
    if ([objEnumerable isKindOfClass:[NSDictionary class]]) {
        
        // make an array of dictionaries representing key/value pairs
        NSDictionary *dict = objEnumerable;
        objectArray = [NSMutableArray arrayWithCapacity:dict.count];
        for (id key in dict.allKeys) {
            
            // NOTE: is much better to send in an array of presorted keyValuePair like objects
            // as the the ourput order here is undefined.
            // we want an object with same properties as a managed KeyValuePair<TKey, TValue>
            id keyValuePair = @{@"key" : key, @"value" : dict[key]};
            [objectArray addObject:keyValuePair];
        }
        
    } else if ([objEnumerable isKindOfClass:[NSArray class]]) {
        
        // the objects in this array must respond to key and value
        objectArray = objEnumerable;
        
    } else {
        NSAssert(NO, @"Don't know how to iterate over object : %@", objEnumerable);
    }
    
    //
    // determine the vertical aggregation stategy to be used
    //
    NSMutableArray *aggregatorStack = nil;
    Class aggregatorClass = NULL;
    if ([xe attributeForName:@"Text.YIncrement"]) {
        
        TSPageDoubleAggregator *aggregator = [TSPageDoubleAggregator new];
        aggregator.index = 0;
        aggregator.multiplier = [xe tspb_attributeDoubleValueForName:@"Text.YIncrement"];
        aggregator.base = [xe attributeForName:@"Text.Y"] ? [xe tspb_attributeDoubleValueForName:@"Text.Y"] : 0.0;
        
        aggregatorStack = self.stacks[TSKeyYIncrement];
        [aggregatorStack tspb_push:aggregator];
        
        aggregatorClass = [aggregator class];
        
    } else if ([xe attributeForName:@"Text.YSpacing"]) {
        
        TSPageSpacingAggregator *aggregator = [TSPageSpacingAggregator new];
        aggregator.usage = 0;
        aggregator.offset = [xe tspb_attributeDoubleValueForName:@"Text.YSpacing"];
        aggregator.base = [xe attributeForName:@"Text.Y"] ? [xe tspb_attributeDoubleValueForName:@"Text.Y"] : 0.0;
        
        aggregatorStack = self.stacks[TSKeyYSpacing];
        [aggregatorStack tspb_push:aggregator];
        
        aggregatorClass = [aggregator class];
    }
    
    //
    // FromIndex attribute
    //
    NSInteger elementFromIndex = -1;
    BOOL elementHasFromIndex = [xe attributeForName:@"FromIndex"] ? YES : NO;
    if (elementHasFromIndex) {
        elementFromIndex = [xe tspb_attributeIntegerValueForName:@"FromIndex"];
    }
    
    //
    // ToIndex attribute
    //
    NSInteger elementToIndex = -1;
    BOOL elementHasToIndex = [xe attributeForName:@"ToIndex"] ? YES : NO;
    if (elementHasToIndex) {
        elementToIndex = [xe tspb_attributeIntegerValueForName:@"ToIndex"];
    }
    
    //
    // iterate over the object updating the aggregator as required
    //
    NSInteger itemIndex = 0;
    for (id item in objectArray) {
        
        // validate the item index
        itemIndex++;
        if (elementHasFromIndex && elementFromIndex > itemIndex) continue;
        if (elementHasToIndex && elementToIndex < itemIndex) break;
        
        // layout the element
        [self processElement:xe withObject:item options:@{@"doLayout" : @YES}];
        
        // update the vertical aggregator
        // Y increment
        if (aggregatorClass == [TSPageDoubleAggregator class]) {
            
            TSPageDoubleAggregator *aggregator = [aggregatorStack tspb_stackPeek];
            aggregator.index++;
            
            // Y spacing
        } else if (aggregatorClass == [TSPageSpacingAggregator class]) {
            
            TSPageSpacingAggregator *aggregator = [aggregatorStack tspb_stackPeek];
            aggregator.base += aggregator.usage + aggregator.offset;
            aggregator.usage = 0;
        }
    }
    
    // pop the aggregator
    [aggregatorStack tspb_pop];
    
}

- (void)layoutTextualElement:(NSXMLElement *)xe withObject:(id)object
{
    // contract
    NSAssert(object, @"object is nil");
    NSAssert(xe, @"element is nil");
    NSAssert([xe.name isEqualToString:@"Text"], @"element name is invalid");
    
    // push element attributes onto the stack
    NSArray *pushedAttributes = [self pushAttributesForElement:xe];

    // get the attributed string representation of the element
    NSMutableAttributedString *attrString = [self attributedStringForElement:xe withObject:object];
    
    // apply the Y aggregators if defined
    NSMutableArray *aggregatorStack = self.stacks[TSKeyYIncrement];
    if (aggregatorStack.count > 0) {
        
        TSPageDoubleAggregator *aggregator = [aggregatorStack tspb_stackPeek];
        double y = aggregator.base + aggregator.index * aggregator.multiplier;
        

        [xe tspb_addAttributeWithName:@"Y" doubleValue:y];
        
    } else {
        
        aggregatorStack = self.stacks[TSKeyYSpacing];
        if (aggregatorStack.count > 0) {
            TSPageSpacingAggregator *aggregator = [aggregatorStack tspb_stackPeek];
            double y = aggregator.base;

            [xe tspb_addAttributeWithName:@"Y" doubleValue:y];
        }
    }
    
    // get element rectangle
    NSRect elementRect = [self rectangleForElement:xe];
    
    // pad the element rect
    if ([self stackHasValueForName:TSSKeyTextPadding]) {
        NSDictionary *dict = [self.stacks[TSSKeyTextPadding] tspb_stackPeek];
        
        // NOTE: top and bottom are interpreted in the normal sense independent of the flipped co-ordinate context
        elementRect.origin.x += [dict[@"left"] doubleValue];
        elementRect.origin.y += [dict[@"top"] doubleValue];
        elementRect.size.width -= ([dict[@"left"] doubleValue] + [dict[@"right"] doubleValue]);
        elementRect.size.height -= ([dict[@"bottom"] doubleValue] + [dict[@"top"] doubleValue]);
    }
    

    // add the item
    TSPageTextItem *textItem = [self addTextItem:attrString rect:elementRect];
    
    // update the vertical aggregator usage
    aggregatorStack = self.stacks[TSKeyYSpacing];
    if (aggregatorStack.count > 0) {
        TSPageSpacingAggregator *aggregator = [aggregatorStack tspb_stackPeek];
        
        CGFloat usage = textItem.usedTextRect.size.height / self.geometryAttributeScale;
        
        if (usage > aggregator.usage) {
            aggregator.usage = usage;
        }
    }
    
    // pop the element attributes
    [self popAttributes:pushedAttributes];

}

- (void)layoutImageElement:(NSXMLElement *)xe withObject:(id)object
{
    // get the image source string
    NSString *sourceString = [[xe attributeForName:@"Source"] stringValue];
    
    // parse the source for a property key
    if (![self.propertyRegex tspb_isMatch:sourceString]) {
        TSLogWarn(@"No source property key found for image element");
        return;
    }
    
    // get the key from the text
    NSString *match = [self.propertyRegex tspb_firstMatch:sourceString];
    NSString *key = [self propertyKeyFromMatchString:match];
    
    id imageObject = [object valueForKey:key];
    NSData *imageData = nil;
    
    // query delegate to extract image data from object.
    if ([self.delegate respondsToSelector:@selector(imageDataForPageBuilder:key:object:)]) {
        imageData = [self.delegate imageDataForPageBuilder:self key:key object:imageObject];
    }

    // if object is NSData then use it directly
    else if ([imageObject isKindOfClass:[NSData class]]) {
        imageData = imageObject;
    }
    
    if (!imageData) {
        TSLogWarn(@"No image data for image source attribute : %@", sourceString);
        return;
    }

    // get image from data
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    
    // get element rectangle
    NSRect elementRect = [self rectangleForElement:xe];

    // add image item
    [self addImageItem:image rect:elementRect];

}

#pragma mark -
#pragma mark String key replacement

- (NSString *)replaceKeysInString:(NSString *)text fromObject:(id)object
{
    //
    // replace property keys with object values
    //
    while ([self.propertyRegex tspb_isMatch:text]) {
        
        // get the key from the text
        NSString *match = [self.propertyRegex tspb_firstMatch:text];
        NSString *key = [self propertyKeyFromMatchString:match];
        
        // extract trailing format specifier from the key name
        NSString *valueFormat = nil;
        NSRange r = [key rangeOfString:@":"];
        if (r.location != NSNotFound) {
            valueFormat = [key substringFromIndex:r.location + 1];
            key = [key substringToIndex:r.location];
        }
        
        // the key may represent a KVC style key path.
        NSArray *keyParts = [key componentsSeparatedByString:@"."];
        id keyedObject = object;
        id value = nil;
        for (NSString __strong *keyPart in keyParts) {
            
            // get the value
            value = [keyedObject valueForKey:keyPart];
            if (!value) {
                
                // support objective-c style naming of keys
                keyPart = [keyPart tspb_lowercaseFirstCharacter];
                value = [keyedObject valueForKey:keyPart];
                
            }
            
            // object has no defined value for keyPart
            if (!value) {
                break;
            }
            
            keyedObject = value;
        }
        
        // get string representation
        NSString *stringValue = nil;
        if (!value || [value isKindOfClass:[NSNull class]]) {
            
            stringValue = @"";
            
        } else if ([value isKindOfClass:[NSDecimalNumber class]]) {
            
            // use the valueFormat
            stringValue = [value description];
            
        } else if ([value isKindOfClass:[NSDate class]]) {
            
            NSDate *date = value;
            stringValue = [date tspb_dateStringWithFormat:valueFormat];
            
        } else {
            
            stringValue = [value description];
        }
        
        text = [text stringByReplacingOccurrencesOfString:match withString:stringValue];
    }
    
    return text;
    
}

- (NSString *)propertyKeyFromMatchString:(NSString *)match
{
    return [match substringWithRange:NSMakeRange(1, match.length - 2)]; // strip { and }
}

#pragma mark -
#pragma mark Attributed string support

- (NSMutableAttributedString *)attributedStringForElement:(NSXMLElement *)xe withObject:(id)object
{
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
    
    // determine if element has any non text children
    NSXMLNodeKind nodeKind = xe.kind;
    for (NSXMLNode *xn in xe.children) {
        nodeKind = xn.kind;
        if (nodeKind != NSXMLTextKind) {
            break;
        }
    }
    
    //
    // concatenate non text child items
    //
    if (nodeKind != NSXMLTextKind) {
        for (NSXMLNode *xnChild in xe.children) {
            NSAttributedString *elementString = nil;
            
            // Run
            if ([xnChild.name isEqualToString:@"Run"]) {
                
                elementString = [self attributedStringForElement:(id)xnChild withObject:object];
                
                // LineBreak
            } else if ([xnChild.name isEqualToString:@"LineBreak"]) {
                
                elementString = [[NSAttributedString alloc] initWithString:@"\n"];
                
            } else {
                
                TSLogWarn(@"Unexpected child element : %@", xnChild);
                
                elementString = [[NSAttributedString alloc] initWithString:[xnChild stringValue]];
            }
            
            if (elementString) {
                [resultString appendAttributedString:elementString];
            }
            
        }
        
        return resultString;
    }
    
    // contract
    NSAssert(object, @"object is nil");
    NSAssert(xe, @"element is nil");
    NSAssert([(NSXMLNode *)xe.children[0] kind] == NSXMLTextKind, @"expected kind == %li found %li", NSXMLTextKind, [(NSXMLNode *)xe.children[0] kind]);
    
    //
    // get the element string value and operate on that
    //
    NSString *text = [xe stringValue];
    if (!text || [text tspb_isEmpty]) {
        return resultString;
    }
    
    //
    // Replace {key} values in text string from object
    //
    text = [self replaceKeysInString:text fromObject:object];
    
    // ensure we are normalised
    text = [text tspb_normaliseLineEndings];
    
    // reject empty text
    if (!text || text.tspb_isEmpty) {
        return resultString;
    }

    // let the delegate validate the text
    if ([self.delegate respondsToSelector:@selector(validateStringForPageBuilder:string:)]) {
        if (![self.delegate validateStringForPageBuilder:self string:text]) {
            return resultString;
        }
    }
    
    //
    // apply the Y aggregators if defined
    //
    NSMutableArray *aggregatorStack = self.stacks[TSKeyYIncrement];
    if (aggregatorStack.count > 0) {
        
        TSPageDoubleAggregator *aggregator = [aggregatorStack tspb_stackPeek];
        double y = aggregator.base + aggregator.index * aggregator.multiplier;
        [xe tspb_addAttributeWithName:@"Y" doubleValue:y];
        
    } else {
        
        aggregatorStack = self.stacks[TSKeyYSpacing];
        if (aggregatorStack.count > 0) {
            TSPageSpacingAggregator *aggregator = [aggregatorStack tspb_stackPeek];
            double y = aggregator.base;
            [xe tspb_addAttributeWithName:@"Y" doubleValue:y];
        }
    }
    
    // push element attributes onto the stack
    NSArray *pushedAttributes = [self pushAttributesForElement:xe];
    
    // create attributed string based on the current styles on the stack
    resultString = [[NSMutableAttributedString alloc] initWithString:text attributes:self.currentStringAttributes];
    
    // pop the element attributes
    [self popAttributes:pushedAttributes];
    
    return resultString;
}

- (NSDictionary *)currentStringAttributes
{
    // build an attributes dictionary that reflects the current state of the stack
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:10];
    
    // set paragraph style
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];    // supplies sensible defaults
    
    // configure horizontal alignment
    NSInteger textAlignment = NSLayoutAttributeLeft;
    if ([self stackHasValueForName:TSKeyTextAlignment]) {
        textAlignment = [[self.stacks[TSKeyTextAlignment] tspb_stackPeek] integerValue];
    }
    switch (textAlignment) {
        case NSLayoutAttributeLeft:
        {
            paragraphStyle.alignment = NSLeftTextAlignment;
            break;
        }
            
        case NSLayoutAttributeCenterX:
        {
            paragraphStyle.alignment = NSCenterTextAlignment;
            break;
        }
            
        case NSLayoutAttributeRight:
        {
            paragraphStyle.alignment = NSRightTextAlignment;
            break;
        }
            
        default:
        {
            NSLog(@"Unexpected text alignment value : %li", textAlignment);
            return nil;
            break;
        }
    }
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    
    // font
    if ([self stackHasValueForName:TSKeyFontFamily]) {
        
        NSString *fontFamily = [self.stacks[TSKeyFontFamily] tspb_stackPeek];
        CGFloat fontSize = -1.0;
        if ([self stackHasValueForName:TSKeyFontSize]) {
            fontSize = [[self.stacks[TSKeyFontSize] tspb_stackPeek] doubleValue];
        }
        
        NSFontTraitMask fontTraitMask = 0;
        if ([self stackHasValueForName:TSKeyFontStyle]) {
            fontTraitMask |= [[self.stacks[TSKeyFontStyle] tspb_stackPeek] integerValue];
        }
        if ([self stackHasValueForName:TSKeyFontWeight]) {
            fontTraitMask |= [[self.stacks[TSKeyFontWeight] tspb_stackPeek] integerValue];
        }
        
        // a weight of 5 is considered normal. weight is ignored if bold trait is set.
        NSFont *font = [[NSFontManager sharedFontManager] fontWithFamily:fontFamily traits:fontTraitMask weight:5 size:fontSize];
        attributes[NSFontAttributeName] = font;
    }
    
    // colour
    if ([self stackHasValueForName:TSKeyForeground]) {
        
        NSColor *color = [self.stacks[TSKeyForeground] tspb_stackPeek];
        attributes[NSForegroundColorAttributeName] = color;
    }
    
    if (!attributes[NSForegroundColorAttributeName]) {
        attributes[NSForegroundColorAttributeName] = [NSColor blackColor];
    }
    
    return attributes;
}

#pragma mark -
#pragma mark Accessors

- (NSRegularExpression *)propertyRegex
{
    if (!_propertyRegex) {
        self.propertyRegex = [NSRegularExpression regularExpressionWithPattern:@"\\{[^\\}]+?\\}" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
    }
    
    return _propertyRegex;
}

- (void)setHighlightPageItemContainerRects:(BOOL)highlightPageItemContainerRects
{
    _highlightPageItemContainerRects = highlightPageItemContainerRects;
    
    for (TSPageItem *pageItem in self.pageItems) {
        pageItem.highlightContainerRect = highlightPageItemContainerRects;
    }
}

- (NSMutableDictionary *)constantElements
{
    if (!_constantElements) {
        _constantElements = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return _constantElements;
    
}
#pragma mark -
#pragma mark Attribute support

- (NSArray *)pushAttributesForElement:(NSXMLElement *)xe
{
    // push all the styles attributes defined for an element onto the stack
    NSArray *styleNames = [[self class] styleAttributeNames];
    NSMutableArray *pushedStyleNames = [NSMutableArray arrayWithCapacity:[styleNames count]];
    
    for (NSString *styleName in styleNames) {
        NSXMLNode *attribute = [xe attributeForName:styleName];
        if (attribute) {
            [pushedStyleNames tspb_push:styleName];
            [self pushMapKey:styleName value:[attribute stringValue]];
        }
    }
    
    return pushedStyleNames;
}

- (void)popAttributes:(NSArray *)styleNames
{
    // pop style names from the stack
    for (NSString *styleName in styleNames) {
        [self popMapKey:styleName];
    }
}

#pragma mark -
#pragma mark Stack support

- (BOOL)stackHasValueForName:(NSString *)name
{
    return [(NSArray *)self.stacks[name] count] > 0;
}


- (void)pushMapKey:(NSString *)key value:(NSString *)value
{
    if (!key || key.tspb_isEmpty || !value || value.tspb_isEmpty) {
        return;
    }
    
    // get the key identifier
    NSNumber *identifier = [[[self class] styleInfo] objectForKey:key];
    NSAssert(identifier, @"Missing identifier for key : %@", key);
    
    id item = nil;
    
    switch (identifier.integerValue) {
           
        case TSStyleFontSize:
        {
            // numeric item
            CGFloat fontSize = [[self numberFromString:value] doubleValue];

            fontSize *= self.fontSizeAttributeScale;
            
            item = @(fontSize);
            break;
        }

        case TSStyleRotation:
        case TSStyleLineHeight:
        {
            // numeric item
            item = [self numberFromString:value];
            break;
        }
            
        case TSStyleForeground:
        case TSStyleBorderBrush:
        case TSStyleBorderBackground:
        {
            if ([self.delegate respondsToSelector:@selector(colorForPageBuilder:key:string:)]) {
                item = [self.delegate colorForPageBuilder:self key:key string:value];
            } else {
                item = [NSColor tspb_colorFromHexRGB:value alpha:1.0];
            }
            
            break;
        }
            
        case TSStyleBorderThickness:
        case TSStyleTextPadding:
        {
            NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
            NSArray *components = nil;
            
            // format is a single digit representing l (left) or 4 separated digits representing l, t, r, b (left, top, right, bottom)
            if ([value rangeOfCharacterFromSet:separatorSet].location != NSNotFound) {
                components = [value componentsSeparatedByCharactersInSet:separatorSet];
                
                if (components.count != 4) {
                    NSLog(@"Invalid number of value comoponents (%li) for key : %@", components.count, key);
                    return;
                }
                
            } else {
                components = @[value, @"0", @"0", @"0"];
            }
            
            item = @{ @"left" : @([[self numberFromString:components[0]] doubleValue] * self.geometryAttributeScale),
                      @"top" : @([[self numberFromString:components[1]] doubleValue] * self.geometryAttributeScale),
                      @"right" : @([[self numberFromString:components[2]] doubleValue] * self.geometryAttributeScale),
                      @"bottom" : @([[self numberFromString:components[3]] doubleValue] * self.geometryAttributeScale),
                      };
            
            break;
        }
            
        case TSStyleTextVerticalAlignment:
        {
            NSTextAlignment alignment = NSLayoutAttributeTop;
            if ([value isEqualToString:@"Top"]) {
                
                alignment = NSLayoutAttributeTop;
                
            } else if ([value isEqualToString:@"Center"]) {
                
                alignment = NSLayoutAttributeCenterY;
                
            } else if ([value isEqualToString:@"Bottom"]) {
                
                alignment = NSLayoutAttributeBottom;
                
            } else {
                
                TSLogWarn(@"invalid key : %@ value : %@", key, value);
            }
            
            item = @(alignment);
            
            break;
        }
            
        case TSStyleTextAlignment:
        {
            NSTextAlignment alignment = NSLayoutAttributeLeft;
            if ([value isEqualToString:@"Left"]) {
                
                alignment = NSLayoutAttributeLeft;
                
            } else if ([value isEqualToString:@"Center"]) {
                
                alignment = NSLayoutAttributeCenterX;
                
            } else if ([value isEqualToString:@"Right"]) {
                
                alignment = NSLayoutAttributeRight;
                
            } else {
                
                TSLogWarn(@"invalid key : %@ value : %@", key, value);
            }
            
            item = @(alignment);
            
            break;
        }
            
        case TSStyleTextWrapping:
        {
            NSLog(@" push key : %@ implementation is pending", key);
            
            break;
        }
            
        case TSStyleFontFamily:
        {
            if ([self.delegate respondsToSelector:@selector(fontFamilyNameForPageBuilder:key:string:)]) {
                item = [self.delegate fontFamilyNameForPageBuilder:self key:key string:value];
            } else {
                item = value;
            }
            
            break;
        }
            
        case TSStyleFontStretch:
        {
            NSLog(@" push key : %@ implementation is pending", key);
            break;
        }
            
        case TSStyleFontStyle:
        {
            NSFontTraitMask fontTrait = 0;
            if ([value isEqualToString:@"Italic"]) {
                fontTrait = NSItalicFontMask;
            }
            
            item = @(fontTrait);
            break;
        }
            
        case TSStyleFontWeight:
        {
            NSFontTraitMask fontTrait = 0;
            if ([value isEqualToString:@"Bold"]) {
                fontTrait = NSBoldFontMask;
            }
            
            item = @(fontTrait);
            
            break;
        }
            
        default:
        {
            // contract
            NSAssert(NO, @"No mapping operation found for key : %@", key);
            break;
        }
    }
    
    // push item onto its key stack
    if (item) {
        NSMutableArray *stack = self.stacks[key];
        
        // contract
        NSAssert(stack, @"stack not found for key : %@", key);
        
        [stack tspb_push:item];
        
        TSLogVerbose(@"Did push key : %@ value : %@", key, item);
    }
}

- (id)popMapKey:(NSString *)key
{
    // contract
    NSAssert(key, @"Stack key is nil");
    
    NSMutableArray *stack = self.stacks[key];
    
    // contract
    NSAssert(stack, @"stack not found for key : %@", key);
    
    id result = [stack tspb_pop];
    
    TSLogVerbose(@"Did pop key : %@", key);
    
    return result;
}

- (NSRect)rectangleForElement:(NSXMLElement *)xe
{
    // XML map co-ordinate system origin is top left.
    // Note that we scale the geometry to points at this stage.
    // We could use a scaling transform to delay the conversion but it seems
    // more conveninet to work in the local PDF point scale.
    
    // vertical co-ordinate
    NSXMLNode *yAttr = [xe attributeForName:@"Y"];
    NSAssert(yAttr, @"Y Co-ordinate undefined");    // contract
    CGFloat y = [self numberFromString:yAttr.stringValue].floatValue * self.geometryAttributeScale;
    y += self.layoutOffset.y;
    
    // horizontal co-ordinate
    NSXMLNode *xAttr = [xe attributeForName:@"X"];
    NSAssert(xAttr, @"X Co-ordinate undefined");    // contract
    CGFloat x = [self numberFromString:xAttr.stringValue].floatValue * self.geometryAttributeScale;
    x += self.layoutOffset.x;
    
    //
    // optional geometry attributes
    //
    
    // width
    NSXMLNode *widthAttr = [xe attributeForName:@"Width"];
    CGFloat width = 0;
    if (widthAttr) {
        width = [self numberFromString:widthAttr.stringValue].floatValue * self.geometryAttributeScale;
    } else {
        width = self.mediaBoxRect.size.width - x;   // default to width of page
    }
    
    // height
    NSXMLNode *heightAttribute = [xe attributeForName:@"Height"];
    CGFloat height = 0;
    if (heightAttribute) {
        height = [self numberFromString:heightAttribute.stringValue].floatValue * self.geometryAttributeScale;
    }
    
    NSRect rect = NSMakeRect(x, y , width, height);
    
    return rect;
}

#pragma mark -
#pragma mark Page item support

- (TSPageTextItem *)addTextItem:(NSAttributedString *)text rect:(NSRect)rect
{
    TSPageTextItem *textItem = [TSPageTextItem itemWithAttributedString:text rect:rect];
    textItem.pageHeight = self.mediaBoxRect.size.height;

    [self addPageItem:textItem];

    return textItem;
}

- (TSPageImageItem *)addImageItem:(NSImage*)image rect:(NSRect)rect
{
    TSPageImageItem *imageItem = [TSPageImageItem itemWithImage:image rect:rect];

    [self addPageItem:imageItem];

    return imageItem;
}

- (void)addPageItem:(TSPageItem *)item
{
    // honour horizontal text alignment
    if ([self stackHasValueForName:TSKeyTextAlignment]) {
        item.horizontalAlignment = [[self.stacks[TSKeyTextAlignment] tspb_stackPeek] integerValue];
    }
    
    // honour vertical text alignment
    if ([self stackHasValueForName:TSKeyTextVerticalAlignment]) {
        item.verticalAlignment = [[self.stacks[TSKeyTextVerticalAlignment] tspb_stackPeek] integerValue];
    }
    
    // honour the background color
    if ([self stackHasValueForName:TSKeyBorderBackground]) {
        item.backgroundColor = [self.stacks[TSKeyBorderBackground] tspb_stackPeek];
    }
    
    item.highlightContainerRect = self.highlightPageItemContainerRects;
    
    // layout now in order to calculate item dimensions
    [item doLayout];
    
    [self.pageItems addObject:item];
}

#pragma mark -
#pragma mark Numeric support

- (NSNumber *)numberFromString:(NSString *)value
{
    NSNumber *number = [[[self class] decimalNumberFormatter] numberFromString:value];
    
    return number;
}

#pragma mark -
#pragma mark Drawing

- (void)drawPageItems
{
    [self loadGraphicsContext];

    // draw all map items
    for (TSPageItem *mapItem in self.pageItems) {
        [mapItem draw];
    }
    
    // highlight all container rects
    if (self.highlightPageItemContainerRects) {
        for (TSPageItem *mapItem in self.pageItems) {
            [mapItem drawContainerRect];
        }
    }

    [self unloadGraphicsContext];
}

- (void)loadGraphicsContext
{
    NSAssert(!self.gcIsLoaded, @"duplicate call to page graphics context loader");
    
    // life is much easier if we use a flipped co-ordinate system.
    // NSLayoutManager expects a flipped context.
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *flippedGC = [NSGraphicsContext graphicsContextWithGraphicsPort:[[NSGraphicsContext currentContext] graphicsPort]
                                                                              flipped:YES];
    [NSGraphicsContext setCurrentContext:flippedGC];
    
    // define the flip transform
    NSAffineTransform* xform = [NSAffineTransform transform];
    [xform translateXBy:0.0 yBy:self.mediaBoxRect.size.height];
    [xform scaleXBy:1.0 yBy:-1.0];
    [xform concat];

    self.gcIsLoaded = YES;
}

- (void)unloadGraphicsContext
{
    NSAssert(self.gcIsLoaded, @"trying to unload page graphics context when none loaded");

    [NSGraphicsContext restoreGraphicsState];
    
    self.gcIsLoaded = NO;
}

@end
