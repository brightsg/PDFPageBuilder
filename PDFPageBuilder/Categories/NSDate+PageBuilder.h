//
//  NSDate+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (PageBuilder)

- (NSString *)tspb_dateStringWithFormat:(NSString *)format;
@end
