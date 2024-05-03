# VRiX
> 브릭스 광고 출력 라이브러리.

[![License][license-image]][license-url]
[![Platform](https://img.shields.io/cocoapods/p/LFAlertController.svg?style=flat)](http://cocoapods.org/pods/LFAlertController)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

VMAP, VAST VRiX

## Features

- [x] VMAP, VAST supported.
- [x] Preroll, Midroll, Postroll 광고 지원
- [x] linear, nonlinear 지원

## Requirements

- iOS 8.0+
- Xcode 8.3

## Installation

```ruby
pod 'VRiX_iOS'
```

## Usage example

#### init
```objc
#import <VRiX/VRiXManager.h>

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
#### init (Swift)
```Swift
override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

//    self.vrixManager = VRiXManager(key: <#T##String!#>, hashKey: <#T##String!#>)
    self.vrixManager = VRiXManager(key: VRIX_KEY, hashKey: VRIX_HASHKEY)

    self.isFetchedData = false
    self.progressView .setProgress(0, animated: false)
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    DispatchQueue.main.async {
        self.playButtonTouched(nil)
    }
}

@IBAction func playButtonTouched(_ sender: Any?) {
    if self.vrixManager != nil && self.isFetchedData == false {
        self.registAdNotification()
        let urlString: NSString = VRIX_URL as NSString
        let encodedUrl: NSString = urlString.replacingOccurrences(of: "|", with: "|".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? VRIX_URL) as NSString
        let encodedUrls: String = encodedUrl as String
//            self.vrixManager?.fetchVRiX(<#T##url: URL!##URL!#>, completionHandler: <#T##((Bool, Error?) -> Void)!##((Bool, Error?) -> Void)!##(Bool, Error?) -> Void#>)
        self.vrixManager?.fetchVRiX(URL.init(string: encodedUrls), completionHandler: { (success, error) in
            self.isFetchedData = true;
            if success == true {
                self.playPreroll()
            }
            else {
                self.errorHandler(error: error)
            }
        })
    }
    else {
        //TODO: 재생 토글
    }
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
        [_vrixMananger prerollAtView:_adView completionWithResult:^(NSString* adNames, NSInteger count, NSArray<NSDictionary *>* userInfos) {
        
            //TODO: preroll광고 끝난후에 처리할 내용을 구현
        }];
    }
    else{
        //TODO: 광고가 없을때 처리
    }
}
```
1.1 Preroll & OutStream (Swift)

```Swift
func playPreroll() {
    var numberOfPreroll: NSInteger? = 0
    numberOfPreroll = self.vrixManager?.prerollCount()

    if let numOfPreroll = numberOfPreroll {
        if numOfPreroll > 0 {
            // Play Preroll
//                self.vrixManager?.preroll(at: <#T##UIView!#>, completionWithResult: <#T##((String?, Int, [[AnyHashable : Any]]?) -> Void)!##((String?, Int, [[AnyHashable : Any]]?) -> Void)!##(String?, Int, [[AnyHashable : Any]]?) -> Void#>)
            self.vrixManager?.preroll(at: self.adView, completionWithResult: { (adNames ,count, userInfos) in

                //TODO: preroll광고 끝난후에 처리할 내용을 구현
            })
        }
    }
    else {
        //TODO: 광고가 없을때 처리
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
2.1 Midroll (Swift)
```Swift
func playMidroll() {
    let currentTime: Float64! = CMTimeGetSeconds(self.player?.currentTime() ?? CMTime.zero)
    if let midrollCount = self.vrixManager?.midrollCount() {
        if midrollCount > 0 {
//            self.vrixManager?.midroll(at: <#T##UIView!#>, timeOffset: <#T##TimeInterval#>, progressHandler: <#T##((Bool, GXAdBreakType, NSAttributedString?) -> Void)!##((Bool, GXAdBreakType, NSAttributedString?) -> Void)!##(Bool, GXAdBreakType, NSAttributedString?) -> Void#>, completionHandler: <#T##((GXAdBreakType) -> Void)!##((GXAdBreakType) -> Void)!##(GXAdBreakType) -> Void#>)

            self.vrixManager?.midroll(at: self.adView, timeOffset: currentTime, progressHandler: { (start, breakType, message) in

                if message != nil && breakType == GXAdBreakTypelinear {
                    //TODO: show message
                }

                if start == true {
                    //TODO: 광고가 시작되었을때 처리
                }

            }, completionHandler: { (breakType) in
                //TODO: midroll광고가 완료되었때 처리 
            })
        }
    }
}
```

3. Postroll
```objc
- (void) playpostroll
{
    NSInteger numberOfPostroll = [_vrixMananger postrollCount];
    if (numberOfPostroll > 0){
        [_vrixMananger postrollAtView:_adView completionHandler:^(BOOL success, id userInfo) {
            //TODO:postroll광고 끝난후에 처리할 내용을 구현
        }];
}
```
3.1 Postroll (Swift)
```Swift
func playPostroll() {
    if let numberOfPostroll = self.vrixManager?.postrollCount() {
        if numberOfPostroll > 0 {
//            self.vrixManager?.postroll(at: <#T##UIView!#>, completionHandler: <#T##((Bool, Any?) -> Void)!##((Bool, Any?) -> Void)!##(Bool, Any?) -> Void#>)
            self.vrixManager?.postroll(at: self.adView, completionHandler: { (success, userInfo) in
                //TODO:postroll광고 끝난후에 처리할 내용을 구현
            })
        }
    }
    else {
        //TODO:postroll광고 없을 때 처리할 내용을 구현
    }
}
```

4. Stop AD
```objc
[self.vrixMananger stopCurrentAD];
```
4.1 Stop AD (Swift)
```Swift
if let vrixMgr = self.vrixManager {
    vrixMgr.stopCurrentAD()
}
```

5. AD Player의 상태변화에 따른 Notfication 제공 (Get Current AD druation,  current time 사용법)

```objc
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
                                             selector:@selector(AdStop:)
                                                 name:GTADPlayerStopByUserNotification
                                               object:nil];
                                               
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AdPlayToEnd:)
                                                 name:GTADPlayerDidPlayToEndTimeNotification
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
                                                name:GTADPlayerStopByUserNotification
                                              object:nil];
                                              
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GTADPlayerDidPlayToEndTimeNotification
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
    NSLog(@"AD is Playing (Duration: %0.1f, playtime: %0.1f)",[self.vrixMananger getCurrentAdDuration], [self.vrixMananger getCurrentAdPlaytime]);
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
```
5.1 AD Player의 상태변화에 따른 Notfication 제공 (Get Current AD druation,  current time 사용법) (Swift)
```Swift
extension Notification.Name {
    public static let GTADPlayerDidPlayEndTimeNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidPlayToEndTime.rawValue)
    public static let GTADPlayerStopByUserNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerStopByUser.rawValue)
    public static let GTADPlayerPrepareToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerPrepareToPlay.rawValue)
    public static let GTADPlayerReadyToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerReadyToPlay.rawValue)
    public static let GTADPlayerDidPlayBackChangeNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidPlayBackChange.rawValue)
    public static let GTADPlayerDidFailToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidFailToPlay.rawValue)
}

func registAdNotification () {
    self.unregistAdNotification()

    NotificationCenter.default.addObserver(self, selector: #selector(AdPreparePlay(sender:)), name: Notification.Name.GTADPlayerPrepareToPlay, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(AdReadyToPlay(sender:)), name: Notification.Name.GTADPlayerReadyToPlay, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(AdPlayBackDidChange(sender:)), name: Notification.Name.GTADPlayerDidPlayBackChange, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(AdPlayToEnd(sender:)), name: Notification.Name.GTADPlayerDidPlayToEndTime, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(AdStop(sender:)), name: Notification.Name.GTADPlayerStopByUser, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(AdFailToPlay(sender:)), name: Notification.Name.GTADPlayerDidFailToPlay, object: nil)
}

func unregistAdNotification () {
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerPrepareToPlay, object: nil)
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerReadyToPlay, object: nil)
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerDidPlayBackChange, object: nil)
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerDidPlayToEndTime, object: nil)
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerStopByUser, object: nil)
    NotificationCenter.default.removeObserver(self, name:Notification.Name.GTADPlayerDidFailToPlay, object: nil)
}

@objc func AdPreparePlay(sender: Any?) {
    print("AdPreparePlay")
}

@objc func AdReadyToPlay(sender: Any?) {
    print("Ready to Play AD")
}

@objc func AdPlayBackDidChange(sender: Any?) {
    print("AD is Playing (Duration: %0.3f, playtime: %0.3f", self.vrixManager?.getCurrentAdDuration() ?? CMTime.zero, self.vrixManager?.getCurrentAdPlaytime() ?? CMTime.zero)
}

@objc func AdStop(sender: Any?) {
    print("Maybe skipped by User...")
}

@objc func AdPlayToEnd(sender: Any?) {
    print("AD Completed!!")
}

@objc func AdFailToPlay(sender: Any?) {
    print("AD load failed!!")
}
```

#### VRiX Handling methods
```objc
/*!
@method			initWithKey:hashKey:
@param          key 사용자별 키값
@param			hashKey 사용자별 시크릿 키값
@discussion		브릭스를 핸들링가능한 메니져를 init한다.
*/
- (VRiXManager *) initWithKey:(NSString *)key hashKey:(NSString *)hashKey;

/*!
@method			fetchVRiX:completionHandler:
@param				url VRiX주소
@param				handler fetch 완료 호출될 block
@discussion		브릭스서비스에서 광고 정보를 fetch한다..
*/
- (void) fetchVRiX:(NSURL *)url
completionHandler:(void (^)(BOOL success, NSError *error))handler;

/*!
@method			stopCurrentAD
@discussion		현재 재생중인 광고를 중지 시킨다.
*/
- (void) stopCurrentAD;

/*!
@method			prerollAtView:completionHandler
@param				targetView 광고가 재생될 뷰
@param				handler 광고재생 완료 후 호출될 block
@discussion		프리롤 광고를 해당뷰에 재생시킨다.
*/
- (void) prerollAtView:(UIView *)targetView
completionHandler:(void (^)(BOOL success, id userInfo))handler;

/*!
@method			prerollCount
@discussion		프리롤광고의 곗수를 리턴한다.
*/
- (NSInteger) prerollCount;

/*!
@method			midrollAtView:timeOffset:progressHandler:completionHandler
@param				targetView 광고가 재생될 뷰
@param             offset 현재 재생중인 컨텐츠의 재생시간
@param             progressHandler timeOffset에 따른 결과값 block 코드
@param				completionHandler 광고재생 완료 후 호출될 block
@discussion		미드롤 광고를 해당뷰에 재생한다.
*/
- (void) midrollAtView:(UIView *)targetView
timeOffset:(NSTimeInterval)offset
progressHandler:(void (^)(BOOL whenItStart, GXAdBreakType breakType, NSAttributedString *message))progressHandler
completionHandler:(void (^)(GXAdBreakType breakType))completionHandler;

/*!
@method			midrollCount
@discussion		미드롤광고의 곗수를 리턴한다.
*/
- (NSInteger) midrollCount;

/*!
@method			postrollAtView:completionHandler
@param				targetView 광고가 재생될 뷰
@param				handler 광고재생 완료 후 호출될 block
@discussion		포스트롤 광고를 해당뷰에 재생시킨다.
*/
- (void) postrollAtView:(UIView *)targetView
completionHandler:(void (^)(BOOL success, id userInfo))handler;

/*!
@method			postrollCount
@discussion		포스트롤광고의 곗수를 리턴한다.
*/
- (NSInteger) postrollCount;
```

### Version 0.1.4 변경 내역
- 함수 포인트 오류로 인한 빌드 오류 수정


## License

Gomcorp – (https://www.gomcorp.com/) – pudaegii@gomcorp.com

Copyright © 2017 Gomcorp.

[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
