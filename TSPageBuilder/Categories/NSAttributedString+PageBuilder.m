//
//  NSAttributedString+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 22/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSAttributedString+PageBuilder.h"

@implementation NSAttributedString (PageBuilder)

- (NSAttributedString *)tspb_attributedStringByTrimming:(NSCharacterSet *)set
{
    NSCharacterSet *invertedSet = set.invertedSet;
    NSString *string = self.string;
    unsigned int loc, len;
    
    NSRange range = [string rangeOfCharacterFromSet:invertedSet];
    loc = (range.length > 0) ? (int)range.location : 0;
    
    range = [string rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];
    len = (range.length > 0) ? (int)NSMaxRange(range) - loc : (int)string.length - loc;
    
    return [self attributedSubstringFromRange:NSMakeRange(loc, len)];
}

@end
