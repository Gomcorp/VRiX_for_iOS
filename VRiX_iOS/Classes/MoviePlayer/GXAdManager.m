//
//  GXAdManager.m
//  GoxParser
//
//  Created by Youngchang koo on 2016. 5. 18..
//  Copyright © 2016년 Youngchang koo. All rights reserved.
//

#import "GXAdManager.h"
#import <AVKit/AVKit.h>
#import "GTVAST.h"
#import "Statistics.h"
#import "GXADPlayer.h"
#import "GTGoxImporterUtil.h"
#import "GXPlayerView.h"
#import "UIColor+HexColors.h"

#define GXKeyPathPlayerItemStatus       @"currentItem.status"
#define GXKeyPathPlayerRate             @"rate"
#define IS_IPHONE_X (MAX(CGRectGetWidth([[UIScreen mainScreen] bounds]), CGRectGetHeight([[UIScreen mainScreen] bounds])) == 812)

@interface GXAdManager()
@property (nonatomic, strong) GTCreativeElement *currentCreative;
@property (nonatomic, strong) GTMediaFile       *currentMedia;
@property (nonatomic) BOOL                      preparingToPlay;

@property (nonatomic) NSInteger progressRatio;
@property (nonatomic, strong) UIView        *targetView;
@property (nonatomic, strong) GXPlayerView  *playerView;
@property (nonatomic, strong) UIView        *overlayView;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) NSMutableArray *extensions;
@property (nonatomic, copy)   NSURL *contentURL;

@property (nonatomic) BOOL                      didFinishedPlaybackBySkip;
@end

@implementation GXAdIconButton
+ (id)buttonWithIconObject:(GTIcon *)icon
{
    GXAdIconButton* button = [GXAdIconButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectZero];
    [button setBackgroundColor:[UIColor clearColor]];
    
    [button setAlpha:0.0f];
    [button setHidden:YES];
    
    if (icon.iconClickThrough == nil && icon.iconClickTracking == nil)
    {
        [button setUserInteractionEnabled:NO];
    }
    else
    {
        [button setUserInteractionEnabled:YES];
    }
    
    [button setIcon:icon];
    
    if (icon.staticResourceAsset)
    {
        
        [button setImage:icon.staticResourceAsset
                forState:UIControlStateNormal];
        
        CGRect frame = [button frame];
        frame.size = [icon.staticResourceAsset size];
        frame.size.width = floorf(frame.size.width / 2.0f);
        frame.size.height = floorf(frame.size.height / 2.0f);
        [button setFrame:frame];
    }
    else
    {
        NSURL *url = [NSURL URLWithString:icon.staticResource];
        if(url != nil)
        {
            dispatch_queue_t queue = dispatch_queue_create("com.gretech.gom.imageDownload", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                NSData *data = [NSData dataWithContentsOfURL:url];
                
                UIImage *image = [UIImage imageWithData:data];
                
                if (image)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [button setImage:image
                                forState:UIControlStateNormal];
                    });
                    
                }
            });
        }
    }
    
    
    
    return button;
}

- (void)layoutFromSuperView
{
    UIView* superview = [self superview];
    if(superview != nil)
    {
        CGPoint center = [self center];
        CGPoint superCenter = [superview center];
        CGRect bounds = [superview bounds];
        
        center.x = roundf(bounds.origin.x + (bounds.size.width * (_relativePosition.x / 100.0f)));
        center.y = roundf(bounds.origin.y + (bounds.size.height * (_relativePosition.y / 100.0f)));
        
        [self setCenter:center];
        
        CGRect frame = [self frame];
        
        CGFloat minXBounds = CGRectGetMinX(bounds);
        CGFloat minYBounds = CGRectGetMinY(bounds);
        CGFloat minXFrame = CGRectGetMinX(frame);
        CGFloat minYFrame = CGRectGetMinY(frame);
        
        minXFrame = minXFrame < minXBounds ? minXBounds : minXFrame;
        minYFrame = minYFrame < minYBounds ? minYBounds : minYFrame;
        
        frame.origin.x = minXFrame;
        frame.origin.y = minYFrame;
        
        CGFloat maxXBounds = CGRectGetMaxX(bounds);
        CGFloat maxYBounds = CGRectGetMaxY(bounds);
        CGFloat maxXFrame = CGRectGetMaxX(frame);
        CGFloat maxYFrame = CGRectGetMaxY(frame);
        
        maxXFrame = maxXFrame > maxXBounds ? maxXBounds : maxXFrame;
        maxYFrame = maxYFrame > maxYBounds ? maxYBounds : maxYFrame;
        
        frame.origin.x = maxXFrame - frame.size.width;
        frame.origin.y = maxYFrame - frame.size.height;
        
        [self setFrame:frame];
        
        center = [self center];
        
        CGFloat xMargin = bounds.size.width * (_margin / 100.0f);
        CGFloat yMargin = bounds.size.height * (_margin / 100.0f);
        
        xMargin = xMargin * (center.x < superCenter.x ? 1.0f : -1.0f);
        yMargin = yMargin * (center.y < superCenter.y ? 1.0f : -1.0f);
        
        center.x += xMargin;
        center.y += yMargin;
        
        [self setCenter:center];
    }
}

