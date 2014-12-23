//
//  NSRegularExpression+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSRegularExpression+PageBuilder.h"

@implementation NSRegularExpression (PageBuilder)

- (BOOL)tspb_isMatch:(NSString*)matchee
{
    return [self numberOfMatchesInString:matchee options:0 range:NSMakeRange(0, matchee.length)] > 0;
}

- (NSString *)tspb_firstMatch:(NSString*)str
{
    NSTextCheckingResult* match = [self firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
    
    if (!match) return nil;
    
    return [str substringWithRange:match.range];
}
@end
