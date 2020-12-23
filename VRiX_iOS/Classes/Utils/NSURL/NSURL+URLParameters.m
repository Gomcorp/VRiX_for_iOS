//
//  NSURL+URLParameters.m
//  GomGuide
//
//  Created by Ku youngchang on 11/15/13.
//  Copyright (c) 2013 Ku youngchang. All rights reserved.
//

#import "NSURL+URLParameters.h"

@implementation NSURL (URLParameters)
static NSString *StringByAddingPercentEscapesForURLArgument(NSString *string) {
    
    NSCharacterSet *allowedCharacters = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *percentEncodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    
    return percentEncodedString;
//    NSString *escapedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                                                                    (CFStringRef)string,
//                                                                                                    NULL,
//                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
//                                                                                                    kCFStringEncodingUTF8));
//    return escapedString;
}

static NSString *HTTPArgumentsStringForParameters(NSDictionary *parameters) {
	NSMutableArray *arguments = [NSMutableArray array];
    
	for (NSString *key in parameters) {
		NSString *parameter = [NSString stringWithFormat:@"%@=%@", key, StringByAddingPercentEscapesForURLArgument([parameters objectForKey:key])];
		[arguments addObject:parameter];
	}
	
	return [arguments componentsJoinedByString:@"&"];
}


- (NSString *)URLStringWithoutQuery
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}

- (NSMutableDictionary *) getURLParameters
{
    NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
    if ([parts count] <= 1)
    {
        return [NSMutableDictionary dictionary];
    }
    NSString *query = [parts objectAtIndex:1];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    for (NSString *param in [query componentsSeparatedByString:@"&"])
    {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    
    return params;
}

- (NSURL *) URLByAppendingQueryString:(NSString *)queryString
{
    if (![queryString length])
    {
        return self;
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@",[self absoluteString], [self query] ? @"&" : @"?", queryString];
    return [NSURL URLWithString:URLString];
}

- (NSURL *) URLByAppendingParamDictionary:(NSDictionary *)parameters
{
    NSString *queryString = HTTPArgumentsStringForParameters(parameters);
    
    return [self URLByAppendingQueryString:queryString];
}

@end
