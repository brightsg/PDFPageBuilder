//
//  TSPDFPage.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 12/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "TSPageBuilder.h"

@class TSPDFPage;

@protocol TSPDFPageDelegate <NSObject>

@optional
- (void)pageBuilderLoadedForPDFPage:(TSPDFPage *)page;
@end

@interface TSPDFPage : PDFPage

/*!
 
 The page builder.
 
 */
@property (strong,nonatomic,readonly) TSPageBuilder *pageBuilder;

/*!
 
 The page delegate.
 
 */
@property (weak,nonatomic) id <TSPDFPageDelegate, TSPageBuilderDelegate> delegate;

/*!
 
 Layout the given object using xml loaded from the map url.
 
 */
- (void)layoutPageItemsForObject:(id)object withMapURL:(NSURL *)url;

/*!
 
 Load the map URL but do no layout.
 Useful for loading constant elements prior to layout.
 
 */
- (void)loadMapURL:(NSURL *)url;

/*!
 
 Set the page media bounds in the units used by the map.
 
 */
- (void)setMediaBoundsInMapUnits:(NSSize)size;

/*!
 
 Height of the page media box;
 
 */
- (CGFloat)height;

/*!
 
 Width of the page media box;
 
 */
- (CGFloat)width;

@end
