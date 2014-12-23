//
//  NSString+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PageBuilder)

- (NSString *)tspb_normaliseLineEndings;

- (BOOL)tspb_isEmpty;

- (NSString *)tspb_lowercaseFirstCharacter;
@end
