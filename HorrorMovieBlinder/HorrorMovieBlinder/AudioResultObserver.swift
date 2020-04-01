//
//  AudioResultObserver.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/04/01.
//  Copyright © 2020 강수진. All rights reserved.
//

import SoundAnalysis

// Observer 객체. 분석 결과가 나타나면 콜 됨
class AudioResultsObserver : NSObject, SNResultsObserving {
    var delegate: BirdClassifierDelegate?
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        // 분류 가져옴
        guard let result = result as? SNClassificationResult,
            let classification = result.classifications.first else { return }
        
        if classification.confidence > 0.8 &&
            classification.identifier == "hasbird" {
            delegate?.handleResult(isVolmeToDown: true)
        } else {
            delegate?.handleResult(isVolmeToDown: false)
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}
