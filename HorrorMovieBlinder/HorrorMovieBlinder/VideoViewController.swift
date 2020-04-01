//
//  VideoViewController.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/04/01.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit
import AVKit

class VideoViewController: UIViewController {

    @IBOutlet var videoView: BlurredVideoView!

    let streamURL = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!

    override func viewDidLoad() {
        super.viewDidLoad()
        videoView.play(stream: streamURL)
    }
    
    //참고
    //내장 파일일때 이런식으로 간단히 처리할 수 있다
    func filePlay() {
        let fileStream = URL(fileURLWithPath: "\(Bundle.main.bundlePath)/IMG_9874.MOV")
        let blurRadius = 5.0
        let asset = AVAsset(url: fileStream)
        let item = AVPlayerItem(asset: asset)
        item.videoComposition = AVVideoComposition(asset: asset) { request in
            let blurred = request.sourceImage.clampedToExtent().applyingGaussianBlur(sigma: blurRadius)
            let output = blurred.clamped(to: request.sourceImage.extent)
            request.finish(with: output, context: nil)
        }
        
        let player = AVPlayer(playerItem: item)
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
}
