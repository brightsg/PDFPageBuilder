//
//  TSPageTextItem.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 14/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPageItem.h"

@interface TSPageTextItem : TSPageItem

/*!
 
 The items text content.
 
 */
@property (strong,readonly) NSAttributedString *attributedString;

/*!
 
 The rect with the content rect used to layout the actual text. All values are in points.
 
 */
@property (assign,readonly) NSRect usedTextRect;

/*!
 
 Factory constructor.
 
 */
+ (instancetype)itemWithAttributedString:(NSAttributedString *)text rect:(NSRect)rect;

/*!

 Initialise with text and content rect. This is the designated initialiser.

 */
- (id)initWithAttributedString:(NSAttributedString *)text rect:(NSRect)rect;

/*!
 
 The height of the page in points. Used to provide a default height for items
 that have no explicit height.
 
 */
@property (assign) CGFloat pageHeight;
@end
