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
@end

@interface TSPDFPage()
@property (strong,nonatomic) NSArray *pageItems;
@property (strong,readwrite,nonatomic) TSPageBuilder *pageBuilder;

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
    return [super boundsForBox:box];
    
}
- (void)drawWithBox:(PDFDisplayBox)box
{
    [super drawWithBox:box];
    
    // draw the page items
    [self.pageBuilder drawPageItems];
}

#pragma mark -
#pragma mark XML data map based page layout

- (void)layoutPageItemsForObject:(id)object withMapURL:(NSURL *)url
{
    // contract
    NSAssert(object, @"Object is nil");
    NSAssert(url, @"Mapping url is nil");
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NO], @"Mapping url not found : %@", url);
    
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
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NO], @"Mapping url not found : %@", url);
    
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

