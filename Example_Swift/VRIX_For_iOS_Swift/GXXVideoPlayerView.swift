//
//  GXVideoPlayerView.swift
//  VRIX_For_iOS_Swift
//
//  Created by GOM&COMPANY IMAC on 2020/12/16.
//

import UIKit

class GXXVideoPlayerView: UIView {
    
    var player : AVPlayer? {
        get {
            return self.playerLayer.player
        }
        set(player) {
            self.playerLayer.player = player
        }
    }
    var playerLayer : AVPlayerLayer {
//        if let layer = self.layer as! AVPlayerLayer {
//            return layer
//        }
        return self.layer as! AVPlayerLayer
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    // Override UIView method
    override static var layerClass: AnyClass {
        get {
//            return CAGradientLayer.self
            return AVPlayerLayer.self
        }
    }
}
