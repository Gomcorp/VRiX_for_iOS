//
//  GTMovieStatistics.m
//  Ade
//
//  Created by mire on 2015. 7. 15..
//  Copyright (c) 2015년 gretetch. All rights reserved.
//

#import "Statistics.h"
#import "NSURL+URLParameters.h"
#import "GTGoxImporterUtil.h"
#import "GTGoxConstants.h"
#import "VRiXManager.h"
#include <sys/sysctl.h>
#import <WebKit/WebKit.h>

@interface Statistics()
    @property (nonatomic, retain) WKWebView* webView;
@end

static NSString* const GTPageViewTriggerClickURLFormat = @"http://ana.gomtv.com/cgi-bin/click.cgi?ltype=click&gid=%@&appname=GOMTV&dataype=xml";

@implementation Statistics

static NSString* _userAgent = nil;
static Statistics* _sharedStatistics = nil;

+ (Statistics*) sharedStatistics
{
    if (_sharedStatistics == nil)
    {
        @synchronized ([Statistics class])
        {
            if (_sharedStatistics == nil)
            {
                _sharedStatistics = [[super allocWithZone:NULL] init];
//                [[self class] userAgent];
            }
        }
    }
    
    return _sharedStatistics;
}
    
- (id) init {
    if ([super init]) {
        //[self userAgent];
        return self;
    }
    
    return nil;
}

+ (NSString*)userAgent {
    if(_userAgent == nil)
    {
        static dispatch_once_t onceUserAgent;
        dispatch_once(&onceUserAgent, ^{
            NSString *model = [[UIDevice currentDevice] model];
            NSString *sysVer = [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
            NSString *version = VRIX_IOS_LIBRARY_VERSION;
            NSString *machineName = GTSystemInfo("hw.machine");
            NSString *versinoString = [NSString stringWithFormat:@"%@ OS %@ VRIX_SDK_iOS/%@/%@", model, sysVer, version, machineName];
            
            _userAgent = versinoString;
        });
    }
    
    return _userAgent;
}
    
- (NSString*)userAgent
{
    if(_userAgent == nil)
    {
        if (_webView == nil) {
            WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
            [webView loadHTMLString:@"<html></html>" baseURL:nil];
            
            self.webView = webView;
        }
        
        
        [_webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError * _Nullable error) {
            //
            if (result != nil && [result isKindOfClass:[NSString class]]) {
                _userAgent = (NSString *) result;
                
                NSString *version = VRIX_IOS_LIBRARY_VERSION;
                NSString *machineName = GTSystemInfo("hw.machine");
                NSString *versinoString = [NSString stringWithFormat:@" VRIX_SDK_iOS/%@/%@", version, machineName];
                
                if ([self.userAgent rangeOfString:versinoString].location == NSNotFound)
                {
                    _userAgent = [[self.userAgent stringByAppendingString:versinoString] copy];
                    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": self.userAgent}];
                }
            }
            
        }];
        
    }
    return _userAgent;
}
//+ (NSString*)userAgent
//{
//    if(_userAgent == nil)
//    {
//        static dispatch_once_t onceUserAgent;
//        dispatch_once(&onceUserAgent, ^{
//            UIWebView *webView = [[UIWebView alloc] init];
//            NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
//            _userAgent = [userAgent copy];
//
//            NSString *version = VRIX_IOS_LIBRARY_VERSION;
//            NSString *machineName = GTSystemInfo("hw.machine");
//            NSString *versinoString = [NSString stringWithFormat:@" VRIX_SDK_iOS/%@/%@", version, machineName];
//
//            if ([userAgent rangeOfString:versinoString].location == NSNotFound)
//            {
//                _userAgent = [[userAgent stringByAppendingString:versinoString] copy];
//                [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
//            }
//        });
//
//    }
//    return _userAgent;
//}

static NSString *GTSystemInfo(const char *name)
{
    size_t size = 0;
    sysctlbyname(name, NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname(name, answer, &size, NULL, 0);
    NSString *result = [NSString stringWithUTF8String:answer];
    free(answer);
    
    return result;
}

- (void)sendStatisticToURL:(NSURL*)url
{
    if(url != nil)
    {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
//        [request setValue:[[self class] userAgent] forHTTPHeaderField:@"User-Agent"];
        [request addValue:identifierForAdvertising() forHTTPHeaderField:GTGoxHeaderKeyAAID];
        
         [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
    }
}



@end
