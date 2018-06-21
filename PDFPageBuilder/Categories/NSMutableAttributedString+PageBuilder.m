//
//  NSMutableAttributedString+PageBuilder.m
//  PDFPageBuilder
//
//  Created by Jonathan Mitchell on 21/06/2018.
//  Copyright © 2018 Thesaurus Software. All rights reserved.
//

#import "NSMutableAttributedString+PageBuilder.h"

@implementation NSMutableAttributedString (PageBuilder)

- (void)tspb_scaleFontSize:(CGFloat)scale
{
    [self beginEditing];
    [self enumerateAttributesInRange: NSMakeRange(0, [self length])
                                    options: 0
                                 usingBlock: ^(NSDictionary *attributesDictionary,
                                               NSRange range,
                                               BOOL *stop)
     {
#pragma unused(stop)
         NSFont *font = [attributesDictionary objectForKey:NSFontAttributeName];
         if (font) {
             [self removeAttribute:NSFontAttributeName range:range];
             font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * scale];
             [self addAttribute:NSFontAttributeName value:font range:range];
         }
     }];
    [self endEditing];
}
@end
