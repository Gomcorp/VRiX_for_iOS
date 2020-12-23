//
//  GXVideoPlayerView.h
//  VRiX_Example
//
//  Created by GOMIMAC on 2020/09/24.
//  Copyright © 2020 adx-developer. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVPlayer;
@class AVPlayerLayer;
@interface GXVideoPlayerView : UIView
@property AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;
@end

NS_ASSUME_NONNULL_END
