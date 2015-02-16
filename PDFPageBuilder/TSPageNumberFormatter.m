//
//  TSPageNumberFormatter.m
//  PDFPageBuilder
//
//  Created by Jonathan Mitchell on 16/02/2015.
//  Copyright (c) 2015 Thesaurus Software. All rights reserved.
//

#import "TSPageNumberFormatter.h"

@implementation TSPageNumberFormatter

#pragma mark -
#pragma mark Lifecycle

- (id)initWithWPFStyleFormatString:(NSString *)wpfStyleFormatter
{
    self = [super init];
 
    // see https://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
    NSString *formatSpecifier = [[wpfStyleFormatter substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSInteger precisionSpecifier = 0;
    if (wpfStyleFormatter.length > 1) {
        precisionSpecifier = [[wpfStyleFormatter substringWithRange:NSMakeRange(1, wpfStyleFormatter.length - 1)] integerValue];
    }
    
    // numeric
    if ([formatSpecifier isEqualToString:@"N"] || [formatSpecifier isEqualToString:@"F"]) {

        self.numberStyle = NSNumberFormatterDecimalStyle;
        [self setHasThousandSeparators:YES];

        // scientific
    } else if ([formatSpecifier isEqualToString:@"E"]) {
        
        self.numberStyle = kCFNumberFormatterScientificStyle;

        // percent
    } else if ([formatSpecifier isEqualToString:@"P"]) {
        
        self.numberStyle = kCFNumberFormatterPercentStyle;

        // currency
    } else if ([formatSpecifier isEqualToString:@"C"]) {
        
        self.numberStyle = NSNumberFormatterCurrencyStyle;
        [self setHasThousandSeparators:YES];
        
    } else {
        
        // other document WPF format specifiers can be implemented as required
        self.numberStyle = NSNumberFormatterNoStyle;
    }

    [self setMaximumFractionDigits:precisionSpecifier];
    [self setMinimumFractionDigits:precisionSpecifier];

    return self;
}

@end
