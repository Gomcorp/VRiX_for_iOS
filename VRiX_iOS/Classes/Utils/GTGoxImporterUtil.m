//
//  GTGoxImporterUtil.m
//  TwoGOM
//
//  Created by Seung-Han Kim on 12. 4. 20..
//  Copyright (c) 2012년 le5na81@gmail.com. All rights reserved.
//

#import "GTGoxImporterUtil.h"

#import "GTGoxConstants.h"
#import "GTVMAP.h"
#import "GTVAST.h"

#import <objc/message.h>

#import "XMLDictionary.h"

#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/ASIdentifierManager.h>
#import "GoxUtils.h"

SEL GTSelecterFromKey(NSString* key)
{
    if([key length] > 0)
    {
        NSString* firstChar = [[key substringWithRange:NSMakeRange(0, 1)] uppercaseString];
        NSString* otherChars = [key length] > 1 ? [key substringWithRange:NSMakeRange(1, [key length] - 1)] : @"";
        NSString* selectorName = [NSString stringWithFormat:@"set%@%@:", firstChar, otherChars];
        
        SEL selector = NSSelectorFromString(selectorName);
        return selector;
    }
    
    return NULL;
}

void GTGoxSetValue(id owner, NSString* key, id value)
{
    @try 
    {
        [owner setValue:value
                 forKey:key];
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetValue] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxAddObject(id owner, NSString* key, id value)
{
    @try 
    {
        if(value != nil)
        {
            NSMutableArray* array = (NSMutableArray*)[owner valueForKey:key];
            
            [array addObject:value];
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxAddObject] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxSetInteger(id owner, NSString* key, id value)
{
    @try 
    {
        NSInteger integerValue = [value integerValue];
        
        SEL selector = GTSelecterFromKey(key);
        if(selector != NULL)
        {
            ((void (*)(id, SEL, NSInteger))objc_msgSend)(owner, selector, integerValue);
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetInteger] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxSetBoolean(id owner, NSString* key, id value)
{
    @try 
    {
        BOOL boolValue = [value boolValue];
        
        SEL selector = GTSelecterFromKey(key);
        if(selector != NULL)
        {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(owner, selector, boolValue);
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetBoolean] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxSetFloat(id owner, NSString* key, id value)
{
    @try 
    {
        CGFloat floatValue = [value floatValue];

        SEL selector = GTSelecterFromKey(key);
        if(selector != NULL)
        {
            ((void (*)(id, SEL, CGFloat))objc_msgSend)(owner, selector, floatValue);
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetFloat] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxSetTimeIntervalFromMicroSecond(id owner, NSString* key, id value)
{
    @try 
    {
        long long longLongValue = [value longLongValue];
        NSTimeInterval timeInterval = (CGFloat)longLongValue / 1000.0f;
        
        SEL selector = GTSelecterFromKey(key);
        if(selector != NULL)
        {
            ((void (*)(id, SEL, NSTimeInterval))objc_msgSend)(owner, selector, timeInterval);
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetTimeIntervalFromMicroSecond] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}

void GTGoxSetPoint(id owner, NSString* key, id value)
{
    @try 
    {
        CGPoint point = [value CGPointValue];
        
        SEL selector = GTSelecterFromKey(key);
        if(selector != NULL)
        {
            ((void (*)(id, SEL, CGPoint))objc_msgSend)(owner, selector, point);
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"[GTGoxSetFloat] exception : %@", [exception reason]);
    }
    @finally 
    {
    }
}




id GTGoxStringFromValue(NSString* value)
{
    if([value isKindOfClass:[NSString class]])
    {
        return value;
    }
    return nil;
}

id GTGoxVrixDataStringFromNode(NSDictionary* node)
{
    GTVMAP *vmap = [[GTVMAP alloc] initWithVMAPString:node.XMLString];
    return vmap;
}

id GTGoxVrixReferenceStringFromNode(NSDictionary* node)
{
    NSString *vrixURL = GTGoxReferenceStringFromNode(node);
    vrixURL = [vrixURL stringByReplacingOccurrencesOfString:@"|" withString:[@"|" stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:vrixURL];
    GTVMAP *vmap = [[GTVMAP alloc] initWithURL:url];
    return vmap;
}

id GTGoxVASTDataStringFromNode(NSDictionary* node)
{
    NSString *vrixURL = GTGoxReferenceStringFromNode(node);
    vrixURL = [vrixURL stringByReplacingOccurrencesOfString:@"|" withString:[@"|" stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:vrixURL];
    GTVMAP *vmap = [[GTVMAP alloc] initWithURL:url];
    return vmap;
}

id GTGoxReferenceStringFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [node valueForKeyPath:[NSDictionary changeAttributename:GTGoxAttributeReference]];;
    }
    return nil;
}

id GTGoxDRMStringFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [node valueForKeyPath:[NSDictionary changeAttributename:GTGoxAttributeDRM]];;
    }
    return @"no-drm";
}

id GTVMAPAdBreakFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTVMAPAdBreak alloc] initWithElement:node];
    }
    return nil;
    
}

id GTVMAPAdSourceFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTVMAPAdSource alloc] initWithElement:node];
    }
    return nil;
    
}

id GTVMAPAdTagURIFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTVMAPAdTagURI alloc] initWithElement:node];
    }
    return nil;
    
}

id GTVMAPVASTFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTVAST alloc] initWithElement:node];
    }
    return nil;
    
}

id GTVMAPVASTAdDataFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTVASTAdData alloc] initWithElement:node];
    }
    return nil;
    
}

id GTVASTAdFromNode(NSDictionary* node)
{
    if([node isKindOfClass:[NSDictionary class]] == YES)
    {
        return [[GTAd alloc] initWithElement:node];
    }
    return nil;
    
}

id GTGoxIntegerFromValue(NSString* value)
{
    NSInteger result = 0;
    if([value isKindOfClass:[NSString class]])
    {
        result = [value integerValue];
    }
    
    
    return [NSNumber numberWithInteger:result];
}

id GTGoxBooleanFromValue(NSString *value)
{
    BOOL result = NO;
    if([value isKindOfClass:[NSString class]])
    {
        NSString* stringValue = value;
        if([stringValue boolValue] == YES || [[stringValue uppercaseString] isEqualToString:@"YES"] == YES)
        {
            result = YES;
        }
    }
    
    return [NSNumber numberWithBool:result];
}

id GTGoxFloatFromValue(NSString *value)
{
    CGFloat result = 0.0;
    if([value isKindOfClass:[NSString class]])
    {
        result = [value floatValue];
    }
    
    
    return [NSNumber numberWithInteger:result];
}

id GTGoxLongLongFromValue(NSString *value)
{
    long long result = 0.0;
    if([value isKindOfClass:[NSString class]])
    {
        result = [value longLongValue];
    }
    
    
    return [NSNumber numberWithLongLong:result];
}

id GTGoxPointFromValue(NSString *value)
{
    @try
    {
        if(![value isKindOfClass:[NSString class]])
        {
            NSException *e = [NSException
                              exceptionWithName:@"Invalid type"
                              reason:@"Invalide type"
                              userInfo:nil];
            @throw e;
        }
        NSRange separator = [value rangeOfString:@","];
        
        CGFloat x = [[value substringToIndex:separator.location] floatValue];
        CGFloat y = [[value substringFromIndex:separator.location + separator.length] floatValue];
        
        CGPoint result = CGPointMake(x, y);
        
        return [NSValue valueWithCGPoint:result];
    }
    @catch (NSException *exception) 
    {
        return [NSValue valueWithCGPoint:CGPointZero];
    }
    @finally 
    {
    }
}

id GTGoxElementFromNode(NSDictionary* node)
{
    return node;
}

id GTConvertTimeIntervalTypeFromString(NSString *time)
{
    if ([time isEqualToString:@"start"])
    {
        return [NSNumber numberWithInteger:0];
    }
    else if([time isEqualToString:@"end"])
    {
        return [NSNumber numberWithInteger:2];
    }
    
    return [NSNumber numberWithInteger:1];
}

id GTConvertTimeIntervalFromString(NSString *time)
{
    if ([time isEqualToString:@"start"])
    {
        return [NSNumber numberWithInteger:0];
    }
    else if([time isEqualToString:@"end"])
    {
        return [NSNumber numberWithInteger:0];
    }
    
    NSArray *temp = [time componentsSeparatedByString:@":"];
    NSTimeInterval interval = 0;
    for (int i = 0; i < [temp count]; i++)
    {
        // hour
        if (i == 0)
        {
            NSInteger hour = [[temp objectAtIndex:i] integerValue];
            interval += hour * 60 * 60;
        }
        // min
        else if (i == 1)
        {
            NSInteger min = [[temp objectAtIndex:i] integerValue];
            interval += min * 60;
        }
        // sec
        else
        {
            NSInteger sec = [[temp objectAtIndex:i] integerValue];
            interval += sec;
        }
        
        
    }
    
    return [NSNumber numberWithInteger:interval];

}

NSString *aaid = @"";
NSString *identifierForAdvertising(void)
{
    static dispatch_once_t onceAAID;
    dispatch_once(&onceAAID, ^{
        if (@available(iOS 14, *)) {

            __block NSString *idfa = @"";
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status)
            {
                //
                switch (status) {
                    case ATTrackingManagerAuthorizationStatusAuthorized:
                    {
                        NSUUID *IDFA = [[ASIdentifierManager sharedManager] advertisingIdentifier];
                        idfa = [IDFA UUIDString];
                        break;
                    }

                    default:
                        break;
                }

                dispatch_semaphore_signal(sem);
            }];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            
            aaid = idfa;
        } else
        {
            NSString *idfa = @"";
            if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
            {
                NSUUID *IDFA = [[ASIdentifierManager sharedManager] advertisingIdentifier];
                
                idfa = [IDFA UUIDString];
                aaid = idfa;
            }
        }
    });
    
    
    return aaid;
}
