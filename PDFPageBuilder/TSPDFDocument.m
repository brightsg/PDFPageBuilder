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
    
    _defaultPageSize = TSPageSizeA4;
}

#pragma mark -
#pragma mark Page handling

- (Class)pageClass
{
    // note the existence in the header file of delegate method - (Class) classForPage;
    return [TSPDFPage class];
}

- (TSPDFPage *)insertNewPageAtIndex:(NSInteger)idx
{
    return [self insertNewPageAtIndex:idx pageSize:self.defaultPageSize];
}

- (TSPDFPage *)insertNewPageAtIndex:(NSInteger)idx pageSize:(TSPageSize)pageSize
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
    
    return pdfPage;
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

#pragma mark -
#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings
{

    // get a copy of the default NSPrintInfo object
    NSDictionary* defaultValues = [[NSPrintInfo sharedPrintInfo] dictionary];
    NSMutableDictionary* printInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:defaultValues];
    
    NSPrintInfo* printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDictionary];
    
    // apply default overrides
    printInfo.topMargin = 0;
    printInfo.rightMargin = 0;
    printInfo.bottomMargin = 0;
    printInfo.leftMargin = 0;
    printInfo.verticallyCentered = NO;
    printInfo.horizontallyCentered = NO;

    // add custom settings - adding to the dict change sthe receiver's properties
    [[printInfo dictionary] addEntriesFromDictionary:printSettings];
    
    // set orientation
    if ([self pageCount]) {
        PDFPage *page = [self pageAtIndex:0];
        NSSize pageSize = [page boundsForBox:kPDFDisplayBoxMediaBox].size;
        BOOL isLandscape = [page rotation] % 180 == 90 ? pageSize.height > pageSize.width : pageSize.width > pageSize.height;
        [printInfo setOrientation:isLandscape ? NSPaperOrientationLandscape : NSPaperOrientationPortrait];
    }
    
    
    // get the print operation
    // this is not mentioned in the docs but is in the header, along with a few other functions
    NSPrintOperation *printOperation = [self printOperationForPrintInfo:printInfo scalingMode:kPDFPrintPageScaleNone autoRotate:NO];
    
    if (printOperation) {
        [printOperation setShowsPrintPanel:YES];
        [printOperation setShowsProgressPanel:YES];
        printOperation.canSpawnSeparateThread = YES;
        
        // configure the operation print panel
        NSPrintPanel *printPanel = [printOperation printPanel];
        [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
    }
    
    return printOperation;
}

@end
