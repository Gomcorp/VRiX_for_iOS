//
//  GoxUtils.h
//  TwoGOM
//
//  Created by 이 욱정 on 11. 10. 25..
//  Copyright (c) 2011년 Gretech. All rights reserved.
//



#import <UIKit/UIKit.h>

enum _GXConnectionType {
    GXConnectionTypeUnknown = 0,
    GXConnectionTypeNone,
    GXConnectionType3G,
    GXConnectionTypeWiFi
};
typedef enum _GXConnectionType GXConnectionType;

@interface NSString (MD5)
- (NSString *)MD5String;
@end

@interface NSString (GoxParseCategory)
- (NSMutableDictionary *)explodeToDictionaryInnerSeparator:(NSString *)innerSeparator
                                           outterSeparator:(NSString *)outterSeparator;
@end

@interface NSArray (GoxParseURLQueries)
- (NSMutableDictionary *)parseURLQuery;
@end