- (void) setupAutoResizeMask
{
//    UIView* superview = [self superview];
//    CGRect screenRect = [superview bounds];
//    CGFloat screenWidth = screenRect.size.width;
//    CGFloat screenHeight = screenRect.size.height;
//
//    CGFloat buttonX = self.center.x;
//    CGFloat buttonY = self.center.y;
//
//    UIViewAutoresizing mask = UIViewAutoresizingNone;
//    if (screenWidth/2 > buttonX)
//    {
//        mask |= UIViewAutoresizingFlexibleRightMargin;
//
//    }
//    else if (screenWidth/2 < buttonX)
//    {
//        mask |= UIViewAutoresizingFlexibleLeftMargin;
//    }
//    else
//    {
//        mask |= UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//    }
//
//
//    if ( screenHeight/2 > buttonY)
//    {
//        mask |= UIViewAutoresizingFlexibleBottomMargin;
//
//    }
//    else if (screenHeight/2 < buttonY)
//    {
//        mask |= UIViewAutoresizingFlexibleTopMargin;
//    }
//    else
//    {
//        mask |= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//    }
//
//    [self setAutoresizingMask:mask];
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if([self isHidden] != hidden)
    {
        CGFloat alpha = hidden == YES ? 0.0f : 1.0f;
        
        if(animated == YES)
        {
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 //
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setAlpha:alpha];
                                 });
                             }
                             completion:^(BOOL finished) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setHidden:hidden];
                                 });
                             }];
            
        }
        else
        {
            if ([NSThread isMainThread] == YES)
            {
                [self setAlpha:alpha];
                [self setHidden:hidden];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setAlpha:alpha];
                    [self setHidden:hidden];
                });
            }
            
        }
    }
}
@end

@implementation GXAdIconWebView

+ (id)buttonWithIconObject:(GTIcon *)icon
{
    CGRect frame = CGRectMake([icon.xPosition floatValue], [icon.yPosition floatValue], icon.width, icon.height);
    GXAdIconWebView* webView = [[GXAdIconWebView alloc] initWithFrame:frame];
    [webView setBackgroundColor:[UIColor clearColor]];
    
    [webView setAlpha:0.0f];
    [webView setHidden:YES];
    
    [webView setIcon:icon];
    [webView setOpaque:NO];
    [webView loadHTMLString:icon.htmlResource baseURL:nil];
    
    return webView;
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if([self isHidden] != hidden)
    {
        CGFloat alpha = hidden == YES ? 0.0f : 1.0f;
        
        if(animated == YES)
        {
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 //
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setAlpha:alpha];
                                 });
                             }
                             completion:^(BOOL finished) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setHidden:hidden];
                                 });
                             }];
            
        }
        else
        {
            if ([NSThread isMainThread] == YES)
            {
                [self setAlpha:alpha];
                [self setHidden:hidden];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setAlpha:alpha];
                    [self setHidden:hidden];
                });
            }
            
        }
    }
}

@end

@implementation GXAdLabel

