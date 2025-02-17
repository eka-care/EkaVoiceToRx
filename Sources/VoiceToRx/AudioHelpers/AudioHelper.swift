//
//  AudioHelper.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 18/09/24.
//

import AVFoundation

final class AudioHelper {
  
  static let shared = AudioHelper()
  
  /// Create array from raw buffer of samples
  func createBuffer(
    from samples: UnsafePointer<Int16>,
    format: AVAudioCommonFormat,
    frameCount: AVAudioFrameCount,
    channels: AVAudioChannelCount,
    sampleRate: Double
  ) -> AVAudioPCMBuffer? {
    // Create an audio format for the buffer (int 16-bit)
    let audioFormat = AVAudioFormat(commonFormat: format, sampleRate: sampleRate, channels: channels, interleaved: false)
    
    // Ensure the format is valid
    guard let format = audioFormat else { return nil }
    
    // Create the AVAudioPCMBuffer with the format and frame capacity
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
    
    // Set the frameLength of the buffer
    buffer.frameLength = frameCount
    
    // Copy the samples into the buffer's channel data
    if let channelData = buffer.int16ChannelData {
      for channel in 0..<Int(channels) {
        // Copy the sample data into the buffer's channel
        memcpy(channelData[channel], samples, Int(frameCount) * MemoryLayout<Int16>.size)
      }
    }
    
    return buffer
  }
  
  /// Convert Buffer Object to raw pointer
  func convertBufferToRawUnsafePointer(buffer: AVAudioPCMBuffer) -> UnsafeRawBufferPointer? {
    guard let int16ChannelData = buffer.int16ChannelData else { return nil }
    /// Get the pointer to the first channel's data
    let numFrames = Int(buffer.frameLength)
    let numChannels = Int(buffer.format.channelCount)
    let dataSize = numFrames * numChannels * MemoryLayout<Int16>.size
    
    /// Convert to UnsafeRawBufferPointer for the first channel data
    let rawPointer = UnsafeRawBufferPointer(start: UnsafeRawPointer(int16ChannelData[0]), count: dataSize)
    return rawPointer
  }
  
  /// Downsample
  func downSample(
    toSampleRate: Double,
    buffer: AVAudioPCMBuffer,
    inputNodeOutputFormat: AVAudioFormat
  ) -> AVAudioPCMBuffer? {
    guard let requiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                             sampleRate: toSampleRate,
                                             channels: 1,
                                             interleaved: false) else { return nil }
    
    let formatConverter = AVAudioConverter(from: inputNodeOutputFormat, to: requiredFormat)
    
    let pcmBufferFrameLength = AVAudioFrameCount(toSampleRate / 10)
    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: requiredFormat, frameCapacity: pcmBufferFrameLength) else { return nil }
    
    var error: NSError? = nil
    let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
      outStatus.pointee = AVAudioConverterInputStatus.haveData
      return buffer
    }
    
    formatConverter?.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)
    return pcmBuffer
  }
  
  /// Assuming start time at index 0
  func formTimeFromAudioIndex(index: Int) -> String {
    let startIndex: Int = 0
    let samples = (index - startIndex)
    let time: Float = Float(Float(samples) / Float(RecordingConfiguration.shared.requiredSampleRate)) /// in sec
    return String(time)
  }
}
