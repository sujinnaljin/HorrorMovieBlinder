//
//  ImageViewController.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/04/01.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit
import Vision

class ImageViewController: UIViewController {
    
    @IBOutlet var faceView: UIImageView!
    let context =  CIContext()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = faceView.image {
            request(image: convertToCI(from: image), orientation: getImageOrientation(from: image))
        }
    }
    
    func convertToCI(from image: UIImage) -> CIImage {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        return ciImage
    }
    
    func getImageOrientation(from image: UIImage) -> CGImagePropertyOrientation {
        return CGImagePropertyOrientation(image.imageOrientation)
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
        guard let results = request.results as? [VNFaceObservation]
            ,!results.isEmpty
            else {
                return
        }
        
        let isNeedBlur = results
            .map { !$0.confidence.isLess(than: 0.8) }
            .reduce(false) { $0 || $1 }
        
        if !isNeedBlur {
            return
        }
    
        DispatchQueue.main.async {
            guard let baseImg = CIImage(image: self.faceView.image!) else {
                fatalError("Cannot find source image")
            }
            
            let blurImg = baseImg
                .clampedToExtent()
                .applyingGaussianBlur(sigma: 10)
                .cropped(to: baseImg.extent)
           
            guard let cgImg = self.context.createCGImage(blurImg, from: blurImg.extent) else { return }
            self.faceView.image = UIImage(cgImage: cgImg)
        }
    }
}

