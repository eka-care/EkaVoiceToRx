//
//  VADProcessingManager.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 06/08/24.
//

import libfvad
import Foundation
import AVFoundation

final class AudioChunkProcessor {
  
  private let vadDetector = VoiceActivityDetector()
  
  init() {
    setVadDetectorSampleRate()
  }
  
  func setVadDetectorSampleRate() {
    do {
      try vadDetector.setSampleRate(sampleRate: RecordingConfiguration.shared.requiredSampleRate)
    } catch {
      print("Error in setting up vad detector")
    }
  }
  
  func processAudioChunk(
    audioEngine: AVAudioEngine,
    buffer: AVAudioPCMBuffer? = nil,
    vadAudioChunker: VADAudioChunker,
    sessionID: UUID,
    lastClipIndex: inout Int,
    chunkIndex: inout Int,
    audioChunkUploader: AudioChunkUploader,
    pcmBufferListRaw: inout [Int16]
  ) {
    var bufferPointer: UnsafeRawBufferPointer?
    /// If audio engine is running, continue forming buffer pointer
    if audioEngine.isRunning, let buffer {
      bufferPointer = AudioHelper.shared.convertBufferToRawUnsafePointer(buffer: buffer)
    } else { /// If audio engine is not running, buffer pointer will be nil
      bufferPointer = nil
    }
    
    let startIndex = lastClipIndex
    var endIndex = pcmBufferListRaw.count - 1
    var isClipFrame = false
    
    if let bufferPointer {
      let p = bufferPointer.assumingMemoryBound(to: Int16.self)
      
      let chunkSize: Int = RecordingConfiguration.shared.sizedDownMinimumBufferSize
      let numberOfChunks: Int = RecordingConfiguration.shared.requiredAudioCaptureMinimumBufferSize / RecordingConfiguration.shared.sizedDownMinimumBufferSize
      
      /// Break down buffer of 100ms into smaller buffer of 20ms each for processing vad
      for i in 0..<numberOfChunks {
        let newPointer = p.baseAddress! + chunkSize*i
        if let voiceActivityValue = processAudioWithVad(
          bufferPointer: newPointer,
          length: chunkSize
        )?.rawValue {
          let (clipDecision, clipPointIndex) = vadAudioChunker.process(vadFrame: Int(voiceActivityValue))
          if clipDecision {
            endIndex = clipPointIndex*chunkSize
            isClipFrame = true /// Frame is to be clipped here as clip decision is true
          }
        }
        pcmBufferListRaw.append(contentsOf: Array(UnsafeBufferPointer(start: newPointer, count: chunkSize)))
      }
    } else {
      isClipFrame = true /// Frame is to be clipped as this would be the last clipping
    }
    
    pcmBufferListRaw.withUnsafeBufferPointer { pointerAudioBuffer in
      // Chunking and uploading to S3
      if isClipFrame && (endIndex>0) {
        audioChunkUploader.createChunkM4AFileAndUploadToS3(
          startingFrame: startIndex,
          endingFrame: endIndex,
          chunkIndex: chunkIndex,
          sessionId: sessionID,
          audioBuffer: pointerAudioBuffer
        )
        
        lastClipIndex = endIndex
        chunkIndex += 1
      }
    }
  }
  
  func processAudioWithVad(
    bufferPointer: UnsafePointer<Int16>?,
    length: Int = 320
  ) -> VadVoiceActivity? {
    guard let bufferPointer else { return nil }
    do {
      let activity = try vadDetector.process(frame: bufferPointer, length: length)
      return activity
    } catch {
      debugPrint("Error process audio with vad")
    }
    return nil
  }
}
