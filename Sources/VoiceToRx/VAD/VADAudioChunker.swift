//
//  VADAudioChunker.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 13/08/24.
//

import Foundation

final class VADAudioChunker {
  
  // MARK: - Properties
  
  /// Dynamic audio data
  struct AudioData {
    /// Array to store past VAD frames since the last clip point
    var vadPast: [Int]
    /// Index of the last clip point
    var lastClipIndex: Int
    /// Array to store the indices of clip points
    var clipPoints: [Int]
    /// Accumulator for the duration of silence
    var silDurationAcc: Int
    /// Count of the past vad points
    var vadPastCount: Int
    
    init(
      vadPast: [Int] = [],
      clipPoints: [Int] = [],
      lastClipIndex: Int = 0,
      silDurationAcc: Int = 0,
      vadPastCount: Int = 0
    ) {
      self.vadPast = vadPast
      self.lastClipIndex = lastClipIndex
      self.clipPoints = clipPoints
      self.silDurationAcc = silDurationAcc
      self.vadPastCount = vadPastCount
    }
  }
  
  var audioData: AudioData
  
  /// Preferred length in samples
  let prefLengthSamples: Int
  
  /// Desperate length in samples
  let despLengthSamples: Int
  
  /// Maximum length in samples
  let maxLengthSamples: Int
  
  /// Threshold for short silences in samples
  let shorThsld: Int
  
  /// Threshold for long silences in samples
  let longThsld: Int
  
  /// sample rate of the vad
  let vadSampleRate: Int
  
  // MARK: - Init
  
  init(
    prefLength: Int = 10,
    despLength: Int = 20,
    maxLength: Int = 25,
    vadSampleRate: Int = 50, /// 50 Samples per second
    audioData: AudioData = .init()
  ) {
    /// Convert lengths from seconds to samples
    self.prefLengthSamples = prefLength * vadSampleRate
    self.despLengthSamples = despLength * vadSampleRate
    self.maxLengthSamples = maxLength * vadSampleRate
    self.vadSampleRate = Int(RecordingConfiguration.shared.requiredSampleRate / RecordingConfiguration.shared.sizedDownMinimumBufferSize)
    
    /// Thresholds for short and long silences
    self.shorThsld = Int(0.2 * Double(vadSampleRate))
    self.longThsld = Int(0.5 * Double(vadSampleRate))
    
    /// Update dynamic data
    self.audioData = audioData
  }
  
  /// To reset previously existing values
  func reset() {
    audioData = .init()
  }
  
  /// Method to process VAD and send the index at which VAD is to be done
  func process(vadFrame: Int) -> (Bool, Int) {
    /// Flag to check if current frame is a clip point
    var shouldMakeClipPoint = false
    
    /// Update silence duration based on VAD frame
    updateSilenceDuration(vadFrame: vadFrame)
    
    /// Calculate the number of samples passed since the last clip point
    let samplePassed = (audioData.vadPastCount - audioData.lastClipIndex)
    if shouldCreateClipPoint(prefLength: samplePassed > prefLengthSamples, threshold: longThsld) {
      createClipPoint(at: audioData.vadPastCount - Int(audioData.silDurationAcc / 2))
      shouldMakeClipPoint = true
    } else if shouldCreateClipPoint(prefLength: samplePassed > despLengthSamples, threshold: shorThsld) {
      createClipPoint(at: audioData.vadPastCount - Int(audioData.silDurationAcc / 2))
      shouldMakeClipPoint = true
    } else if samplePassed >= maxLengthSamples {
      createClipPoint(at: audioData.vadPastCount)
      shouldMakeClipPoint = true
    }
    
    updateAudioVadPast(vadFrame: vadFrame) 
    
    return (shouldMakeClipPoint, audioData.clipPoints.last ?? 0)
  }
  
  /// Method to update the silence duration based on the current VAD frame
  private func updateSilenceDuration(vadFrame: Int) {
    if !audioData.vadPast.isEmpty {
      if vadFrame == 0 {
        /// Increase silence duration accumulator if VAD frame is silence
        audioData.silDurationAcc += 1
      } else if vadFrame == 1 {
        /// Reset silence duration accumulator if VAD frame is speech
        audioData.silDurationAcc = 0
      }
    }
  }
  
  private func updateAudioVadPast(vadFrame: Int) {
    /// Append current VAD frame to past frames
    audioData.vadPast.append(vadFrame)
    /// Updated by the sample size
    audioData.vadPastCount += 1
  }
  
  /// Method to determine if a clip point should be created based on sample passed and threshold
  private func shouldCreateClipPoint(prefLength: Bool, threshold: Int) -> Bool {
    return prefLength && audioData.silDurationAcc > threshold
  }
  
  /// Method to create a new clip point at the specified index
  private func createClipPoint(at index: Int) {
    /// Set last clip index to specified index
    audioData.lastClipIndex = index
    /// Append new clip point
    audioData.clipPoints.append(audioData.lastClipIndex)
  }
}
