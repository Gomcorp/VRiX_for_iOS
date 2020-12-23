//
//  VRiX.h
//  VRiX
//
//  Created by GOMIMAC on 2017. 8. 21..
//  Copyright © 2017년 GOMIMAC. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString *const GTADPlayerDidPlayToEndTimeNotification;
extern NSString *const GTADPlayerStopByUserNotification;
extern NSString *const GTADPlayerPrepareToPlayNotification;
extern NSString *const GTADPlayerReadyToPlayNotification;
extern NSString *const GTADPlayerDidPlayBackChangeNotification;
extern NSString *const GTADPlayerDidFailToPlayNotification;

extern NSString *const VIDEO_AD_COMPLETION_REASON_KEY;
extern NSString *const VIDEO_AD_COMPLETION_REASON_COMPLETE;
extern NSString *const VIDEO_AD_COMPLETION_REASON_SKIPPED;
extern NSString *const VIDEO_AD_COMPLETION_REASON_SKIPPED_BEFORE_CLICKED;
extern NSString *const VIDEO_AD_COMPLETION_REASON_CLICKED;
extern NSString *const VIDEO_AD_COMPLETION_REASON_ERROR;
extern NSString *const VIDEO_AD_COMPLETION_OBJECT_KEY;
extern NSString *const VIDEO_AD_COMPLETION_AD_NAMES_KEY;

@class GTVMAP;
@interface VRiX : NSObject

@property (nonatomic, strong) GTVMAP*   vmap;

- (id) initWithVRiXURL:(NSURL *)URL;

@end
