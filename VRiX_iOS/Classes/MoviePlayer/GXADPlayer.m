//
//  GXADPlayer.m
//  GoxParser
//
//  Created by Youngchang koo on 2016. 6. 9..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//
#import "GXADPlayer.h"
#import <UIKit/UIKit.h>
#import "NSString+InvalidChar.h"

#define GTKeyPathStatus                 @"status"

// Asset keys
#define GTKeyPathTracks                 @"tracks"
#define GTKeyPathPlayable               @"playable"

// PlayerItem keys
#define GTKeyPathItemTracks             @"playerItem.tracks"
#define GTKeyPathItemDuration           @"playerItem.duration"

// Player keys
#define GTKeyPathPlayerItemStatus       @"currentItem.status"
#define GTKeyPathPlayerRate             @"rate"

@interface GXADPlayer()<AVAudioSessionDelegate>

@property (nonatomic, strong) AVPlayer *            corePlayer;
@property (nonatomic) GTADPlayerStatus           status;          // KVOable
@property (nonatomic) GTADPlayerPlaybackState    playbackState;   // KVOable
@property (nonatomic, strong) NSError *             error;

@property (nonatomic) BOOL                          preparingToPlay;
@property (nonatomic) BOOL                          forceStop;
@property (nonatomic) BOOL                          usesApplicationAudioSession;
@property (nonatomic) BOOL                          interruptedWhilePlaying;
@property (nonatomic, strong) NSTimer *             timelineTimer;

@property (nonatomic) BOOL                          isSendStartCall;
@end

@implementation GXADPlayer
@synthesize error   = _error;
@synthesize status  = _status;
@synthesize playbackState = _playbackState;
@synthesize corePlayer = _corePlayer;

- (id)initWithContentURL:(NSURL *)contentURL
{
    self = [self init];
    
    if (self) {
        _rate = 1.0;
        
        _corePlayer = [[AVPlayer alloc] initWithURL:contentURL];
        
        [_corePlayer addObserver:self forKeyPath:GTKeyPathPlayerItemStatus options:0 context:nil];
        [_corePlayer addObserver:self forKeyPath:GTKeyPathPlayerRate options:0 context:nil];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(GT_playerItemDidPlayToEndTime:)
                                   name:AVPlayerItemDidPlayToEndTimeNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(GT_handleRouteChange:)
                                   name:AVAudioSessionRouteChangeNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        
        
        _contentURL = contentURL;
    }
    
    return self;
    
}

- (void) applicationDidEnterBackground:(id)sender
{
    if (self.playbackState == GTADPlayerPlaybackStatePlaying && self.status == GTADPlayerStatusReadyToPlay)
    {
        [self pause];
    }
}

- (void) applicationWillEnterForeground:(id)sender
{
    if (self.playbackState == GTADPlayerPlaybackStatePaused && self.status == GTADPlayerStatusReadyToPlay)
    {
        [self play];
    }
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [notificationCenter removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.isSendStartCall = NO;
}

- (void)setContentURL:(NSURL *)contentURL
{
    if (self.contentURL != contentURL)
    {
        if (_playbackState == GTADPlayerPlaybackStatePlaying) {
            [self stop];
        }
        
        
        _contentURL = contentURL;
    }
}
#pragma mark -
- (void)play
{
    if (_status == GTADPlayerStatusFailed)
    {
        //
        NSLog(@"AssetPlayer's status is \"Failed\".\nError: %@", _error);
        return;
    }
    else if (_status == GTADPlayerStatusReadyToPlay)
    {
        // -[AVPlayer play]는 rate를 무조건 1.0으로 세팅하므로 play가 아니라 rate를 호출해야 한다.
        //_corePlayer.rate = _rate;
        [_corePlayer play];
        [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerReadyToPlayNotification object:self];
        
        [self startTicking];
        if (_playbackState != GTADPlayerPlaybackStatePlaying)
        {
            self.playbackState = GTADPlayerPlaybackStatePlaying;
        }
    }
    else
    {
        if (_preparingToPlay == NO && self.contentURL && _forceStop == NO)
        {
            [self prepareToPlay];
            if (_preparingToPlay)
            {
                // 재생할 준비가 되면 재생을 시작한다.
                [self addObserver:self forKeyPath:GTKeyPathStatus options:0 context:nil];
            }
        }
    }
}

- (void)pause
{
    if (_status != GTADPlayerStatusReadyToPlay)
        return;
    
    if (_playbackState == GTADPlayerPlaybackStatePlaying)
    {
        [_corePlayer pause];
        [self stopTicking];
        
        if (_playbackState != GTADPlayerPlaybackStatePaused)
        {
            NSLog(@"At here, _playbackState should have already paused.");
            self.playbackState = GTADPlayerPlaybackStatePaused;
        }
    }
}

- (void)stopByUser
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerStopByUserNotification
                                                        object:self
                                                      userInfo:nil];
    
    [self stop];
}

