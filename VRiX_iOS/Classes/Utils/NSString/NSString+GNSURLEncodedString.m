//
//  NSString+GNSURLEncodedString.m
//  TwoGOM
//
//  Created by 김승한 on 12. 12. 11..
//
//

#import "NSString+GNSURLEncodedString.h"

@implementation NSString (GNSURLEncodedString)

- (NSString*)urlEncodedStirng
{
    return [self urlEncodedStirngWithStringEncoding:kCFStringEncodingUTF8];
}

- (NSString*)urlEncodedStirngWithStringEncoding:(CFStringEncoding)encoding
{
    NSString* encodedUrl = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                 (CFStringRef)self,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                 encoding));
	return encodedUrl;
}

- (NSString*)urlDecodedString
{
    return [self urlDecodedStringWithStringEncoding:kCFStringEncodingUTF8];
}

- (NSString*)urlDecodedStringWithStringEncoding:(CFStringEncoding)encoding
{
    NSString* decodeUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                               (CFStringRef)self,
                                                                                                               (CFStringRef)@"",
                                                                                                               encoding));
    
    return decodeUrl;
}
@end
