//
//  TSPageNumberFormatter.h
//  PDFPageBuilder
//
//  Created by Jonathan Mitchell on 16/02/2015.
//  Copyright (c) 2015 Thesaurus Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPageNumberFormatter : NSNumberFormatter

/*!
 
 Initialise with WPF style formatter as per https://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
 
 */
- (id)initWithWPFStyleFormatString:(NSString *)wpfStyleFormatter;

@end
