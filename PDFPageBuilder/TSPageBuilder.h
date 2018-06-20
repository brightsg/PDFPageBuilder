//
//  TSPageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 12/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSPageTextItem.h"
#import "TSPageImageItem.h"

#define TSPB_SCALE_MM_TO_PTS (72/25.4)

// map keys
extern NSString *TSKeyYIncrement;
extern NSString *TSKeyYSpacing;
extern NSString *TSKeyRotation;
extern NSString *TSKeyBorderBrush;
extern NSString *TSKeyBorderThickness;
extern NSString *TSKeyBorderBackground;
extern NSString *TSSKeyTextPadding;
extern NSString *TSKeyTextAlignment;
extern NSString *TSKeyTextVerticalAlignment;
extern NSString *TSKeyTextWrapping;
extern NSString *TSKeyFontFamily;
extern NSString *TSKeyFontSize;
extern NSString *TSKeyFontStretch;
extern NSString *TSKeyFontStyle;
extern NSString *TSKeyFontWeight;
extern NSString *TSKeyLineHeight;
extern NSString *TSKeyForeground;
extern NSString *TSKeyProperty;

@class TSPageBuilder;

@protocol TSPageBuilderDelegate <NSObject>

@optional
/*!
 
 Image data for pagebuilder object.
 
 */
- (NSData *)imageDataForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key object:(id)object;

/*!
 
 Color for pagebuilder object.
 
 */
- (NSColor *)colorForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key string:(NSString *)string;

/*!
 
 Font family name for pagebuilder object.
 
 */
- (NSString *)fontFamilyNameForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key string:(NSString *)string;

/*!
 
 Validate string for pagebuilder object.
 
 */
- (BOOL)validateStringForPageBuilder:(TSPageBuilder *)pageBuilder string:(NSString *)string;

@end

@interface TSPageBuilder : NSObject

/*!
 
 Delegate.
 
 */
@property (weak) id <TSPageBuilderDelegate> delegate;

/*!
 
 Rectangle within which all page content will be rendered.
 
 */
@property (assign) NSRect mediaBoxRect;

/*!
 
 Scale factor to be applied to all geometry attributes.
 The default geometry is in millimetres but clients can modify if want to say specify geometry in points.
 
 */
@property (assign) CGFloat geometryAttributeScale;

/*!
 
 Scale factor to be applied to all font size attributes.
 The default font size is in millimetres but clients can modify if want to say specify fontsize in points.
 
 */
@property (assign) CGFloat fontSizeAttributeScale;


/**
 
 Scale factor to be applied to Text.YIncrement attribute
 
 */
@property (assign) CGFloat textYIncrementAttributeScale;

/**
 
 Scale factor to be applied to Text.YSpacing attribute
 
 */
@property (assign) CGFloat textYSpacingAttributeScale;

/*!
 
 Highlight page item containers. This is useful for resolving layout issues.
 
 */
@property (assign,nonatomic) BOOL highlightPageItemContainerRects;


/*!
 
 A dictionary of constant element names and values.
 
 */
@property (strong,readonly) NSDictionary *constantElementDictionary;

/*!
 
 Offset to be used during calls to layout methods.
 
 */
@property (assign) NSPoint layoutOffset;

/*!
 
 Add a layout given elements and object.
 This method may be called multiple times to layout various objects on the same page.
 Use -layoutOffset to offset a given layout as required.
 
 */
- (NSArray *)addLayoutForElement:(NSXMLElement *)xeRoot withObject:(id)object;

/*
 
 Loads the the given element.
 Useful for loading constant element values prior to doing layout.
 
 */
- (NSArray *)loadElement:(NSXMLElement *)xeRoot;

/*!
 
 Draw the page items
 
 */
- (void)drawPageItemsToContext:(CGContextRef)context;

/*!
 
 Push a value onto the stack identified by the map key.
 This may be called by the client to manually update the stack for a given key.
 
 */
- (void)pushMapKey:(NSString *)key value:(NSString *)value;

/*!
 
 Pop the topmost value from the stack identified by the key.
 
 */
- (id)popMapKey:(NSString *)key;

/*!
 
 Add a text item at the given rect to the list of laid out page items. The rect values are in points.
 
 */
- (TSPageTextItem *)addTextItem:(NSAttributedString *)text rect:(NSRect)rect;

/*!
 
 Add an image item at the given rect to the list of laid out page items. The rect values are in points.
 
 */
- (TSPageImageItem *)addImageItem:(NSImage*)image rect:(NSRect)rect;

/*!
 
 Dictionary of objects used to render elements.
 Keys are element names.
 
 */
@property (strong,readonly) NSMutableDictionary *elementRenderDictionary;

/*!
 
 Decimal number formatter getter.
 
 */
+ (NSNumberFormatter *)decimalNumberFormatter;

/*!
 
 Decimal number formatter setter.
 
 */
+ (void)setDecimalNumberFormatter:(NSNumberFormatter *)formatter;

/*!
 
 Date formatter getter.
 
 */
+ (NSDateFormatter *)dateFormatter;

/*!
 
 Date formatter setter.
 
 */
+ (void)setDateFormatter:(NSDateFormatter *)formatter;

@end