+ (id) labelWithIconObject:(GTLabel *)label
{
    GXAdLabel *adLabel = [[GXAdLabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [adLabel setLabelObject:label];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(label.shadowpathX, label.shadowpathY);
    shadow.shadowColor = label.shadowcolor;
    [adLabel setFormatString:label.format];
    [adLabel setActionString:label.action];
    
    adLabel.attiributedData = @{NSForegroundColorAttributeName : label.fontcolor, NSShadowAttributeName:shadow, NSFontAttributeName:[UIFont systemFontOfSize:label.size]};
    if(![adLabel.actionString isEqualToString:@"counterdown"])
    {
        [adLabel setText:label.value];
    }
    else
    {
        [adLabel setHidden:YES];
    }
    
    
    
    return adLabel;
}

- (void) setText:(NSString *)text
{
    self.attributedText = [[NSAttributedString alloc] initWithString:text attributes:self.attiributedData];;
    [self sizeToFit];
    [self setHidden:NO];
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if([self isHidden] != hidden)
    {
        CGFloat alpha = hidden == YES ? 0.0f : 1.0f;
        
        if(animated == YES)
        {
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 //
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setAlpha:alpha];
                                 });
                             }
                             completion:^(BOOL finished) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self setHidden:hidden];
                                 });
                             }];
            
        }
        else
        {
            if ([NSThread isMainThread] == YES)
            {
                [self setAlpha:alpha];
                [self setHidden:hidden];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setAlpha:alpha];
                    [self setHidden:hidden];
                });
            }
            
        }
    }
}
@end

@interface GXAdManager()

@property (nonatomic, assign) BOOL didSelectMoreButton;
@end
@implementation GXAdManager

- (void) playCreativeElement:(GTCreativeElement*)elementObject atTargetView:(UIView *)targetView completion:(void (^)(BOOL, id))completion
{
    self.currentCreative = elementObject;
    _progressRatio = 1;
    self.targetView = targetView;
    
    CGRect frame = CGRectMake(0, 0, targetView.frame.size.width, targetView.frame.size.height);
    self.overlayView= [[UIView alloc] initWithFrame:frame];
    [_overlayView setBackgroundColor:[UIColor clearColor]];
    
    self.playerView = [[GXPlayerView alloc] initWithFrame:frame];
    [_playerView setBackgroundColor:[UIColor clearColor]];
    
    [targetView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]];
    
    [targetView addSubview:_playerView];
    [targetView addSubview:_overlayView];
    
    // button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor redColor]];
    [button addTarget:self action:@selector(creativeTriggerHandler:) forControlEvents:UIControlEventTouchUpInside];
    [_overlayView addSubview:button];
    
    [_playerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [_overlayView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    
    // setup for play
    if ([elementObject isKindOfClass:[GTLinear class]])
    {
        GTLinear *linear = (GTLinear *)elementObject;
        for (GTMediaFile *mediaFile in linear.mediaFiles)
        {
            self.currentMedia = mediaFile;
            NSURL *url = [NSURL URLWithString:mediaFile.referURL];
            
            [self playWithURL:url atTargetView:self.playerView completion:^(BOOL success, id userInfo)
            {
                //
                [self.playerView removeFromSuperview];
                self.playerView = nil;
                completion (success, userInfo);
            }];
            break;
        }
    }
    
}

- (void) creativeTriggerHandler:(id)sender
{
    //NSLog(@"%@", self.currentCreative);
}

- (void) playWithURL:(NSURL*)URL atTargetView:(UIView *)targetView completion:(void (^)(BOOL, id))completion;
{
    self.player = nil;
    
    self.completion = completion;
    self.buttons = [[NSMutableArray alloc] init];
    self.extensions = [[NSMutableArray alloc] init];
    self.didSelectMoreButton = NO;
    
    //NSURL *testURL = [NSURL URLWithString:@"http://api.wecandeo.com/video?k=BOKNS9AQWrGMMsx09mbUgpPRM7QipjXsWTuisq4erJ6hIx1VHlRhSuWwieie"];
    GXADPlayer *avPlayer = [[GXADPlayer alloc] initWithContentURL:URL];
    [self setPlayer:avPlayer];
    
    [self.playerView setPlayer:avPlayer.corePlayer];
    
    [self GX_registerForMoviePlayerNotifications];
    [self GX_registerApplicationNotification];
    
    if ([_currentCreative isKindOfClass:[GTLinear class]])
    {
        GTLinear *linear = (GTLinear *)_currentCreative;
    
        for (GTIcon* icon in linear.Icons)
        {
            if (icon.htmlResource)
            {
                GXAdIconWebView *webView = [GXAdIconWebView buttonWithIconObject:icon];
                
                [_overlayView addSubview:webView];
                
                [self.buttons addObject:webView];
            }
            else
            {
                GXAdIconButton *button = [GXAdIconButton buttonWithIconObject:icon];
                
                [_overlayView addSubview:button];
                
                [self.buttons addObject:button];
            }
        }
        
        for (GTExtension *extension in _currentCreative.extensions)
        {
            if ([extension.type isEqualToString:@"vrix"])
            {
                [self vrixExtensionHandler:extension atTargetView:targetView];
            }
        }
    }
    
    [self performSelector:@selector(playAd) withObject:nil afterDelay:0.2];
   
}

- (void) vrixExtensionHandler:(GTExtension *)extension atTargetView:(UIView *)targetView
{
    if ([extension.extensionObject isKindOfClass:[GTVRiXExtensionObject class]] && [extension.extensionObject isKindOfClass:[GTLabel class]])
    {
        GTLabel *label = (GTLabel *)extension.extensionObject;
        GXAdLabel *adLabel = [GXAdLabel labelWithIconObject:label];
        
        [targetView addSubview:adLabel];
        
        [self.extensions addObject:adLabel];
    }
}

- (void) playAd
{
    if (self.player != nil)
    {
        _didFinishedPlaybackBySkip = NO;
        if([NSThread isMainThread] == YES)
        {
            [self.player play];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.player play];
            });
        }
        
    }
}