- (void)stop
{
    self.error = nil;
    
    if (_status != GTADPlayerStatusReadyToPlay)
    {
        BOOL preparingToPlay = _preparingToPlay;
        _preparingToPlay = NO;
        _forceStop = YES;
        
        if (preparingToPlay) {
            // status의 옵저버들을 위해 현재 값에 상관없이 무조건 설정한다.
            self.status = GTADPlayerStatusUnknown;
        } else {
            if (_status != GTADPlayerStatusUnknown)
                self.status = GTADPlayerStatusUnknown;
        }
        
        return;
    }
    
    if (_playbackState != GTADPlayerPlaybackStatePaused)
        self.playbackState = GTADPlayerPlaybackStatePaused;
    
    if (_corePlayer.currentItem)
    {
        [_corePlayer replaceCurrentItemWithPlayerItem:nil];
    }
    
    if (_playbackState != GTADPlayerPlaybackStatePaused)
    {
        NSLog(@"_playbackState should have already stopped.");
        self.playbackState = GTADPlayerPlaybackStatePaused;
    }
    
    [self invalidateTicking];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [notificationCenter removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    
    [_corePlayer removeObserver:self forKeyPath:GTKeyPathPlayerItemStatus context:nil];
    [_corePlayer removeObserver:self forKeyPath:GTKeyPathPlayerRate context:nil];
}

- (void)prepareToPlay
{
    if (_preparingToPlay || _contentURL == nil || _status != GTADPlayerStatusUnknown)
        return;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerPrepareToPlayNotification object:self];
    
    _preparingToPlay = YES;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_contentURL options:nil];
    NSArray *requiredKeys = [NSArray arrayWithObjects:GTKeyPathTracks, GTKeyPathPlayable, nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset
                                    automaticallyLoadedAssetKeys:requiredKeys];
    [self GT_prepareToPlayPlayerItem:playerItem];
//    [asset loadValuesAsynchronouslyForKeys:requiredKeys completionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (_preparingToPlay && [asset.URL isEqual:self.contentURL]) {
//                [self GT_prepareToPlayAsset:asset withKeys:requiredKeys];
//                // 이 시점에서 _status는 아직 unknown이고 다음 런루프에서 readyToPlay로 변경되므로
//                // _preparingToPlay는 그 다음 런루프에서 변경한다.
//                dispatch_async(dispatch_get_main_queue(), ^{ _preparingToPlay = NO; });
//            }
//        });
//    }];
}

- (void)GT_prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requiredKeys
{
    for (NSString *key in requiredKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            BOOL reallyFailed = [self.contentURL isFileURL];
            if (reallyFailed == NO) {
                NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
                if ([systemVersion compare:@"4.3" options:NSNumericSearch] != NSOrderedAscending)
                    reallyFailed = YES;
            }
            if (reallyFailed == NO) {
                [self GT_prepareToPlayPlayerItem:[AVPlayerItem playerItemWithURL:self.contentURL]];
            } else {
                self.error = error;
                self.status = GTADPlayerStatusFailed;
                [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerDidFailToPlayNotification object:self];
            }
            return;
        }
    }
    
    [self GT_prepareToPlayPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
}

- (void)GT_prepareToPlayPlayerItem:(AVPlayerItem *)playerItem
{
    [_corePlayer replaceCurrentItemWithPlayerItem:playerItem];
}
- (void)seekToTime:(CMTime)time
{
    [_corePlayer seekToTime:time toleranceBefore:kCMTimePositiveInfinity toleranceAfter:kCMTimePositiveInfinity];
}



