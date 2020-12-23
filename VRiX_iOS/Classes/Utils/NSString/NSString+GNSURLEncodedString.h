//
//  NSString+GNSURLEncodedString.h
//  TwoGOM
//
//  Created by 김승한 on 12. 12. 11..
//
//

#import <Foundation/Foundation.h>

#define kCFEUCKRStringEncoding 0x80000000 + kCFStringEncodingDOSKorean

@interface NSString (GNSURLEncodedString)

- (NSString*)urlEncodedStirng;
- (NSString*)urlEncodedStirngWithStringEncoding:(CFStringEncoding)encoding;
- (NSString*)urlDecodedString;
- (NSString*)urlDecodedStringWithStringEncoding:(CFStringEncoding)encoding;

@end
