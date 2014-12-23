//
//  TSPageImageItem.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 16/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPageImageItem.h"

@interface TSPageImageItem()
@property (assign) NSRect drawRect;
@property (assign) NSRect imageRect;
@end

@implementation TSPageImageItem

#pragma mark -
#pragma mark Factory

+ (instancetype)itemWithImage:(NSImage *)image rect:(NSRect)rect
{
    TSPageImageItem *imageItem = [[self alloc] initWithImage:image rect:rect];
    return imageItem;
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithImage:(NSImage *)image rect:(NSRect)rect
{
    self = [super initWithRect:rect];
    if (self) {
        _image = image;
        
        _image.flipped = YES;
    }
    
    return self;
}

#pragma mark -
#pragma mark drawing

- (void)drawContent
{
    // draw the image in the rect
    [self.image drawInRect:self.drawRect fromRect:self.imageRect operation:NSCompositeSourceOver fraction:1.0];
}

#pragma mark -
#pragma mark Layout

- (void)doLayout
{
    // image rect
    NSSize imagesize = self.image.size;
    NSRect imageRect = NSMakeRect(0, 0, imagesize.width, imagesize.height);
    CGFloat imageAspectRation = imagesize.width / imagesize.height;
    
    // draw rect
    NSRect drawRect = self.containerRect;
    CGFloat drawAspectRation = self.containerRect.size.width / self.containerRect.size.height;
    
    // maintain the image aspect ration within the available draw rect
    if (imageAspectRation < drawAspectRation) {
        drawRect.size.width = self.containerRect.size.height * imageAspectRation;
    } else {
        drawRect.size.height = self.containerRect.size.width / imageAspectRation;
    }
    
    // honour the horizontal alignment
    switch (self.horizontalAlignment) {
        case NSLayoutAttributeLeft:
        {
            drawRect.origin.x += 0;
            break;
        }
            
        case NSLayoutAttributeCenterX:
        {
            drawRect.origin.x += (self.containerRect.size.width - drawRect.size.width)/2;
            break;
        }
            
        case NSLayoutAttributeRight:
        {
            drawRect.origin.x += (self.containerRect.size.width - drawRect.size.width);
            break;
        }
            
        default:
        {
            NSLog(@"Unexpected horizontal alignment value : %li", self.horizontalAlignment);
            break;
        }
    }
    
    // honour the vertical alignment
    switch (self.verticalAlignment) {
        case NSLayoutAttributeTop:
        {
            drawRect.origin.y += 0;
            break;
        }
            
        case NSLayoutAttributeCenterY:
        {
            drawRect.origin.y += (self.containerRect.size.height - drawRect.size.height)/2;
            break;
        }
            
        case NSLayoutAttributeBottom:
        {
            drawRect.origin.y += self.containerRect.size.height - drawRect.size.height;
            break;
        }
            
        default:
        {
            NSLog(@"Unexpected vertical alignment value : %li", self.verticalAlignment);
            break;
        }
    }

    self.drawRect = drawRect;
    self.imageRect = imageRect;
}

@end
