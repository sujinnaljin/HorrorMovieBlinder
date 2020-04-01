//
//  VideoViewController.swift
//  HorrorMovieBlinder
//
//  Created by 강수진 on 2020/04/01.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit
import AVKit
import SoundAnalysis
import MediaPlayer

class VideoViewController: UIViewController {

    @IBOutlet var videoView: BlurredVideoView!
    
    //오디오
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = BirdSoundClassifier()
    var inputFormat: AVAudioFormat!
    var audioAnalyzer: SNAudioStreamAnalyzer!
    var resultsObserver = AudioResultsObserver()
    let analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")

    let streamURL = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!

    
    override func viewDidLoad() {
        setupAudio()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoView.play(stream: streamURL)
        startAudio(audioFileURL: streamURL)
    }
}

//참고 - 내장 파일일때 이런식으로 간단히 처리할 수 있다
extension VideoViewController {
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

extension VideoViewController {
    private func setupAudio() {
        resultsObserver.delegate = self
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        audioAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
    }
    
    func startAudio(audioFileURL: URL) {
        // Prepare a new request for the trained model.
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try audioAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }
        
        //analyzer는 고정된 블럭 사이즈로 analyze
        //8k 버퍼
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8192, format: inputFormat) { buffer, time in
            self.analysisQueue.async {
                // 오디오 데이터 분석
                self.audioAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        do{
            try audioEngine.start()
        } catch( _){
            print("error in starting the Audio Engin")
        }
    }
}

extension VideoViewController: BirdClassifierDelegate {
    func handleResult(isVolmeToDown: Bool) {
        self.videoView.player.volume = isVolmeToDown ? 0.5 : 1.0
    }
}

protocol BirdClassifierDelegate {
    func handleResult(isVolmeToDown: Bool)
}
