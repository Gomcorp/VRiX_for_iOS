//
//  GoxUtils.m
//  TwoGOM
//
//  Created by 이 욱정 on 11. 10. 25..
//  Copyright (c) 2011년 Gretech. All rights reserved.
//
#import "GoxUtils.h"
#include <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CommonCrypto/CommonDigest.h>
//#import <NFKit/NFCommonUtils.h>

#define kGoxUtilsReachabilityKey @"line"
#define kGoxUtils3GString        @"1"
#define kGoxUtilsWifiString      @"16"

#define GoxCategoryTypeMovie				@"movie"
#define GoxCategoryTypeBroadcast			@"broadcast"
#define GoxCategoryTypeGame                 @"game"
#define GoxCategoryTypeMusicVideo           @"musicvideo"

@implementation NSString (MD5)
- (NSString *)MD5String
{
    const char * pointer = [self UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
    
    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x",md5Buffer[i]];
    
    return string;
}

@end

@implementation NSString (ParseCategory)

- (NSMutableDictionary *)explodeToDictionaryInnerSeparator:(NSString *)innerSeparator
                                           outterSeparator:(NSString *)outterSeparator
{
    NSArray* firstExplode = [self componentsSeparatedByString:outterSeparator];
    NSArray* secondExplode = nil;
    
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:[firstExplode count]];
    for (NSString* explodedString in firstExplode)
    {
        secondExplode = [explodedString componentsSeparatedByString:innerSeparator];
        if ([secondExplode count] == 2) 
        {
            [result setObject:[secondExplode objectAtIndex:1]
                       forKey:[secondExplode objectAtIndex:0]];
        }
    }
    
    return result;
}

@end

@implementation NSArray (GoxParseURLQueries)

- (NSMutableDictionary *)parseURLQuery
{
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    for (NSURLQueryItem *item in self)
    {
        [result setObject:item.value forKey:item.name];
    }
    
    return result;
}

@end
