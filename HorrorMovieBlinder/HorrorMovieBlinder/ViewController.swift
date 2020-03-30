//
//  ViewController.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/03/30.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var objectNameLabel: UILabel!
    
    // MARK: - Image Classification
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             1. Core ML Model 모델과 함께 Vision 설정
             //모델을 이용해서 Vision request를 설정하려면, VNCoreMLRequest 객체를 만들어야한다. 이를 위해선 해당 클래스의 인스턴스를 만들고 그것의 model 프로퍼티를 사용한다.
             */
            let model = try VNCoreMLModel(for: ObjectDetector().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            /*
             ML model은 input image를 고정된 비율로 처리하지만, 실제 input image는 임의의 고정비율을 가질수 있기 때문에 Vision은 반드시 이미지를 알맞게 늘리거나 잘라야한다.
             최선의 결과를 위해서 request의 imageCropAndScaleOption 프로퍼티를 모델이 트레이닝한 이미지의 레이아웃과 맞도록 설정한다.
             가능한 분류 모델에 대해서는 따로 명시되지 않는한 VNImageCropAndScaleOption.centerCrop 옵션이 적절하다.
             */
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    func updateClassifications(for image: UIImage) {
        objectNameLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        /*
         2. Vision Request 동작
         처리될 이미지와 함께 VNImageRequestHandler 객체를 생성한다. 그리고 결과를 perform(_:) 메소드에 전달한다.
         해당 메소드는 background 큐를 사용하기 때문에 메인 큐가 block되지 않는다.
         */
        DispatchQueue.global(qos: .userInitiated).async {
       
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 여기서 일반적인 이미지 처리 에러를 캐치한다.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    /*
     3. 이미지 분류 결과 처리
     Vision request의 completion handler는 요청이 성공했냐 실패했냐를 알려준다.
     만약 성공했으면 results 프로퍼티가 ML model에 의해 정의된 가능한 분류를 나타내는 VNClassificationObservation 객체를 포함하고 있다.
     */
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.objectNameLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            
            if results.isEmpty {
                self.objectNameLabel.text = "Nothing recognized."
                return
            }
                
            switch results.first! {
            case is VNClassificationObservation:
                let classifications = results as! [VNClassificationObservation]
                if let topClassification = classifications.first {
                    self.objectNameLabel.text = String(format: "  (%.2f) %@", topClassification.confidence, topClassification.identifier)
                }
            case is VNRecognizedObjectObservation:
                let predictions = results as! [VNRecognizedObjectObservation]
                predictions.forEach { (prediction) in
                    self.createLabelAndBox(prediction: prediction)
                }
            default:
                fatalError("Unexptected Results")
            }
                
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = imageView.image else {
            return
        }
        updateClassifications(for: image)
        
    }
    
    func createLabelAndBox(prediction: VNRecognizedObjectObservation) {
        let labelString: String? = String(format: "(%.2f) %@", prediction.confidence, prediction.label ?? "")
        let color: UIColor = .red

        let scale = CGAffineTransform.identity.scaledBy(x: imageView.bounds.width, y: imageView.bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let bgRect = prediction.boundingBox.applying(transform).applying(scale)
        let bgView = UIView(frame: bgRect)
        bgView.layer.borderColor = color.cgColor
        bgView.layer.borderWidth = 4
        bgView.backgroundColor = UIColor.clear
        imageView.addSubview(bgView)

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        label.text = labelString ?? "N/A"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: bgRect.origin.x, y: bgRect.origin.y - label.frame.height,
                             width: label.frame.width, height: label.frame.height)
        imageView.addSubview(label)
    }
       
}

extension VNRecognizedObjectObservation {
    var label: String? {
        return self.labels.first?.identifier
    }
    
}
