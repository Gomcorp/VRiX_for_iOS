//
//  Statistics.h
//  vrix
//
//  Created by mire on 2015. 7. 15..
//  Copyright (c) 2015년 gretetch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Statistics : NSObject
+ (Statistics*)sharedStatistics;
+ (NSString*)userAgent;

- (void)sendStatisticToURL:(NSURL*)url;
- (NSString *)userAgent;
@end
