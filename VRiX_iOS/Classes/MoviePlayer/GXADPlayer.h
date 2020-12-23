//
//  GXADPlayer.h
//  GoxParser
//
//  Created by Youngchang koo on 2016. 6. 9..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "VRiX.h"

typedef NS_ENUM(NSInteger, GTADPlayerPlaybackState)
{
    GTADPlayerPlaybackStateStopped,
    GTADPlayerPlaybackStatePlaying,
    GTADPlayerPlaybackStatePaused,
};

typedef NS_ENUM(NSInteger, GTADPlayerStatus)
{
    GTADPlayerStatusUnknown,
    GTADPlayerStatusReadyToPlay,
    GTADPlayerStatusFailed,
};


@interface GXADPlayer : NSObject
@property (nonatomic, readonly, strong) AVPlayer *            corePlayer;
@property (nonatomic, readonly) GTADPlayerStatus status;                 // KVOable
@property (nonatomic, readonly) GTADPlayerPlaybackState playbackState;   // KVOable
@property (nonatomic) float rate;
@property (nonatomic, readonly, strong) NSError *error;

@property (nonatomic, copy) NSURL *contentURL;

- (id)initWithContentURL:(NSURL *)contentURL;

- (CGFloat)duration;
- (CGFloat)currentTime;

- (void)play;
- (void)pause;
- (void)stop;
- (void)stopByUser;
- (void)prepareToPlay;

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime;

@end
