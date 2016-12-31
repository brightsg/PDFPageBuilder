//
//  TSPDFPage.m
//  BrightPay
//
//  Created by Jonathan Mitchell on 12/02/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

// BPWIN source: FixedDocumentBuilder.cs

#import "TSPDFPage.h"
#import "TSPageItem.h"

@interface PDFPage()

// undocumented method - ARC requires selectors to be defined.
- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context;
@end

@interface TSPDFPage()

// collections
@property (strong,nonatomic) NSArray *pageItems;

// objects
@property (strong,readwrite,nonatomic) TSPageBuilder *pageBuilder;

// primitives
@property (assign) BOOL didDrawPageItems;

@end

@implementation TSPDFPage

#pragma mark -
#pragma mark Lifecycle

/* 
 
 Lifecycle Note:
 
 Curiously there does not seem to be a reliable designated initialser available.
 
 There is the undocumented - (id)initWithPageRef:(CGPDFPageRef)pageRef but in order
 to avoid resorting to this properties are allocated in their accessors as below.
 
 
 */
#pragma mark -
#pragma mark Accessors

- (NSArray *)pageItems
{
    if (!_pageItems) {
        _pageItems = [NSMutableArray arrayWithCapacity:20];
    }
    
    return _pageItems;
}

- (TSPageBuilder *)pageBuilder
{
    if (!_pageBuilder) {
        _pageBuilder = [TSPageBuilder new];
        _pageBuilder.delegate = self.delegate;
        
        if ([self.delegate respondsToSelector:@selector(pageBuilderLoadedForPDFPage:)]) {
            [self.delegate pageBuilderLoadedForPDFPage:self];
        }
    }
    
    return _pageBuilder;
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
    
    if (_pageBuilder) {
        self.pageBuilder.delegate = delegate;
    }
}

- (CGFloat)height
{
    return [self boundsForBox:kPDFDisplayBoxMediaBox].size.height;
}

- (CGFloat)width
{
    return [self boundsForBox:kPDFDisplayBoxMediaBox].size.width;
}

#pragma mark -
#pragma mark Drawing

- (void)setMediaBoundsInMapUnits:(NSSize)size
{
    CGFloat width = size.width * self.pageBuilder.geometryAttributeScale;
    CGFloat height = size.height * self.pageBuilder.geometryAttributeScale;
    [self setBounds:NSMakeRect(0, 0, width, height) forBox:kPDFDisplayBoxMediaBox];
}

- (NSRect)boundsForBox:(PDFDisplayBox)box
{
    // we can modify the bounds if drawing is required
    // outside the default rect
    NSRect bounds = [super boundsForBox:box];
    return bounds;
}

/*
 See http://www.cocoabuilder.com/archive/cocoa/178803-pdfmarkupannotations-not-showing-when-drawing-pdfpage.html
 http://stackoverflow.com/questions/38517984/displaying-pdf-files-using-the-pdfkit-interface/38739041#38739041
 
 Before 10.12 - (void)drawWithBox:(PDFDisplayBox)box was called.
 In 10.12 - (void)drawWithBox:(PDFDisplayBox)box toContext:(CGContextRef)context was defined.
 However, on 10.12.0 NSPrintThumbnailView calls drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context not toContext:.
 Both -drawWithBox: and -drawWithBox:toContext: may call directly into -drawWithBox:inContext: but there are differences between both minor and patch versions.
 
 This matters because failure here means a failure to render any of our page items.
 The code below hopefully deals with all the encountered scenarios.
 
 */

// Public - Called pre 10.12
- (void)drawWithBox:(PDFDisplayBox)box
{
    self.didDrawPageItems = NO;
    
    [super drawWithBox:box];
    
    // draw the page items
    if (!self.didDrawPageItems) {
        [self.pageBuilder drawPageItemsToContext:nil];
        self.didDrawPageItems = YES;
    }
}

// Public - Called 10.12+ (may not be called during printing)
- (void)drawWithBox:(PDFDisplayBox)box toContext:(CGContextRef)context
{
    self.didDrawPageItems = NO;
    
    [super drawWithBox:box toContext:context];
    
    // draw the page items
    if (!self.didDrawPageItems) {
        [self.pageBuilder drawPageItemsToContext:context];
        self.didDrawPageItems = YES;
    }
}

// Private - may or may not be called by the public drawWithBox: variants above
- (void)drawWithBox:(PDFDisplayBox)box inContext:(CGContextRef)context
{
    [super drawWithBox:box inContext:context];
    
    // draw the page items
    [self.pageBuilder drawPageItemsToContext:context];
    self.didDrawPageItems = YES;
}

#pragma mark -
#pragma mark XML data map based page layout

- (void)layoutPageItemsForObject:(id)object withMapURL:(NSURL *)url
{
    // contract
    NSAssert(object, @"Object is nil");
    NSAssert(url, @"Mapping url is nil");
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NULL], @"Mapping url not found : %@", url);
    
    // load the XML document data map
    NSError *error = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
    if (!xmlDoc) {
        [NSException raise:@"XML data map exception" format:@"An error occurred loading the data map: %@", error];
    }
    
    // set the default box representing the physical medium
    self.pageBuilder.mediaBoxRect = [self boundsForBox:kPDFDisplayBoxMediaBox];
        
    // layout page for root element with object
    [self.pageBuilder addLayoutForElement:xmlDoc.rootElement withObject:object];
}

- (void)loadMapURL:(NSURL *)url
{
    // contract
    NSAssert(url, @"Mapping url is nil");
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NULL], @"Mapping url not found : %@", url);
    
    // load the XML document data map
    NSError *error = nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
    if (!xmlDoc) {
        [NSException raise:@"XML data map exception" format:@"An error occurred loading the data map: %@", error];
    }
    
    // load the root element
    [self.pageBuilder loadElement:xmlDoc.rootElement];
}

    
@end

