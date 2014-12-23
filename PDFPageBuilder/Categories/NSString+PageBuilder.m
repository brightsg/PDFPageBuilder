//
//  NSString+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSString+PageBuilder.h"

@implementation NSString (PageBuilder)

- (NSString *)tspb_normaliseLineEndings
{
    return [self stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
}

- (BOOL)tspb_isEmpty
{
    return ([[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0);
}

- (NSString *)tspb_lowercaseFirstCharacter
{
    NSString *firstChar = [[self substringToIndex:1] lowercaseString];
    return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstChar];
}
@end
