//
//  BlurredVideoView.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/04/01.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit
import AVKit
import Vision

class BlurredVideoView: UIView {
    var blurRadius: Double = 5.0
    var player: AVPlayer!
    
    private var output: AVPlayerItemVideoOutput!
    private var displayLink: CADisplayLink!
    //trade off- 색 퀄리티 저하 vs 성능 향상
    private var context: CIContext = CIContext(options: [CIContextOption.workingColorSpace : NSNull()])
    private var playerItemObserver: NSKeyValueObservation?
    private var baseImg: CIImage?
    private var blurImg: CIImage?
    
    func play(stream: URL) {
        let item = AVPlayerItem(url: stream)
        player = AVPlayer(playerItem: item)
        
        //이 옵저버 없어질때 KVO observer도 자동으로 없어짐
        playerItemObserver = item.observe(\.status) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            //준비되면 더 이상 옵저빙 안해도 되니까 해제
            self?.playerItemObserver = nil
            
            self?.setupDisplayLink()
            self?.player.play()
        }
        
        output = AVPlayerItemVideoOutput(outputSettings: nil)
        item.add(output)
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdated(link:)))
        displayLink.preferredFramesPerSecond = 20
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func displayLinkUpdated(link: CADisplayLink) {
        //비디오의 현재 시간
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard output.hasNewPixelBuffer(forItemTime: time),
            let pixbuf = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
                return
        }
        
        baseImg = CIImage(cvImageBuffer: pixbuf)
        guard let baseImg = baseImg else {return}
        blurImg = baseImg.clampedToExtent().applyingGaussianBlur(sigma: blurRadius).cropped(to: baseImg.extent)
        request(image: baseImg, orientation: .up)
    }
    
    func show(image: CIImage?) {
        guard let image = image
            ,let cgImg = self.context.createCGImage(image, from: image.extent) else { return }
        self.layer.contents = cgImg
    }
}

//Filter
extension BlurredVideoView {
    func convertToCI(from image: UIImage) -> CIImage {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        return ciImage
    }
    
    func request(image: CIImage, orientation: CGImagePropertyOrientation) {
        // 1. 얼굴 주위 박스 처리하기 위해 얼굴 감지 request 생성. 그리고 결과를 completion handler로 넘겨줌
        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)

        // 2. 만들 request handler 이용해서 이미지에 대해 페이스 디텍션 처리.
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
            do {
                try handler.perform([detectFaceRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }

    //handler
    func detectedFace(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNFaceObservation]
                ,!results.isEmpty
                else {
                    self.show(image: self.baseImg)
                    return
            }
            
            let isNeedBlur = results
                .map { !$0.confidence.isLess(than: 0.8) }
                .reduce(false) { $0 || $1 }
            
            if !isNeedBlur {
                self.show(image: self.baseImg)
                return
            }
            
            self.show(image: self.blurImg)
        }
    }
}


