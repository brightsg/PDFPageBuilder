//
//  DemoPDFDocument.h
//  PageBuilderDemo
//
//  Created by Jonathan Mitchell on 22/12/2014.
//  Copyright (c) 2014 Thesaurus Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PDFPageBuilder/PDFPageBuilder.h>

@interface DemoPDFDocument : TSPDFDocument <TSPDFDocumentDelegate, TSPDFPageDelegate, TSPageBuilderDelegate>

@property (strong) NSURL *url;
@property (assign) NSInteger documentsPerPage;
@property (assign) CGFloat nthPageVerticalOffset;

- (void)layoutPageItemsForObject:(NSObject *)object withMapURL:(NSURL *)mapURL pageIndex:(NSUInteger)pageIndex partIndex:(NSUInteger)partIndex;
- (void)loadDataMapURL:(NSURL *)url;
@end
