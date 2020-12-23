//
//  VRiX.m
//  VRiX
//
//  Created by GOMIMAC on 2017. 8. 21..
//  Copyright © 2017년 GOMIMAC. All rights reserved.
//

#import "VRiX.h"
#import "GTVMAP.h"

NSString *const GTADPlayerDidPlayToEndTimeNotification =
@"GTADPlayerDidPlayToEndTimeNotification";

NSString *const GTADPlayerStopByUserNotification =
@"GTADPlayerForceStopNotification";

NSString *const GTADPlayerPrepareToPlayNotification =
@"GTADPlayerPrepareToPlayNotification";

NSString *const GTADPlayerReadyToPlayNotification =
@"GTADPlayerReadyToPlayNotification";

NSString *const GTADPlayerDidPlayBackChangeNotification =
@"GTADPlayerDidPlayBackChangeNotification";

NSString *const GTADPlayerDidFailToPlayNotification =
@"GTADPlayerDidFailToPlayNotification";

NSString *const VIDEO_AD_COMPLETION_REASON_KEY =                            @"VIDEO_AD_COMPLETION_REASON_KEY";
NSString *const VIDEO_AD_COMPLETION_REASON_COMPLETE =                       @"VIDEO_AD_COMPLETION_REASON_COMPLETE";
NSString *const VIDEO_AD_COMPLETION_REASON_SKIPPED =                        @"VIDEO_AD_COMPLETION_REASON_SKIPPED";
NSString *const VIDEO_AD_COMPLETION_REASON_SKIPPED_BEFORE_CLICKED =         @"VIDEO_AD_COMPLETION_REASON_SKIPPED_BEFORE_CLICKED";
NSString *const VIDEO_AD_COMPLETION_REASON_CLICKED =                        @"VIDEO_AD_COMPLETION_REASON_CLICKED";
NSString *const VIDEO_AD_COMPLETION_REASON_ERROR =                          @"VIDEO_AD_COMPLETION_REASON_ERROR";
NSString *const VIDEO_AD_COMPLETION_OBJECT_KEY =                            @"VIDEO_AD_COMPLETION_OBJECT_KEY";
NSString *const VIDEO_AD_COMPLETION_AD_NAMES_KEY =                          @"VIDEO_AD_COMPLETION_AD_NAMES_KEY";

@interface VRiX()
@property (nonatomic, strong) NSURL*    VRiXURL;

@end
@implementation VRiX

- (id) initWithVRiXURL:(NSURL *)URL
{
    if ([super init])
    {
        self.VRiXURL = URL;
        if (_VRiXURL)
        {
            self.vmap = [[GTVMAP alloc] initWithURL:URL];;
        }
        
        return self;
    }
    
    return nil;
}

@end
