//
//  TSMapItem.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 14/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSRect TSRectToNearestMM(NSRect rect);

@interface TSPageItem : NSObject

/*!
 
 Item needs layout. When true -doLayout will be called prior to drawing.
 
 */
@property (assign) BOOL needsLayout;

/*!
 
 Highlight the containerRect.
 
 */
@property (assign) BOOL highlightContainerRect;

/*!
 
 Item container rectangle. All values are in points.
 
 */
@property (assign) NSRect containerRect;

/*!
 
 Horizontal alignment.
 
 */
@property (assign,nonatomic) NSLayoutAttribute horizontalAlignment;

/*!
 
 Vertical alignment.
 
 */
@property (assign,nonatomic) NSLayoutAttribute verticalAlignment;

/*!
 
 Background color.
 
 */
@property (strong,nonatomic) NSColor *backgroundColor;

/*!
 
 Designated initialiser.
 
 */
- (id)initWithRect:(NSRect)rect;

/*!
 
 Draw the item.
 
 This method calls the following receivder methods in order:
 doLayout (if needed), drawBackground, drawContent, drawBorder.
 
 */
- (void)draw;

/*!
 
 Draw the item background
 
 */
- (void)drawBackground;

/*!

 Draw the item interior content. Subclasses must override this method.

*/
- (void)drawContent;

/*!
 
 Draw the item border.
 
 */
- (void)drawBorder;

/*!
 
 Draw the container rect. This method is useful for debugging layout issues.
 
 */
- (void)drawContainerRect;

/*!
 
 Layout the item.
 
 */
- (void)doLayout;

@end
