//
//  DemoPDFDocument.m
//  PageBuilderDemo
//
//  Created by Jonathan Mitchell on 22/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import "DemoPDFDocument.h"

// scale WPF device independent pixels to points
#define WPF_DIP_TO_PTS (72.0/96.0)

@interface DemoPDFDocument ()

@end


@implementation DemoPDFDocument

#pragma mark -
#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if (self) {
        self.url = url;
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
    // these ivars hold map constants
    _documentsPerPage = 1;
    _nthPageVerticalOffset = 0,0;
    
    // subclass will act as the delegate
    self.delegate = self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutPageItemsForObject:(NSObject *)object withMapURL:(NSURL *)mapURL pageIndex:(NSUInteger)pageIndex partIndex:(NSUInteger)partIndex
{
    // get existing page or append new page
    NSUInteger pageCount = [self pageCount];
    TSPDFPage *page = nil;
    if (pageIndex < pageCount) {
        
        page = (id)[self pageAtIndex:pageIndex];
        
    } else if (pageIndex == pageCount) {
        
        if (self.url) {
            
            // get page from template url
            DemoPDFDocument *document = [[DemoPDFDocument alloc] initWithURL:self.url];
            page = (id)[document pageAtIndex:0];
            [document removePageAtIndex:0];
            
            // add to document
            [self insertPage:page atIndex:pageIndex];
            
        } else {
            
            // insert new page
            [self insertNewPageAtIndex:pageIndex pageSize:TSPageSizeA4];
            
            page = (id)[self pageAtIndex:pageIndex];
        }
    } else {
        NSAssert(NO, @"invalid page index : %li", pageIndex);
    }
    
    // validate the page
    NSAssert([page isKindOfClass:[TSPDFPage class]], @"invalid pdf page class");
    
    // receiver is the the page delegate
    page.delegate = self;
    
    // set font size scale
    // the input map font size is in WPF device independent pixels so scale to points
    page.pageBuilder.fontSizeAttributeScale = WPF_DIP_TO_PTS;
    
    // the part index represents a part of a page to which the object is mapped
    if (self.documentsPerPage > 1 && partIndex) {
        CGFloat yOffset = (page.height/self.documentsPerPage + self.nthPageVerticalOffset) * partIndex;
        page.pageBuilder.layoutOffset = NSMakePoint(0, yOffset);
    }
    
    // layout the object on the given page index
    [self layoutPageItemsForObject:object withMapURL:mapURL pageIndex:pageIndex];
}

#pragma mark -
#pragma mark Data map

- (void)loadDataMapURL:(NSURL *)url
{
    // load the map for the first page without performing any layout
    TSPDFPage *page = (id)[self pageAtIndex:0];
    [page loadMapURL:url];
    
    // access the loaded constant elements dictionary
    NSDictionary *dict = page.pageBuilder.constantElementDictionary;
    
    id value = nil;
    
    // number per page
    value = dict[@"NumberPerPage"];
    if (value) {
        self.documentsPerPage = [[[NSNumberFormatter new] numberFromString:value] integerValue];
    }
}

#pragma mark -
#pragma mark TSPDFDocumentDelegate

- (void)pdfDocument:(TSPDFDocument *)document willLayoutPage:(TSPDFPage *)page
{
}

#pragma mark -
#pragma mark TSPDFPageDelegate

- (void)pageBuilderLoadedForPDFPage:(TSPDFPage *)page
{
    // set to YES to highlight container rects in order to resolve layout issues
    page.pageBuilder.highlightPageItemContainerRects = NO;
}

#pragma mark -
#pragma mark TSPageBuilderDelegate

- (NSData *)imageDataForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key object:(id)object
{
    // this optional delegate method is called because the pagebuilder has a source object for an image element
    // that is not an NSData instance. we have to return a valid NSData object that encodes the image represented by object
    
    NSAssert([object isKindOfClass:[NSString class]], @"invalid object");
    NSImage *image = [NSImage imageNamed:(id)object];
    
    return [image TIFFRepresentation];
}

- (NSColor *)colorForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key string:(NSString *)string
{
    // this optional delegate method is called to allow color customization.
    // be default color values are interpreted as hexRGB.
    NSColor *color = nil;
    
    // allow use of class color methods
    if ([NSColor respondsToSelector:NSSelectorFromString(string)]) {
        color = [NSColor performSelector:NSSelectorFromString(string)];
    } else {
        
        // resort to default
        color = [NSColor tspb_colorFromHexRGB:string alpha:1.0];
    }
    
    return color;
}

- (NSString *)fontFamilyNameForPageBuilder:(TSPageBuilder *)pageBuilder key:(NSString *)key string:(NSString *)string
{
    // this optional delegate method is called to allow font customization.
    
    NSString *fontFamilyName = string;
    
    return fontFamilyName;
}

- (BOOL)validateStringForPageBuilder:(TSPageBuilder *)pageBuilder string:(NSString *)string
{
    // this optional delegate method is called to allow string validation.
    if ([string isEqualToString:@"£"]) return NO;
    
    return YES;
}

@end