- (void) reloadView
{
    [_playerView needsUpdateConstraints];
    [_targetView needsUpdateConstraints];
    [_avPlayerLayer setNeedsDisplay];
}

- (void) stopPlayByUser
{
    [self.player stopByUser];
    
    [self deallocPlayer];
}

- (void) stopPlay
{
    [self.player stop];
    
    [self deallocPlayer];
}

- (void) pause
{
    [self.player pause];
}

- (void) resume
{
    [self.player play];
}

- (void) deallocPlayer
{
    [self GX_unregisterForMoviePlayerNotifications];
    [self GX_unregisterApplicationNotification];
    [self.avPlayerLayer removeFromSuperlayer];
    
    if( _playerView != nil)
        [_playerView removeFromSuperview];
    
    if (_overlayView != nil)
        [_overlayView removeFromSuperview];
    
    self.targetView     = nil;
    self.playerView     = nil;
    self.overlayView    = nil;
    
//    self.player = nil;
    if (self.player != nil)
    {
        [self.player pause];
    }
    
    for (UIButton *button in _buttons)
    {
        [button removeFromSuperview];
    }
    
    for (GXAdLabel *label in _extensions)
    {
        [label removeFromSuperview];
    }
    
    [_buttons removeAllObjects];
    [_extensions removeAllObjects];
}

- (CGFloat)currentAdDuration
{
    if (self.isPlaying == YES) {
        return self.player.duration;
    }
    
    return 0;
}

- (CGFloat)currentAdPlayTime
{
    if (self.isPlaying == YES) {
        return self.player.currentTime;
    }
    
    return 0;
}


+ (GXAdManager *)sharedManager
{
    static GXAdManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

#pragma mark - notification

- (void)GX_registerForMoviePlayerNotifications
{
    [self GX_unregisterForMoviePlayerNotifications];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(GT_moviePlayerPlaybackDidFinish:)
                               name:GTADPlayerDidPlayToEndTimeNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(GT_moviePlayerReadyToPlay:)
                               name:GTADPlayerReadyToPlayNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(GT_moviePlayerPlaybackDidChange:)
                               name:GTADPlayerDidPlayBackChangeNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(GT_moviePlayerDidFailToPlay:)
                               name:GTADPlayerDidFailToPlayNotification
                             object:nil];
    
}

- (void)GX_unregisterForMoviePlayerNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self
                                  name:GTADPlayerDidPlayToEndTimeNotification
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:GTADPlayerReadyToPlayNotification
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:GTADPlayerDidPlayBackChangeNotification
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:GTADPlayerDidFailToPlayNotification
                                object:nil];
}

- (void)GX_registerApplicationNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(GX_applicationDidBecomeActiveNotificaion:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
    
}

- (void)GX_unregisterApplicationNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:[UIApplication sharedApplication]];
    
    
}


#pragma mark - notification handler
- (void)GX_applicationDidBecomeActiveNotificaion:(NSNotification *)notifcation
{
    if(_mPlayer != nil)
    {
        if(_mPlayer.status == AVPlayerStatusReadyToPlay)
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect frame = self.targetView.frame;
                frame.origin.x = 0;
                frame.origin.y = 0;
                
                [self.overlayView setFrame:frame];
                [self.playerView setFrame:frame];
                [self.avPlayerLayer setFrame:frame];
                [self reloadView];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self.player play];
                });
            });
            
            
        }
    }
}

