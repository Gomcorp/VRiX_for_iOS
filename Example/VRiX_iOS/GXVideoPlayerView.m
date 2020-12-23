//
//  GXVideoPlayerView.m
//  VRiX_Example
//
//  Created by GOMIMAC on 2020/09/24.
//  Copyright © 2020 adx-developer. All rights reserved.
//

#import "GXVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation GXVideoPlayerView

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
}

// Override UIView method
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer
{
    return (AVPlayerLayer *)self.layer;
}


@end
