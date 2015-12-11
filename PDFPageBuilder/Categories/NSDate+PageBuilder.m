//
//  NSDate+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSDate+PageBuilder.h"
#import "TSPageBuilder.h"

@implementation NSDate (PageBuilder)

// date format patterns
// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
- (NSString *)tspb_dateStringWithFormat:(NSString *)format
{
    NSDateFormatter *dateFormatter = [TSPageBuilder dateFormatter];
    [dateFormatter setDateFormat:format];
    NSString *dateString = [dateFormatter stringFromDate:self];
    
    return dateString;
}

@end
