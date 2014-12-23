//
//  TSPDFDocument.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 12/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "TSPDFDocument.h"
#import "TSPDFPage.h"

@implementation TSPDFDocument

#pragma mark -
#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self) {
        [self setupInstance];
    }
    
    return self;
}


- (id)initWithData:(NSData *)data
{
    self = [super initWithData:data];
    if (self) {
        [self setupInstance];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupInstance];
    }
    
    return self;
}

- (void)setupInstance
{
    // allow override ?
}

#pragma mark -
#pragma mark Page handling

- (Class)pageClass
{
    return [TSPDFPage class];
}

- (void)insertNewPageAtIndex:(NSInteger)idx pageSize:(TSPageSize)pageSize
{
    // get page size in MM
    NSSize size = NSMakeSize(-1, -1);
    switch (pageSize) {
        case TSPageSizeA4:
        {
            size = NSMakeSize(210, 297);
            break;
        }
            
        case TSPageSizeA5:
        {
            size = NSMakeSize(148, 210);
            break;
        }
            
        default:
        {
            NSAssert(NO, @"Invalid paper size");
        }
    }
    
    // create page
    TSPDFPage *pdfPage = [TSPDFPage new];
    pdfPage.delegate = self.delegate;
    
    // set media bounds to define page size
    [pdfPage setMediaBoundsInMapUnits:size];
    
    // insert page into document
    [self insertPage:pdfPage atIndex:idx];
}

#pragma mark -
#pragma mark Data mapping

- (void)layoutPageItemsForObject:(id)object withMapURL:(NSURL *)url pageIndex:(NSUInteger)pageIndex
{    
    // get the required page
    TSPDFPage *pdfPage = (TSPDFPage *)[self pageAtIndex:pageIndex];
    pdfPage.delegate = self.delegate;
    
    // inform the delegate
    if ([self.delegate respondsToSelector:@selector(pdfDocument:willLayoutPage:)]) {
        [self.delegate pdfDocument:self willLayoutPage:pdfPage];
    }
    
    // map object properties to this page using the given map URL
    [pdfPage layoutPageItemsForObject:object withMapURL:url];
}

@end