#pragma mark -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:GTKeyPathPlayerItemStatus])
    {
        AVPlayerItem *playerItem = [object currentItem];
        [self GT_playerItem:playerItem didChangeStatus:change];
    }
    else if ([keyPath isEqualToString:GTKeyPathPlayerRate])
    {
        AVPlayer *player = (AVPlayer *)object;
        [self GT_playerItem:player didChangeRate:change];
    }
    else if ([keyPath isEqualToString:GTKeyPathStatus])
    {
        [self removeObserver:self forKeyPath:GTKeyPathStatus];
        NSURL *contentURL = self.contentURL;
        
        UIApplication *application = [UIApplication sharedApplication];
        UIApplicationState appState = application.applicationState;
        if (appState == UIApplicationStateActive &&
            contentURL == self.contentURL &&
            self.status == GTADPlayerStatusReadyToPlay)
        {
            
            [self play];
        }
        
    }
    else
    {
        NSLog(@"else key path: %@", keyPath);
    }
}

- (void)GT_playerItem:(AVPlayerItem *)playerItem didChangeStatus:(NSDictionary *)change
{
    self.error = playerItem.error;
    
    GTADPlayerStatus status = GTADPlayerStatusUnknown;
    if (playerItem) {
        switch (playerItem.status) {
            case AVPlayerItemStatusUnknown:
                status = GTADPlayerStatusUnknown;
                break;
            case AVPlayerItemStatusReadyToPlay:
                //[self GT_updateForStatusReadyToPlay];
                
                
                /////
                
                status = GTADPlayerStatusReadyToPlay;
                break;
            case AVPlayerItemStatusFailed:
                status = GTADPlayerStatusFailed;
                break;
            default:
                break;
        }
    }
    
    if (_status != status)
        self.status = status;
}

- (void)GT_playerItem:(AVPlayer *)player didChangeRate:(NSDictionary *)change
{
    if (_status != GTADPlayerStatusReadyToPlay)
        return;
    
    if (player.rate == 0) {
        if (_playbackState == GTADPlayerPlaybackStatePlaying)
            self.playbackState = GTADPlayerPlaybackStatePaused;
    } else {
        if (_playbackState != GTADPlayerPlaybackStatePlaying)
            self.playbackState = GTADPlayerPlaybackStatePlaying;
    }
}

- (void)GT_playerItemDidPlayToEndTime:(NSNotification *)notification
{
    if (notification.object == _corePlayer.currentItem)
    {
        void (^block)(void) = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerDidPlayToEndTimeNotification
                                                                object:self
                                                              userInfo:nil];
        };
        
        if ([NSThread isMainThread])
            block();
        else
            dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)GT_handleRouteChange:(NSNotification *)notification
{
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self play];
        });
    }
}

- (void)GT_playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    NSLog(@"%@", notification);
}

- (void)GT_updateForStatusReadyToPlay
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GTMovieDurationAvailableNotification"
                                                        object:self
                                                      userInfo:nil];
}


#pragma mark - Timeline Timer

- (void)startTicking
{
    CGFloat interval = 0.5;
    
    if (_timelineTimer == nil) {
        SEL sel = @selector(GT_timelineTimerDidFire:);
        self.timelineTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                              target:self
                                                            selector:sel
                                                            userInfo:nil
                                                             repeats:YES];
    }
    
    [_timelineTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    
    [self GT_timelineTimerDidFire:_timelineTimer];
}

- (void)stopTicking
{
    [_timelineTimer setFireDate:[NSDate distantFuture]];
}

- (void)invalidateTicking
{
    [_timelineTimer invalidate];
    self.timelineTimer = nil;
}

- (void)GT_timelineTimerDidFire:(NSTimer *)timer
{
    if (self.corePlayer == nil)
        return;
    
    // post notification
    void (^block)(void) = ^{
        if (self.currentTime == 0 && self.isSendStartCall == NO) {
            self.isSendStartCall = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerDidPlayBackChangeNotification
                                                                object:self
                                                              userInfo:nil];
        }
        if (self.currentTime > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GTADPlayerDidPlayBackChangeNotification
                                                                object:self
                                                              userInfo:nil];
        }
        
    };
    
    if ([NSThread isMainThread])
        block();
    else
        dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark -
- (CGFloat)duration
{
    if (self.corePlayer == nil)
        return 0.0;
    
    CGFloat duration    = CMTimeGetSeconds(self.corePlayer.currentItem.asset.duration);
    
    return duration;
}

- (CGFloat)currentTime
{
    if (self.corePlayer == nil)
        return 0.0;
    
    CGFloat currentTime = CMTimeGetSeconds(self.corePlayer.currentTime);
    
    return currentTime;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    if (self.corePlayer != nil)
    {
        [self.corePlayer seekToTime:CMTimeMakeWithSeconds(currentPlaybackTime, NSEC_PER_SEC)];
    }
    
}
@end

