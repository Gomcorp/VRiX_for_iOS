//
//  GXPlayerView.m
//  GoxParser
//
//  Created by GOMIMAC on 2017. 6. 13..
//  Copyright © 2017년 Youngchang koo. All rights reserved.
//

#import "GXPlayerView.h"

@implementation GXPlayerView

- (AVPlayer *)player
{
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
}

// Override UIView method
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
