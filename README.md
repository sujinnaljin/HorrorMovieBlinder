# HorrorMovieBlinder

## Overview

iOS의  **AVKit**, **Vision** 및 **Sound Analysis** Framework 사용하여 여러 기능을 적용해본 프로젝트입니다.

## 주요 기능 

- **이미지 분류**

  VNDetectFaceLandmarksRequest 객체를 사용하여 '사람의 얼굴'을 감지할 수 있습니다.

- **상황에 따른 이미지 필터 적용 (사람 얼굴 감지 되었을 때)**

  고정된 이미지에서 얼굴 객체의 신뢰도(confidence)를 기반으로 필터 처리를 합니다. (CIFilter 중 CIGaussianBlur 이용)

- **상황에 따른 영상 필터 적용 (사람 얼굴 감지 되었을 때)**

  HTTP 라이브 스트리밍 영상에서 얼굴 객체의 신뢰도(confidence)를 기반으로 필터 처리를 합니다. (CIFilter 중 CIGaussianBlur 이용)

  CADisplayLink를 이용해 20fps 마다 해당 작업을 수행합니다.

- **상황에 따른 음량 감소 (새 소리가 날 때)** 

  SNAudioStreamAnalyzer를 이용해 분석한 결과의 identifier와 confidence를 기반으로 AVPlayer의 소리를 줄입니다.

## Preview

 ![preview](https://media.giphy.com/media/eM6WHUeqrytE2jpmuL/giphy.gif)



## Develop Environment 

- Language :  **Swift 5**

- iOS Depolyment Target : **13.2**

