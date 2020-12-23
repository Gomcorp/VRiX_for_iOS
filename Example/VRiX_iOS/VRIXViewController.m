//
//  VRIXViewController.m
//  VRiX_iOS
//
//  Created by gombridge@gmail.com on 12/23/2020.
//  Copyright (c) 2020 gombridge@gmail.com. All rights reserved.
//

#import "VRIXViewController.h"
#import <VRiX_iOS/VRiXManager.h>
#import <VRiX_iOS/VRiX.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GXVideoPlayerView.h"

#define MAIN_CONTENTS_URL   @"https://videok.ait.cool/video/hd/000/029/530.mp4"
#define VRIX_URL            @"https://devads.vrixon.com/vast/vast.vrix?invenid=KHLOC"
#define VRIX_KEY            @"574643454"
#define VRIX_HASHKEY        @"577c3adb3b614c54"

@interface VRIXViewController ()

@property (nonatomic, strong) VRiXManager *vrixMananger;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic) BOOL isFetchedData;
@property (nonatomic, strong) NSTimer *             timelineTimer;

@end

@implementation VRIXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    self.vrixMananger = [[VRiXManager alloc] initWithKey:VRIX_KEY hashKey:VRIX_HASHKEY];
    
    self.isFetchedData = NO;
    
    [_progressView setProgress:0];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self playButtonTouched:nil];
    });
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.vrixMananger != nil)
    {
        [self.vrixMananger stopCurrentAD];
    }
    
    [self unregistAdNotification];
    [self.player pause];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self navigationController] setNavigationBarHidden:NO animated:NO];
        });
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - control vrix
- (void) playPreroll
{
    NSInteger numberOfPreroll = [_vrixMananger prerollCount];
    
    if (numberOfPreroll > 0)
    {
        [_adView setHidden:NO];
        [_controlView setHidden:YES];
        
        [_vrixMananger prerollAtView:_adView completionWithResult:^(NSString* adNames, NSInteger count, NSArray<NSDictionary *>* userInfos) {
            //
            NSLog(@"%@", adNames);
            
            [self playMainContent];
            [self.playButton setSelected:YES];
        }];
    
    }
    else
    {
        [self playMainContent];
    }
}

- (void) playMidroll
{
    CGFloat currentTime = CMTimeGetSeconds(_player.currentTime);
    
    //vrix midroll handling
    if([_vrixMananger midrollCount] > 0)
    {
       
        
        [_vrixMananger midrollAtView:_adView
                          timeOffset:currentTime
                     progressHandler:^(BOOL start, GXAdBreakType breakType, NSAttributedString *message)
         {
             //
             if (message != nil && breakType == GXAdBreakTypelinear)
             {
                 [self.messageLabel setAttributedText:message];
             }
             
             if (start == YES)
             {
                 if (breakType == GXAdBreakTypelinear)
                 {
                     [self playButtonTouched:nil];
                 }
                 
                 [self.adView setHidden:NO];
                 [self.controlView setHidden:YES];
             }
             else
             {
                 
             }
         }
                   completionHandler:^(GXAdBreakType breakType)
         {
             //
             if (breakType == GXAdBreakTypelinear)
             {
                 [self playButtonTouched:nil];
             }
             
             [self.adView setHidden:YES];
             [self.controlView setHidden:NO];
             
         }];
    }
}

- (void) playpostroll
{
    NSInteger numberOfPostroll = [_vrixMananger postrollCount];
    if (numberOfPostroll > 0)
    {
        [_adView setHidden:NO];
        [_controlView setHidden:YES];
        
        [_vrixMananger postrollAtView:_adView completionHandler:^(BOOL success, id userInfo) {
            //
            self.vrixMananger = nil;
            self.isFetchedData = NO;
            
            [self playButtonTouched:nil];
        }];
        
    }
    else
    {
        [self playButtonTouched:nil];
    }
}

- (void) playMainContent
{
    [_adView setHidden:YES];
    
    NSURL *videoURL = [NSURL URLWithString:MAIN_CONTENTS_URL];
    self.player = [AVPlayer playerWithURL:videoURL];
    [self.mainVideoView setPlayer:self.player];
    [_player play];
    [_controlView setHidden:NO];
    [_playButton setSelected:YES];
    
    [self startTicking];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(playerItemDidPlayToEndTime:)
                               name:AVPlayerItemDidPlayToEndTimeNotification
                             object:nil];
    
}

- (void) errorHandler:(NSError *)error
{
    
}



#pragma mark - button handler
- (IBAction)rewindButtonTouched:(id)sender
{
    CGFloat currentTime = CMTimeGetSeconds(_player.currentTime);
    CGFloat changeTime = 0;
    
    if (currentTime <= 30)
    {
        [_player seekToTime:CMTimeMakeWithSeconds(changeTime, NSEC_PER_SEC)];
    }
    else
    {
        changeTime = currentTime - 30;
        [_player seekToTime:CMTimeMakeWithSeconds(changeTime, NSEC_PER_SEC)];
    }
    
}

