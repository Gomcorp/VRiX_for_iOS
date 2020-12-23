# VRiX_iOS

> 브릭스 광고 출력 라이브러리.

[![Swift Version][swift-image]][swift-url]
[![Build Status][travis-image]][travis-url]
[![License][license-image]][license-url]
[![Platform](https://img.shields.io/cocoapods/p/LFAlertController.svg?style=flat)](http://cocoapods.org/pods/LFAlertController)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

VMAP, VAST VRiX

## Features

- [x] VMAP, VAST supported.
- [x] Preroll, Midroll, Postroll 광고 지원
- [x] linear, nonlinear 지원

## How to use sample

To run the VRiX project, clone the repo, and run `pod install` from the VRiX directory first.

## Requirements

- iOS 9.3+
- Xcode 8.3

## Installation

VRiX is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'VRiX'
```

## Usage example

#### init
```objc
#import <VRiX/VRiXManager.h>

- (void)viewDidLoad {
    [super viewDidLoad];
    self.vrixMananger = [[VRiXManager alloc] initWithKey:VRIX_KEY hashKey:VRIX_HASHKEY];

    [self.vrixMananger fetchVRiX:[NSURL URLWithString:encodedUrl]
               completionHandler:^(BOOL success, NSError *error){
                    //
                    if (success == YES){
                        [self playPreroll];
                    }else{
                        //TODO: error handler
                    }
                }];
}
```
#### Play AD
1. Preroll & OutStream

```objc
- (void) playPreroll
{
    NSInteger numberOfPreroll = [_vrixMananger prerollCount];
    if (numberOfPreroll > 0){
        // Play Preroll
        [_vrixMananger prerollAtView:_adView completionHandler:^{
            //TODO: preroll광고 끝난후에 처리할 내용을 구현
        }];
    }
}
```
2. Midroll
```objc
- (void) playMidroll
{
    CGFloat currentTime = CMTimeGetSeconds(_player.currentTime);

    //vrix midroll handling
    if([_vrixMananger midrollCount] > 0){
        // Play Midroll
        [_vrixMananger midrollAtView:_adView
                          timeOffset:currentTime
                     progressHandler:^(BOOL start, GXAdBreakType breakType, NSAttributedString *message){
                            //
                            if (message != nil && breakType == GXAdBreakTypelinear){
                                //TODO: show message
                            }

                            if (start == YES){
                                //TODO: 광고가 시작되었을때 처리
                            }
                
                    }
                    completionHandler:^(GXAdBreakType breakType){
                            //TODO: midroll광고가 완료되었때 처리 
                    }];
                }
        }];
    }
}
```

3. Postroll
```objc
- (void) playpostroll
{
    NSInteger numberOfPostroll = [_vrixMananger postrollCount];
    if (numberOfPostroll > 0){
        [_vrixMananger postrollAtView:_adView completionHandler:^{
            //TODO:postroll광고 끝난후에 처리할 내용을 구현
        }];
}
```
4. Stop AD
```objc
    [self.vrixMananger stopCurrentAD];
```

## Author

Gomcorp, kuyoungchang@gretech.com

## License

Gomcorp – (https://www.gomcorp.com/) – kuyoungchang@gomcorp.com

Copyright © 2017 Gomcorp.

[swift-image]:https://img.shields.io/badge/swift-3.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
