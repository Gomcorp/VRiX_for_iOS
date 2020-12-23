//
//  GXPlayerView.h
//  GoxParser
//
//  Created by GOMIMAC on 2017. 6. 13..
//  Copyright © 2017년 Youngchang koo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface GXPlayerView : UIView
@property AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;
@end