- (void) GT_moviePlayerPlaybackDidFinish:(NSNotification *)notifcation
{
    [self stopPlay];
    
    if ([_currentCreative isKindOfClass:[GTLinear class]])
    {
        // skip을 진행했을 경우 complete를 보내지 않는다
        if (_didFinishedPlaybackBySkip == NO)
        {
            NSArray *progressTrackings = [self GX_findTrackingEventProgress];
            for (GTTracking *progressTracking in progressTrackings)
            {
                [_currentCreative sendTracking:progressTracking];
            }
            
            NSMutableArray<GTTracking *>* trackings = [_currentCreative findTracksEventName:GXTrainkinEventTypeComplete];
            [_currentCreative sendTrackings:trackings];
        }
    }
    _didFinishedPlaybackBySkip = NO;
    
    NSDictionary *userInfo = @{VIDEO_AD_COMPLETION_REASON_KEY:VIDEO_AD_COMPLETION_REASON_COMPLETE, VIDEO_AD_COMPLETION_OBJECT_KEY:notifcation};
    self.completion(YES, userInfo);
}

- (void) GT_moviePlayerReadyToPlay:(NSNotification *)notification
{
    for (GXAdIconButton *button in self.buttons)
    {
        //NSLog(@"%f x %f", button.icon.offset, button.icon.duration);
        [self GX_setButtonLayout:button];
        
        if ([button isKindOfClass:[GXAdIconButton class]])
        {
            [button addTarget:self
                       action:@selector(GX_buttonHanlder:)
             forControlEvents:UIControlEventTouchUpInside];
            
            [button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            button.imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            
            [button setupAutoResizeMask];
        }
        else if ([button isKindOfClass:[GXAdIconWebView class]])
        {
            GXAdIconWebView *webView = (GXAdIconWebView *)button;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(GX_buttonHanlder:)];
            [webView addGestureRecognizer:tapGestureRecognizer];
        }
        
        if (button.icon.offset == 0) {
            [button setHidden:NO animated:NO];
        }
        
        
    }
    
    for (GXAdLabel *label in self.extensions)
    {
        [self GX_setLabelLayout:label];
    }
}

- (void)GT_moviePlayerDidFailToPlay:(NSNotification *)notification
{
    if (self.completion) {
        
        [self stopPlay];
        
        NSDictionary *userInfo = @{VIDEO_AD_COMPLETION_REASON_KEY:VIDEO_AD_COMPLETION_REASON_ERROR};
        self.completion(NO, userInfo);
    }
    
}
- (void)GT_moviePlayerPlaybackDidChange:(NSNotification *)notification
{
    CGFloat duration = [self.player duration];
    CGFloat current  = [self.player currentTime];
    //NSLog(@"%@ duration: %0.1f -> current: %0.1f", notification, duration, current);
    
    //
    if (current >= 0 )
    {
        GTLinear *linear = (GTLinear *)self->_currentCreative;
        
        if(linear.ad != nil) {

            [self sendImpressionUrls:linear.ad];
            [linear setAd:nil];
        }
        
        NSMutableArray<GTTracking *>* trackings = [_currentCreative findTracksEventName:GXTrainkinEventTypeStart];
        [_currentCreative sendTrackings:trackings];
    }
    
    if ([_currentCreative isKindOfClass:[GTLinear class]])
    {
        // tracking..
        CGFloat quart = duration/4;
        
        if (quart * _progressRatio < current)
        {
            NSMutableArray<GTTracking *>* trackings = nil;
            switch (_progressRatio)
            {
                case 1:
                    trackings = [_currentCreative findTracksEventName:GXTrainkinEventTypeFirstQuartile];
                    break;
                case 2:
                    trackings = [_currentCreative findTracksEventName:GXTrainkinEventTypeMidpoint];
                    break;
                case 3:
                    trackings = [_currentCreative findTracksEventName:GXTrainkinEventTypeThirdQuartile];
                    break;
                default:
                    break;
            }
            
            if (trackings != nil && [trackings count] > 0)
            {
                [_currentCreative sendTrackings:trackings];
            }
            
            _progressRatio++;
        }
        
        // progress tracking
        NSArray *progressTrackings = [self GX_findTrackingEventProgress];
        for (GTTracking *progressTracking in progressTrackings)
        {
            if (current >= progressTracking.offset)
            {
                [_currentCreative sendTracking:progressTracking];
            }
        }
        
        // icon show or hide
        for (GXAdIconButton *button in self.buttons)
        {
            NSTimeInterval offset = button.icon.offset;
            NSTimeInterval buttnDuration = button.icon.duration == 0 ? duration : button.icon.duration;
        
            // 항상보여준다.
            if (offset == 0 && button.icon.duration == 0)
            {
                [button setHidden:NO animated:NO];
            }
            // 보여줘야하는 시점이라면
            else if (offset < current  && offset + buttnDuration > current)
            {
                [button setHidden:NO animated:NO];
            }
            // 보여주는 시점이 지났다면 hidden
            else if (offset + buttnDuration < current)
            {
                [button setHidden:YES animated:NO];
            }
        }
        
        // extension
        for (GXAdLabel *label in self.extensions)
        {

            if ([label.labelObject.action isEqualToString:@"counterdown"])
            {
                NSTimeInterval interval = duration - current;
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:label.formatString];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                NSString *formattedDate = [dateFormatter stringFromDate:date];
                [label setText:formattedDate];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [label layoutIfNeeded];
                });
                
            }
        }
    }
}

