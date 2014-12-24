//
//  AppDelegate.m
//  PageBuilderDemo
//
//  Created by Jonathan Mitchell on 23/12/2014.
//  Copyright (c) 2014 Thesaurus Software. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoPDFDocument.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSURL *dataMapURL;
@property (strong, nonatomic) NSURL *pdfTemplateURL;
@property (strong, nonatomic) DemoPDFDocument *pdfDocument;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // load an existing pdf document or create a new empty document
    self.pdfTemplateURL = [[NSBundle mainBundle] URLForResource:@"Demo-A4" withExtension:@"pdf"];
    
    // Note that we use a TSPDFDocument subclass.
    // This is not a requirement but helps with more complex documents.
    self.pdfDocument = [[DemoPDFDocument alloc] initWithURL:self.pdfTemplateURL];

    // assign document to view
    self.pdfView.document = self.pdfDocument;

    // get url for the XML dara map
    self.dataMapURL = [[NSBundle mainBundle] URLForResource:@"Demo-A4.map" withExtension:@"xml"];

    // get the data objects
    NSArray *objects = [self targetObject];
    
    // load the map constants
    [self.pdfDocument loadDataMapURL:self.dataMapURL];
    
    // add pages for objects and map
    NSInteger pageIndex = 0;
    NSInteger objectIndex = 0;
    NSInteger partIndex = 0;
    for (id object in objects) {
        
        // page index for object
        pageIndex = objectIndex / self.pdfDocument.documentsPerPage;
        
        // part index is 0 to self.pdfDocument.documentsPerPage - 1
        partIndex = objectIndex % self.pdfDocument.documentsPerPage;
        
        // add map for object at indicated page index and part index
        [self.pdfDocument layoutPageItemsForObject:object withMapURL:self.dataMapURL pageIndex:pageIndex partIndex:partIndex];
        
        objectIndex++;
    }
    
    // obliterate any unused document parts on last page of template pages
    if (self.pdfTemplateURL && partIndex < self.pdfDocument.documentsPerPage - 1) {
        
        // get the last indexed page
        TSPDFPage *page = (id)[self.pdfDocument pageAtIndex:pageIndex];
        
        CGFloat x = 0;
        CGFloat y = page.height * (partIndex + 1) / self.pdfDocument.documentsPerPage;
        CGFloat w = page.width;
        CGFloat h = page.height - y;
        
        // get the rect to be obliterated
        NSRect rect = NSMakeRect(x, y, w, h);
        
        // manually add item to the page
        
        // add an empty text item to obliterate the unwanted content in the target rect
        [page.pageBuilder pushMapKey:TSKeyBorderBackground value:@"FFFFFF"];
        [page.pageBuilder addTextItem:[[NSAttributedString alloc] initWithString:@""] rect:rect];
        [page.pageBuilder popMapKey:TSKeyBorderBackground];
        
    }
    
    [self.pdfView layoutDocumentView];
}


- (id)targetObject
{
    // target can be of any class as long as it responds to the required keys
    id object = @{
                    // title keys
                    @"AppName" : @"PageBuilder Demo : ",
                    @"IsConditionA" : @YES,
                    @"CondA" : @"A",
                    @"CondAValue" : @"true",
                    @"IsConditionB" : @YES,
                    @"CondB" : @"B",
                    @"CondC" : @"C",
                    
                    @"IsLogoIncluded" : @YES,
                    @"Logo" : @"DemoLogo.jpeg",
                    
                    @"Box1Details" : @[
                                        @{@"Key" : @"Key 1", @"Value" : @"Value 1"},
                                        @{@"Key" : @"Key 2", @"Value" : @"Value 2"},
                                        @{@"Key" : @"Key 3", @"Value" : @"Value 4"},
                                        @{@"Key" : @"Key 4", @"Value" : @"Value 4"},
                                        ],
                    
                    @"Box2Details" : @[
                                        @{@"Key" : @"Key 1", @"Value" : @100},
                                        @{@"Key" : @"Key 2", @"Value" : @200},
                                        @{@"Key" : @"Key 3", @"Value" : @300},
                                        @{@"Key" : @"Key 4", @"Value" : @400},
                            ],
                    @"Box2Total" : @1000,
                    
                    @"Box3Details" : @[
                                        @{@"Key" : @"Key 1", @"Value" : @1000},
                                        @{@"Key" : @"Key 2", @"Value" : @2000},
                                        @{@"Key" : @"Key 3", @"Value" : @3000},
                                        @{@"Key" : @"Key 4", @"Value" : @4000},
                            ],
                    @"Box3Total" : @10000,
                    
                    @"Box 4 Title" : @"Box 4",
                    @"Box4Details" : @[
                            @{@"Key" : @"Key 1", @"Value" : @"Cats"},
                            @{@"Key" : @"Key 2 is short", @"Value" : @"Dogs"},
                            @{@"Key" : @"Key 3 is longer", @"Value" : @"Fleas"},
                            @{@"Key" : @"Key 4 is the longest of all and should wrap nicely", @"Value" : @"Bats"},
                            @{@"Key" : @"Key 5 is quite long too", @"Value" : @"Fish"},
                            ],
                    
                    @"Box5Details" : @[
                            @{@"Key" : @"Key 1", @"Value" : @"Alpha"},
                            @{@"Key" : @"Key 2", @"Value" : @"Bravo"},
                            @{@"Key" : @"Key 3", @"Value" : @"Charlie"},
                            @{@"Key" : @"Key 4", @"Value" : @"Delta"},
                            ],
                    
                    @"Box6Content" : @{ @"Title" : @"This is Big!", @"Sub Content 1" : @"sub 1"},
                    @"IsBox6Sub1" : @YES,
                    @"ShowCredits" : @YES
                    };

    
    // repeat the object
    return @[object, object, object];
}
@end
