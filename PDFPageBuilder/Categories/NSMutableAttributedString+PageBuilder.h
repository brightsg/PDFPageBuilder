//
//  NSMutableAttributedString+PageBuilder.h
//  PDFPageBuilder
//
//  Created by Jonathan Mitchell on 21/06/2018.
//  Copyright © 2018 Thesaurus Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMutableAttributedString (PageBuilder)

- (void)tspb_scaleFontSize:(CGFloat)delta;

@end