- (void) GX_setLabelLayout:(GXAdLabel *)label
{
    CGFloat videoX = _playerView.playerLayer.videoRect.origin.x > 1 ? _playerView.playerLayer.videoRect.origin.x: 0;
    CGFloat videoY = _playerView.playerLayer.videoRect.origin.y > 1 ? _playerView.playerLayer.videoRect.origin.y: 0;
    
    if (IS_IPHONE_X == NO)
    {
        videoX = 0;
        videoY = 0;
    }
    
    CGRect frame = label.frame;
    
    CGFloat widthRatio = 0;
    CGFloat heightRatio = 0;
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat topMargin = 0;
    CGFloat bottomMargin = 0;

    UIViewAutoresizing resizingMask = UIViewAutoresizingNone;
    GTPositionFixedFlag *flag = nil;
    for (GTExtension *extension in _currentCreative.extensions)
    {
        if (extension.postionFixedFlag != nil)
        {
            flag = extension.postionFixedFlag;
        }
    }
    
    if (flag == nil || flag.useFlag == NO)
    {
        widthRatio = _targetView.frame.size.width / self.currentMedia.width;
        heightRatio = _targetView.frame.size.height / self.currentMedia.height;
        
        resizingMask = resizingMask | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    else
    {
        CGFloat scale = 2;//[UIScreen mainScreen].scale;
        widthRatio = 2 / scale;
        heightRatio = 2 / scale;
        
        leftMargin = label.labelObject.leftMargin;
        rightMargin = label.labelObject.rightMargin;
        topMargin = label.labelObject.topMargin;
        bottomMargin = label.labelObject.bottomMargin;
    }
    
    if ([label.labelObject.xPosition isEqualToString:@"left"])
    {
        frame.origin.x = videoX + leftMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleRightMargin;
    }
    else if ([label.labelObject.xPosition isEqualToString:@"right"])
    {
        frame.origin.x = _targetView.frame.size.width - videoX - rightMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleLeftMargin;
    }
    else
    {
        frame.origin.x = [label.labelObject.xPosition floatValue] * widthRatio;
        frame.origin.x += _targetView.frame.size.width / 2 > frame.origin.x ? videoX : -1 * videoX;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    }
    
    if ([label.labelObject.yPosition isEqualToString:@"bottom"])
    {
        CGRect targetFrame = _targetView.frame;
        frame.origin.y = targetFrame.size.height - videoY - bottomMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleTopMargin;
    }
    else if ([label.labelObject.yPosition isEqualToString:@"top"])
    {
        frame.origin.y = videoY + topMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleBottomMargin;
    }
    else
    {
        frame.origin.y = [label.labelObject.yPosition floatValue] * heightRatio + videoY;
        frame.origin.y += _targetView.frame.size.height / 2 > frame.origin.y ? -1 * videoY : videoY;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    
//    resizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
//    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [label setAutoresizingMask:resizingMask];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [label setFrame:frame];
    });
    
}

