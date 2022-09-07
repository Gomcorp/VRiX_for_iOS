//
//  ViewController.swift
//  VRIX_For_iOS_Swift
//
//  Created by GOM&COMPANY IMAC on 2020/12/10.
//

import UIKit

let MAIN_CONTENTS_URL   = "https://videok.ait.cool/video/hd/000/029/530.mp4"
let VRIX_URL            = "https://devads.vrixon.com/vast/vast.vrix?invenid=KHLOC"
let VRIX_KEY            = "574643454"
let VRIX_HASHKEY        = "577c3adb3b614c54"

extension Notification.Name {
    public static let GTADPlayerDidPlayEndTimeNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidPlayToEndTime.rawValue)
    public static let GTADPlayerStopByUserNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerStopByUser.rawValue)
    public static let GTADPlayerPrepareToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerPrepareToPlay.rawValue)
    public static let GTADPlayerReadyToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerReadyToPlay.rawValue)
    public static let GTADPlayerDidPlayBackChangeNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidPlayBackChange.rawValue)
    public static let GTADPlayerDidFailToPlayNotification: Notification.Name = Notification.Name.init(NSNotification.Name.GTADPlayerDidFailToPlay.rawValue)
}

class ViewController: UIViewController {
    
    @IBOutlet var mainVideoView: GXXVideoPlayerView!
    @IBOutlet var adView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var controlView: UIView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    var vrixManager : VRiXManager?
    var player: AVPlayer?
    var isFetchedData = false
    var timelineTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let vrixMgr = self.vrixManager {
            vrixMgr.stopCurrentAD()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft ||
            UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            DispatchQueue.main.async {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            }
        }
        else {
            DispatchQueue.main.async {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
    }
    
    
    //MARK: - control vrix
    func playPreroll() {
        var numberOfPreroll: NSInteger? = 0
        numberOfPreroll = self.vrixManager?.prerollCount()
        
        if let numOfPreroll = numberOfPreroll {
            if numOfPreroll > 0 {
                self.adView.isHidden = false
                self.controlView.isHidden = true
                
                self.vrixManager?.preroll(at: self.adView, completionWithResult: { (adNames ,count, userInfos) in

                    print("%@", adNames!)
                    
                    self.playMainContent()
                    self.playButton.isSelected = true
                })
            }
        }
        else {
            self.playMainContent()
        }
    }
    
    func playMidroll() {
        let currentTime: Float64! = CMTimeGetSeconds(self.player?.currentTime() ?? CMTime.zero)
        if let midrollCount = self.vrixManager?.midrollCount() {
            if midrollCount > 0 {

                self.vrixManager?.midroll(at: self.adView, timeOffset: currentTime, progressHandler: { (start, breakType, message) in
                    
                    if message != nil && breakType == GXAdBreakTypelinear {
                        self.messageLabel.attributedText = message
                    }
                    
                    if start == true {
                        if breakType == GXAdBreakTypelinear {
                            self.playButtonTouched(nil)
                        }
                        self.adView.isHidden = false
                        self.controlView.isHidden = true
                    }
                    
                }, completionHandler: { (breakType) in
                    
                    if breakType == GXAdBreakTypelinear {
                        self.playButtonTouched(nil)
                    }
                    
                    self.adView.isHidden = true
                    self.controlView.isHidden = false
                })
            }
        }
    }
    
    func playPostroll() {
        if let numberOfPostroll = self.vrixManager?.postrollCount() {
            if numberOfPostroll > 0 {
                self.adView.isHidden = false
                self.controlView.isHidden = true
                
                self.vrixManager?.postroll(at: self.adView, completionHandler: { (success, userInfo) in
                    self.vrixManager = nil
                    self.isFetchedData = false
                    
                    self.playButtonTouched(nil)
                })
            }
        }
        else {
            self.playButtonTouched(nil)
        }
    }
    
    func playMainContent() {
        self.adView.isHidden = true
        let videoURL: URL! = URL.init(string: MAIN_CONTENTS_URL)
        self.player = AVPlayer.init(url: videoURL)
        self.mainVideoView.player = self.player
        self.player?.play()
        self.controlView.isHidden = false
        self.playButton.isSelected = true
    }
    
    func errorHandler(error: Error?) {
        
    }
    
    //MARK: Button Handler
    
    @IBAction func reload(_ sender: Any) {
        self.isFetchedData = false
        self.playButtonTouched(self)
    }
    
    @IBAction func playButtonTouched(_ sender: Any?) {
        if self.vrixManager != nil && self.isFetchedData == false {
//            self.registAdNotification()
            let urlString: NSString = VRIX_URL as NSString
            let encodedUrl: NSString = urlString.replacingOccurrences(of: "|", with: "|".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? VRIX_URL) as NSString
            let encodedUrls: String = encodedUrl as String
            
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
            if self.playButton.isSelected == true {
                self.player?.pause()
                self.playButton.isSelected = false
            }
            else {
                self.player?.play()
                self.playButton.isSelected = true
            }
        }
    }
    
    @IBAction func rewindButtonTouched(_ sender: Any?) {

        let currentTime: Float64! = CMTimeGetSeconds(self.player?.currentTime() ?? CMTime.zero)
        var changeTime: Float64 = 0
        
        if currentTime > 30 {
            changeTime = currentTime - 30
        }
        
        self.player?.seek(to: CMTimeMakeWithSeconds(changeTime, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    @IBAction func fastfowardButtonTouched(_ sender: Any?) {
        let duration: Float64! = CMTimeGetSeconds(self.player?.currentItem?.asset.duration ?? CMTime.zero)
        let currentTime: Float64! = CMTimeGetSeconds(self.player?.currentTime() ?? CMTime.zero)
        var changeTime: Float64! = 0
        
        if duration <= currentTime + 30 {
            changeTime = duration - 5
        }
        else {
            changeTime = currentTime + 30
        }
        
        self.player?.seek(to: CMTimeMakeWithSeconds(changeTime, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
    
    
    //MARK: Player Notification
    func playerItemDidPlayToEndTime(notification: NSNotification) {
        if notification.object as! NSObject == (self.player?.currentItem)! as NSObject {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            self.playPostroll()
        }
    }
    
    // MARK: Timeline Timer
    func startTicking() {
        if self.timelineTimer == nil {
            self.timelineTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                      target: self,
                                                      selector: #selector(GT_timelineTimerDidFire(timer:)),
                                                      userInfo: nil,
                                                      repeats: true)
        }
        self.timelineTimer?.fireDate = Date.init(timeIntervalSinceNow: 0.5)
        self.GT_timelineTimerDidFire(timer: self.timelineTimer)
    }
    
    func stopTicking () {
        self.timelineTimer?.fireDate = Date.distantFuture
    }
    
    func invalidateTicking() {
        if self.timelineTimer?.isValid == true {
            self.timelineTimer?.invalidate()
        }
        self.timelineTimer = nil
    }
    
    @objc func GT_timelineTimerDidFire(timer: Timer?) {
        if self.player == nil {
            return
        }
        
        // post notification
//        Void (^block)(Void) = ^{
        func block() {
            // progress bar change
            let duration: Float64! = CMTimeGetSeconds(self.player?.currentItem?.asset.duration ?? CMTime.zero)
            let currentTime: Float64! = CMTimeGetSeconds(self.player?.currentTime() ?? CMTime.zero)
            self.progressView.progress = Float(currentTime / duration)
            
            // vrix midroll handling
            if let midrollCount = self.vrixManager?.midrollCount() {
                if midrollCount > 0 {
                    self.playMidroll()
                }
            }
        }
        
        if Thread.isMainThread == true {
            block()
        }
        else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
    
    //MARK: notification
    func registAdNotification () {
        self.unregistAdNotification()
//
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
}

