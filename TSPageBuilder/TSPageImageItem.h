//
//  TSPageImageItem.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 16/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPageItem.h"

@interface TSPageImageItem : TSPageItem

/*!
 
 Factory constructor.
 
 */
+ (instancetype)itemWithImage:(NSImage *)image rect:(NSRect)rect;

/*!
 
 Initialise with image and content rect. This is the designated initialiser.
 
 */
- (id)initWithImage:(NSImage *)image rect:(NSRect)rect;

/*!
 
 The items image content.
 
 */
@property (strong) NSImage *image;

@end
