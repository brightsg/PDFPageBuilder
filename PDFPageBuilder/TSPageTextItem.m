//
//  TSPageTextItem.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 14/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPageTextItem.h"
#import "NSAttributedString+PageBuilder.h"

@interface TSPageTextItem ()

@property (strong,readwrite) NSString *text;
@property (strong,readwrite) NSDictionary *attributes;
@property (strong,readwrite) NSAttributedString *attributedString;
@property (assign,readwrite) NSRect usedTextRect;
@property (strong) NSTextStorage *textStorage;
@property (assign) NSPoint lineFragmentOrigin;
@property (assign) NSRange glyphRange;

@end

@implementation TSPageTextItem

#pragma mark -
#pragma mark Factory

+ (id)itemWithAttributedString:(NSAttributedString *)text rect:(NSRect)rect
{
    TSPageTextItem *textItem = [[self alloc] initWithAttributedString:text rect:rect];
    
    return textItem;
}

#pragma mark -
#pragma mark Defaults

+ (NSFont *)defaultFont
{
    static NSFont *font = nil;
    if (!font) {
        
        // default size system font
        font = [NSFont systemFontOfSize:0];
    }
    
    return font;
}


+ (NSParagraphStyle *)defaultParagraphStyleLeft
{
    NSMutableParagraphStyle *style = nil;
    
    if (!style) {
        style = [NSMutableParagraphStyle new];
        [style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        style.alignment = NSLeftTextAlignment;
    }
    
    return style;
}

+ (NSDictionary *)defaultAttributesLeft
{
    static NSDictionary *attributes;
    if (!attributes) {
        attributes = @{NSFontAttributeName : self.defaultFont,
                       NSParagraphStyleAttributeName : self.defaultParagraphStyleLeft
                       };
    }
    
    return attributes;
}
 
#pragma mark -
#pragma mark Lifecycle

- (id)initWithAttributedString:(NSAttributedString *)text rect:(NSRect)rect
{
    self = [super initWithRect:rect];
    if (self) {
        text = [text tspb_attributedStringByTrimming:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _attributedString = text;
        _glyphRange = NSMakeRange(0, 0);
    }
    
    return self;
}

#pragma mark -
#pragma mark Layout

- (void)doLayout
{
    // reset the glyph range
    self.glyphRange = NSMakeRange(0, 0);

    // some of the layout methods below raise if operating on a zero length string
    if (!self.attributedString || self.attributedString.length == 0) {
        return;
    }
    
    NSRect boundingRect = self.containerRect;
    
    // if no rect height defined then use default
    BOOL containerHasExplicitHeight = YES;
    if (boundingRect.size.height == 0) {
        boundingRect.size.height = self.pageHeight - self.containerRect.origin.y ;
        containerHasExplicitHeight = NO;
    }
    
    // allocate text container and layout manager
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:boundingRect.size];
    textContainer.lineFragmentPadding = 0;  // defaults to non zero
    
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    layoutManager.usesFontLeading = YES;
    
    // allocate text storage and assign layout manager
    self.textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedString];
    [self.textStorage addLayoutManager:layoutManager];
    
    // do glyph layout
    // NOTE: cannot quite get glyphRangeForBoundingRect configured correctly here
    //self.glyphRange = [layoutManager glyphRangeForBoundingRect:boundingRect inTextContainer:textContainer];
    self.glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    
    // get rect used for actual glyph layout
    self.usedTextRect = [layoutManager usedRectForTextContainer:textContainer];
    
    // if container has no explicit height then default to use text height
    if (!containerHasExplicitHeight) {
        boundingRect.size.height = self.usedTextRect.size.height;
    }
    
    // calculate the vertical alignment
    switch (self.verticalAlignment) {
        case NSLayoutAttributeTop:
        {
            boundingRect.origin.y += 0;
            break;
        }
            
        case NSLayoutAttributeCenterY:
        {
            boundingRect.origin.y += (boundingRect.size.height - self.usedTextRect.size.height)/2;
            break;
        }
            
        case NSLayoutAttributeBottom:
        {
            boundingRect.origin.y += boundingRect.size.height - self.usedTextRect.size.height;
            break;
        }
            
        default:
        {
            NSLog(@"Unexpected text vertical alignment value : %li", self.verticalAlignment);
            break;
        }
    }
    
    self.lineFragmentOrigin = boundingRect.origin;
}

#pragma mark -
#pragma mark drawing

- (void)drawContent
{
    // draw those glyphs
    if (self.glyphRange.length == 0) {
        return;
    }
    
    NSLayoutManager *layoutManager = self.textStorage.layoutManagers[0];
    [layoutManager drawBackgroundForGlyphRange:self.glyphRange atPoint:self.lineFragmentOrigin];
    [layoutManager drawGlyphsForGlyphRange:self.glyphRange atPoint:self.lineFragmentOrigin];

}

@end
