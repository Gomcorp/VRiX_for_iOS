//
//  VRIXViewController.h
//  VRiX_iOS
//
//  Created by gombridge@gmail.com on 12/23/2020.
//  Copyright (c) 2020 gombridge@gmail.com. All rights reserved.
//

@import UIKit;

@class GXVideoPlayerView;

@interface VRIXViewController : UIViewController

@property (strong, nonatomic) IBOutlet GXVideoPlayerView* mainVideoView;
@property (strong, nonatomic) IBOutlet UIView*          adView;
@property (strong, nonatomic) IBOutlet UILabel*         messageLabel;

@property (strong, nonatomic) IBOutlet UIView*          controlView;
@property (strong, nonatomic) IBOutlet UIButton*        playButton;
@property (strong, nonatomic) IBOutlet UIProgressView*  progressView;

- (IBAction)rewindButtonTouched:(id)sender;
- (IBAction)fastfowardButtonTouched:(id)sender;

- (IBAction)playButtonTouched:(id)sender;

@end
