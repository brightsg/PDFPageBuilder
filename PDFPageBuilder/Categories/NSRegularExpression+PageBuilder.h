//
//  NSRegularExpression+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRegularExpression (PageBuilder)

- (BOOL)tspb_isMatch:(NSString*)matchee;
- (NSString *)tspb_firstMatch:(NSString*)str;
@end