- (IBAction)fastfowardButtonTouched:(id)sender
{
    CGFloat duration    = CMTimeGetSeconds(_player.currentItem.asset.duration);
    CGFloat currentTime = CMTimeGetSeconds(_player.currentTime);
    CGFloat changeTime = 0;
    
    if (duration <= currentTime + 30)
    {
        changeTime = duration - 5;
        [_player seekToTime:CMTimeMakeWithSeconds(changeTime, NSEC_PER_SEC)];
        
    }
    else
    {
        changeTime = currentTime + 30;
        [_player seekToTime:CMTimeMakeWithSeconds(changeTime, NSEC_PER_SEC)];
    }
}

- (IBAction)playButtonTouched:(id)sender
{
    
    if (_vrixMananger && _isFetchedData == NO)
    {
        [self registAdNotification];
        
        NSString* encodedUrl = [VRIX_URL stringByReplacingOccurrencesOfString:@"|" withString:[@"|" stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
        [_vrixMananger fetchVRiX:[NSURL URLWithString:encodedUrl]
               completionHandler:^(BOOL success, NSError *error)
         {
             //
             self.isFetchedData = YES;
             if (success == YES)
             {
                 [self playPreroll];
             }else
             {
                 [self errorHandler:error];
             }
         }];
    }
    else
    {
        if (_playButton.selected == YES)
        {
            [_player pause];
            [_playButton setSelected:NO];
        }
        else
        {
            [_player play];
            [_playButton setSelected:YES];
        }
    }
}


#pragma mark - player notification
- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
    if (notification.object == _player.currentItem)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:nil];
        
        [self playpostroll];
    }
    
}


#pragma mark - Timeline Timer

- (void)startTicking
{
    if (_timelineTimer == nil) {
        SEL sel = @selector(GT_timelineTimerDidFire:);
        self.timelineTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                              target:self
                                                            selector:sel
                                                            userInfo:nil
                                                             repeats:YES];
    }
    
    [_timelineTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    [self GT_timelineTimerDidFire:_timelineTimer];
}

- (void)stopTicking
{
    [_timelineTimer setFireDate:[NSDate distantFuture]];
}

- (void)invalidateTicking
{
    if([_timelineTimer isValid])
    {
        [_timelineTimer invalidate];
    }
    self.timelineTimer = nil;
}

- (void)GT_timelineTimerDidFire:(NSTimer *)timer
{
    if (self.player == nil)
        return;
    
    // post notification
    void (^block)(void) = ^{
        // progress bar change
        CGFloat duration    = CMTimeGetSeconds(self.player.currentItem.asset.duration);
        CGFloat currentTime = CMTimeGetSeconds(self.player.currentTime);
        [self.progressView setProgress:currentTime/duration];
        
        //vrix midroll handling
        if([self.vrixMananger midrollCount] > 0)
        {
            [self playMidroll];
        }
    };
    
    if ([NSThread isMainThread])
        block();
    else
        dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark - notification
- (void) registAdNotification
{
    [self unregistAdNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdPreparePlay:)
                                                 name:GTADPlayerPrepareToPlayNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdReadyToPlay:)
                                                 name:GTADPlayerReadyToPlayNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdPlayBackDidChange:)
                                                 name:GTADPlayerDidPlayBackChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdPlayToEnd:)
                                                 name:GTADPlayerDidPlayToEndTimeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdStop:)
                                                 name:GTADPlayerStopByUserNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdFailToPlay:)
                                                 name:GTADPlayerDidFailToPlayNotification
                                               object:nil];
}

- (void) unregistAdNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerPrepareToPlayNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerReadyToPlayNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerDidPlayBackChangeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerDidPlayToEndTimeNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerStopByUserNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerDidFailToPlayNotification
                                                  object:nil];
}

- (void) AdPreparePlay:(id)sender
{
    NSLog(@"AdPreparePlay");
}

- (void) AdReadyToPlay:(id)sender
{
    NSLog(@"Ready to Play AD");
}

- (void) AdPlayBackDidChange:(id)sender
{
    NSLog(@"AD is Playing (Duration: %0.3f, playtime: %0.3f)", [self.vrixMananger getCurrentAdDuration], [self.vrixMananger getCurrentAdPlaytime]);
}

- (void) AdStop:(id)sender
{
    NSLog(@"Maybe skipped by User...");
}

- (void) AdPlayToEnd:(id)sender
{
    NSLog(@"AD Completed");
}

- (void) AdFailToPlay:(id)sender
{
    NSLog(@"AD load fail");
}
@end
