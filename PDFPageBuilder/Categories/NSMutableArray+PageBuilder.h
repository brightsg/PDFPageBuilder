//
//  NSMutableArray+PageBuilder.h
//  BrightPay
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (PageBuilder)

// a stack is Last In First Out

/*!
 
 Pop item off top of stack and return item.
 
 */
- (id)tspb_pop;

/*!
 
 Push an item onto the top of the stack.
 
 */
- (void)tspb_push:(id)obj;


/*!
 
 Return the top item in the stack.
 
 */
- (id)tspb_stackPeek;

@end