- (void) GX_setButtonLayout:(GXAdIconButton *)button
{
    CGFloat videoX = _playerView.playerLayer.videoRect.origin.x > 1 ? _playerView.playerLayer.videoRect.origin.x: 0;
    CGFloat videoY = _playerView.playerLayer.videoRect.origin.y > 1 ? _playerView.playerLayer.videoRect.origin.y: 0;
    
    if (IS_IPHONE_X == NO)
    {
        videoX = 0;
        videoY = 0;
    }
    
    GTPositionFixedFlag *flag = nil;
    for (GTExtension *extension in _currentCreative.extensions)
    {
        if (extension.postionFixedFlag != nil)
        {
            flag = extension.postionFixedFlag;
        }
    }
    
    CGRect frame = button.frame;
    CGFloat widthRatio = 0;
    CGFloat heightRatio = 0;
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat topMargin = 0;
    CGFloat bottomMargin = 0;
    
    UIViewAutoresizing resizingMask = UIViewAutoresizingNone;
    
    if (flag == nil || flag.useFlag == NO)
    {
        widthRatio = _targetView.frame.size.width / self.currentMedia.width;
        heightRatio = _targetView.frame.size.height / self.currentMedia.height;
        
        resizingMask = resizingMask | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    else
    {
        CGFloat scale = 2;//[UIScreen mainScreen].scale;
        widthRatio = 2 / scale;
        heightRatio = 2 / scale;
        
        leftMargin = flag.leftMargin;
        rightMargin = flag.rightMargin;
        topMargin = flag.topMargin;
        bottomMargin = flag.bottomMargin;
    }

    frame.size.width = button.icon.width * widthRatio;
    frame.size.height = button.icon.height * heightRatio;
    
    
    
    if ([button.icon.xPosition isEqualToString:@"left"])
    {
        frame.origin.x = videoX + leftMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleRightMargin;
    }
    else if ([button.icon.xPosition isEqualToString:@"right"])
    {
        frame.origin.x = _targetView.frame.size.width - frame.size.width - videoX - rightMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleLeftMargin;
    }
    else
    {
        frame.origin.x = [button.icon.xPosition floatValue] * widthRatio;
        frame.origin.x += _targetView.frame.size.width / 2 > frame.origin.x ? videoX : -1 * videoX;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    }
    
    if ([button.icon.yPosition isEqualToString:@"bottom"])
    {
        frame.origin.y = _targetView.frame.size.height - frame.size.height - videoY - bottomMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleTopMargin;
    }
    else if ([button.icon.yPosition isEqualToString:@"top"])
    {
        frame.origin.y = videoY + topMargin;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleBottomMargin;
    }
    else
    {
        frame.origin.y = [button.icon.yPosition floatValue] * heightRatio + videoY;
        frame.origin.y += _targetView.frame.size.height / 2 > frame.origin.y ? -1 * videoY : videoY;
        resizingMask = resizingMask | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    
    [button setAutoresizingMask:resizingMask];

    [button setFrame:frame];
}


- (void) GX_buttonHanlder:(id)sender
{
    
    GXAdIconButton *button = (GXAdIconButton *)sender;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setValue:button forKey:VIDEO_AD_COMPLETION_OBJECT_KEY];
    
    if([button.icon.program isEqualToString:GXBUTTON_PROGRAM_ACTION_TYPE_SKIP])
    {
        if ([_currentCreative isKindOfClass:[GTLinear class]])
        {
            // skip tracking을 더이상 하지 않는다.
            //            GTLinear *linear = (GTLinear *)_currentCreative;
            //
            //
            //            GTTracking *skipTracking = [self GX_findTrackEventName:GXTrainkinEventTypeSkip];
            //            [self GX_sendTracking:skipTracking];
            
            // click tracking
            for(int trackCount = 0; trackCount < button.icon.iconClickTracking.count ; trackCount++)
            {
                NSURL *trackURL = [self GX_makeClickTrackingURL:button.icon.iconClickTracking[trackCount]];
                if(trackURL != nil)
                {
                    [[Statistics sharedStatistics] sendStatisticToURL:trackURL];
                }
            }
            
            _didFinishedPlaybackBySkip = YES;
            NSString *value = self.didSelectMoreButton == YES ? VIDEO_AD_COMPLETION_REASON_SKIPPED_BEFORE_CLICKED : VIDEO_AD_COMPLETION_REASON_SKIPPED;
            [userInfo setValue:value forKey:VIDEO_AD_COMPLETION_REASON_KEY];
            
        }
        [self stopPlayByUser];
        self.completion(YES, userInfo);
    }
    else if([button.icon.program isEqualToString:GXBUTTON_PROGRAM_ACTION_TYPE_SKIP_DESC])
    {
        // click tracking
        for(int trackCount = 0 ; trackCount < button.icon.iconClickTracking.count ; trackCount++) {
            NSURL * trackURL = [self GX_makeClickTrackingURL:button.icon.iconClickTracking[trackCount]];
            if (trackURL != nil)
            {
                [[Statistics sharedStatistics] sendStatisticToURL:trackURL];
            }
        }
        
        // click through
        NSURL *url = [NSURL URLWithString:button.icon.iconClickThrough];
        if (url != nil)
        {
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
            {
                [[UIApplication sharedApplication] openURL:url
                                                   options:@{}
                                         completionHandler:nil];
            }
            else
            {
                if (@available(iOS 11.0, *)) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }
        //do nothing..
    }
    else
    {
        self.didSelectMoreButton = YES;
        if ([_currentCreative isKindOfClass:[GTLinear class]])
        {
            _didFinishedPlaybackBySkip = YES;
            
            GTLinear *linear = (GTLinear *)_currentCreative;
            
            // skip tracking을 더이상 하지 않는다.
            //            if ([_currentCreative isKindOfClass:[GTLinear class]])
            //            {
            //                GTLinear *linear = (GTLinear *)_currentCreative;
            //                GTTracking *skipTracking = [self GX_findTrackEventName:GXTrainkinEventTypeSkip];
            //                [self GX_sendTracking:skipTracking];
            //
            //            }
            
            
            // click tracking
            NSURL *trackURL;
            for(int trackCount = 0 ; trackCount < button.icon.iconClickTracking.count ; trackCount++) {
                trackURL = [self GX_makeClickTrackingURL:button.icon.iconClickTracking[trackCount]];
                if (trackURL != nil)
                {
                    [[Statistics sharedStatistics] sendStatisticToURL:trackURL];
                }
            }
            
            
            // click through
            NSURL *url = [NSURL URLWithString:button.icon.iconClickThrough];
            if (url != nil)
            {
                if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
                {
                    [[UIApplication sharedApplication] openURL:url
                                                       options:@{}
                                             completionHandler:nil];
                }
                else
                {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }

            // skip or not
            if(([linear.clickType isEqualToString:@"skip"]) && (trackURL != nil || url != nil))
            {
                [self stopPlayByUser];
                
                [userInfo setValue:VIDEO_AD_COMPLETION_REASON_CLICKED forKey:VIDEO_AD_COMPLETION_REASON_KEY];
                
                self.completion(YES, userInfo);
            }
            
        }
        
    }
}

- (NSURL *) GX_makeClickTrackingURL:(NSString *)trackingURL
{
    if (trackingURL == nil)
    {
        return nil;
    }
    
    NSString *trackURLString = [NSString stringWithFormat:@"%@&et=%0.0f",trackingURL, _mPlayer.currentTime];
    NSURL *trackURL = [NSURL URLWithString:trackURLString];
    
    return trackURL;
}

- (NSArray<GTTracking *> *) GX_findTrackingEventProgress
{
    NSMutableArray<GTTracking *> *result = [[NSMutableArray alloc] init];
    GTLinear *linear = (GTLinear *)_currentCreative;
    for (GTTracking *tracking in linear.trackingEvents)
    {
        if ([tracking.event isEqualToString:GXTrainkinEventTypeProgress])
        {
            [result addObject:tracking];
        }
    }
    
    return [[NSArray alloc] initWithArray:result];
}

- (NSString *)identifierForAdvertising
{
    return identifierForAdvertising();
}

- (BOOL)isPlaying
{
    
    if (self.mPlayer == nil)
    {
        return NO;
    }
    
    if (self.mPlayer.playbackState == GTADPlayerPlaybackStatePlaying || self.mPlayer.playbackState == GTADPlayerPlaybackStatePaused)
    {
        return YES;
    }
    
    return NO;
}

- (void)sendImpressionUrls:(GTAd*)ad
{
    for(NSURL *url in ad.impressionURLs) {
        [[Statistics sharedStatistics] sendStatisticToURL:url];
    }
}

@end
