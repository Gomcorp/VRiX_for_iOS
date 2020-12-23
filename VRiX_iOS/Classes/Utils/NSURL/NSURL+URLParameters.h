//
//  NSURL+URLParameters.h
//  GomGuide
//
//  Created by Ku youngchang on 11/15/13.
//  Copyright (c) 2013 Ku youngchang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (URLParameters)
- (NSString *)URLStringWithoutQuery;
- (NSMutableDictionary *) getURLParameters;
- (NSURL *) URLByAppendingQueryString:(NSString *)queryString;
- (NSURL *) URLByAppendingParamDictionary:(NSDictionary *)parameters;
@end
