//
//  NSString+InvalidChar.h
//  TwoGOM
//
//  Created by Seung-Han Kim on 12. 4. 20..
//  Copyright (c) 2012년 le5na81@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (InvalidChar)

- (NSString *)validXMLString;
- (BOOL)containsString:(NSString *)substring;
@end
