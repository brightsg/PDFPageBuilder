//
//  NSMutableArray+PageBuilder.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "NSMutableArray+PageBuilder.h"

@implementation NSMutableArray (PageBuilder)


- (id)tspb_pop
{
    // nil if [self count] == 0
    id lastObject = [self lastObject];
    if (lastObject) {
        [self removeLastObject];
    }
    return lastObject;
}

- (void)tspb_push:(id)obj
{
    [self addObject: obj];
}

- (id)tspb_stackPeek
{
    return [self lastObject];
}

@end
