//
//  NSAttributedString+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 22/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (PageBuilder)

- (NSAttributedString *)tspb_attributedStringByTrimming:(NSCharacterSet *)set;

@end
