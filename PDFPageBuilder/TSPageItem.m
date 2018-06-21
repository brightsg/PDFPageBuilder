//
//  TSMapItem.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 14/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPageItem.h"

@implementation TSPageItem

#pragma mark -
#pragma mark Setup

- (id)initWithRect:(NSRect)rect
{
    self = [super init];
    if (self) {
        _containerRect = rect;
        _horizontalAlignment = NSLayoutAttributeCenterX;
        _verticalAlignment = NSLayoutAttributeTop;
        _backgroundColor = nil;
        _needsLayout = YES;
        _highlightContainerRect = NO;
    }
    
    return self;
}

#pragma mark -
#pragma mark Drawing

- (void)draw
{
    // do layout if requred
    if (self.needsLayout) {
        [self doLayout];
    }

    [self drawBackground];
    [self drawContent];
    [self drawBorder];
}

- (void)drawBackground
{
    // fill the container rect
    if (self.backgroundColor) {
        [self.backgroundColor set];
        NSRectFill(self.containerRect);
    }
}

- (void)drawContent
{
    // subclasses must override
    NSAssert(NO, @"Subclass must override this method");
}

- (void)drawBorder
{
    // TODO: draw item border
}

- (void)drawContainerRect
{
    // highlight container rect
    if (self.highlightContainerRect) {
        
        NSRect rect = self.containerRect;
        
        // if height not explicitly set then draw top line
        if (self.containerRect.size.height < 1) {
            rect.size.height = 1;
        }
        
        [[NSColor redColor] set];
        NSFrameRect(rect);
    }

}

#pragma mark -
#pragma mark Layout

- (void)doLayout
{
    // subclass override must call this
    self.needsLayout = NO;
}

#pragma mark -
#pragma mark Accessors

- (void)setHorizontalAlignment:(NSLayoutAttribute)horizontalAlignment
{
    _horizontalAlignment = horizontalAlignment;
    self.needsLayout = YES;
}

- (void)setVerticalAlignment:(NSLayoutAttribute)verticalAlignment
{
    _verticalAlignment = verticalAlignment;
    self.needsLayout = YES;
}

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    self.needsLayout = YES;
}

@end
