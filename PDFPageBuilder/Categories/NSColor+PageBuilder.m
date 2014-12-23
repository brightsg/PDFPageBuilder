//
//  NSColor+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSColor+PageBuilder.h"

@implementation NSColor (PageBuilder)

/*
 NSColor: Instantiate from Web-like Hex RRGGBB string
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */

+ (NSColor *)tspb_colorFromHexRGB:(NSString *)inColorString alpha:(CGFloat)alpha
{
    NSColor *result = nil;
    unsigned int colorCode = 0;
    
    if (nil != inColorString)
    {
        NSScanner *scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode];	// ignore error
    }
    CGFloat red = ((colorCode>>16)&0xFF)/255.0;
    CGFloat green = ((colorCode>>8)&0xFF)/255.0;
    CGFloat blue = ((colorCode>>0)&0xFF)/255.0;
    result = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0];
    return [result colorWithAlphaComponent:alpha];
}

@end
