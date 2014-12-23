//
//  NSXMLElement+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSXMLElement (PageBuilder)
- (NSString *)tspb_innerXMLString;
- (BOOL)tspb_removeChild:(NSXMLNode *)childNode;

- (double)tspb_attributeDoubleValueForName:(NSString *)name;
- (NSInteger)tspb_attributeIntegerValueForName:(NSString *)name;
- (NSString *)tspb_attributeStringValueForName:(NSString *)name;
- (void)tspb_addAttributeWithName:(NSString *)name doubleValue:(double)doubleValue;
- (void)tspb_addAttributeWithName:(NSString *)name integerValue:(NSInteger)integerValue;
- (void)tspb_addAttributeWithName:(NSString *)name stringValue:(NSString *)string;
- (void)tspb_addAttributeWithName:(NSString *)name numberValue:(NSNumber *)number;
@end
