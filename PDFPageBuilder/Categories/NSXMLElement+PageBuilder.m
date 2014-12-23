//
//  NSXMLElement+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSXMLElement+PageBuilder.h"

@implementation NSXMLElement (PageBuilder)

- (NSString *)tspb_innerXMLString
{
    NSMutableString *xmlString = [[NSMutableString alloc] init];
    for (NSXMLNode *item in self.children) {
        
        NSString *xml = [item XMLString];
        if (xml) {
            [xmlString appendString:xml];
        }
    }
    
    return xmlString;
}

- (BOOL)tspb_removeChild:(NSXMLNode *)childNode
{
    NSUInteger idx = [self.children indexOfObject:childNode];
    
    BOOL result = NO;
    
    if (idx != NSNotFound) {
        [self removeChildAtIndex:idx];
        result = YES;
    }
    
    return result;
}

- (double)tspb_attributeDoubleValueForName:(NSString *)name
{
    return [[self tspb_attributeStringValueForName:name] doubleValue];
}

- (NSInteger)tspb_attributeIntegerValueForName:(NSString *)name
{
    return [[self tspb_attributeStringValueForName:name] integerValue];
}

- (NSString *)tspb_attributeStringValueForName:(NSString *)name
{
    return [[self attributeForName:name] stringValue];
}

- (void)tspb_addAttributeWithName:(NSString *)name doubleValue:(double)doubleValue
{
    [self tspb_addAttributeWithName:name numberValue:[NSNumber numberWithDouble:doubleValue]];
}

- (void)tspb_addAttributeWithName:(NSString *)name integerValue:(NSInteger)integerValue
{
    [self tspb_addAttributeWithName:name numberValue:[NSNumber numberWithInteger:integerValue]];
}

- (void)tspb_addAttributeWithName:(NSString *)name stringValue:(NSString *)string
{
    [self addAttribute:[NSXMLNode attributeWithName:name stringValue:string]];
}

- (void)tspb_addAttributeWithName:(NSString *)name numberValue:(NSNumber *)number
{
    [self tspb_addAttributeWithName:name stringValue:[number stringValue]];
}

@end
