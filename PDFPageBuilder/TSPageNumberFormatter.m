//
//  TSPageNumberFormatter.m
//  PDFPageBuilder
//
//  Created by Jonathan Mitchell on 16/02/2015.
//  Copyright (c) 2015 Thesaurus Software. All rights reserved.
//

#import "TSPageNumberFormatter.h"

@interface TSPageNumberFormatter()

// blocks
@property (copy) NSString * (^fixupString)(NSString *value);

@end

@implementation TSPageNumberFormatter

#pragma mark -
#pragma mark Lifecycle

- (id)initWithWPFStyleFormatString:(NSString *)wpfStyleFormatter
{
    self = [super init];
 
    NSArray *standardFormatSpecifiers = @[@"C", // currency
                                          @"D", // decimal
                                          @"E", // exponential
                                          @"F", // fixed point
                                          @"G", // General
                                          @"N", // Numeric
                                          @"P", // Percent
                                          @"R", // Round trip
                                          @"X"]; // hex
    
    // see https://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
    NSString *formatSpecifier = [[wpfStyleFormatter substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    
    if ([standardFormatSpecifiers containsObject:formatSpecifier]) {
        
        // get the precision precision
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
    }
    else {
        
        // the presumption here is that we have a custom numeric .NET style format string.
        // https://msdn.microsoft.com/en-us/library/0c899ak8(v=vs.110).aspx
        //
        // Note that .NET supports formats such as :
        // #,#0 . 00
        //
        // points to note are :
        //
        // 1.The NumberGroupSeparator and NumberGroupSizes properties of the current NumberFormatInfo object determine the character used
        // as the number group separator and the size of each number group. For example, if the string "#,#" and the invariant culture
        // are used to format the number 1000, the output is "1,000".
        //
        // 2. The .NET format engine can live with spaces around the decimal point specifier. The Unicode Technical Standard #35 used by
        // Cocoa cannot.
        
        // address point 1
        NSString *format = [wpfStyleFormatter stringByReplacingOccurrencesOfString:@",#0" withString:@",##0"];
        
        // address point 2.
        // we note that this could be a lot smarter in terms of searching for whitespace before and after the decimal point to account
        // for cases where the amount of whitespace varies.
        
        NSString *shortDecmialPoint = @".";
        NSString *wideDecmialPoint = @" . ";
        if ([format rangeOfString:wideDecmialPoint].location != NSNotFound) {
            format = [format stringByReplacingOccurrencesOfString:wideDecmialPoint withString:shortDecmialPoint];
            
            // the fix up block will reverse the wide to short decimal point transformation
            self.fixupString = ^NSString *(NSString * value) {
                return [value stringByReplacingOccurrencesOfString:shortDecmialPoint withString:wideDecmialPoint];
            };
        }

        self.format = format;
    }
    
    return self;
}

#pragma mark -
#pragma mark STring representation

- (NSString *)stringFromNumber:(NSNumber *)number
{
    NSString *result = [super stringFromNumber:number];
    if (self.fixupString) {
        result = self.fixupString(result);
    }
    
    return result;
}
@end
