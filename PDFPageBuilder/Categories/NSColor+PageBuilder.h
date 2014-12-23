//
//  NSColor+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (PageBuilder)

+ (NSColor *)tspb_colorFromHexRGB:(NSString *)inColorString alpha:(CGFloat)alpha;

@end
