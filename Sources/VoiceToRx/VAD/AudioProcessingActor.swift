//
//  AudioProcessingActor.swift
//  EkaVoiceToRx
//
//  Created to fix concurrent mutation issues in audio processing
//

import Foundation
import AVFoundation

/// Actor to serialize audio chunk processing and prevent concurrent mutations
actor AudioProcessingActor {
  
  // MARK: - Properties
  
  private var pcmBuffersListRaw: [Int16] = []
  private var lastClipIndex: Int = 0
  private var chunkIndex: Int = 1
  private let vadAudioChunker: VADAudioChunker
  
  // MARK: - Initialization
  
  init() {
    self.pcmBuffersListRaw = []
    self.lastClipIndex = 0
    self.chunkIndex = 1
    self.vadAudioChunker = VADAudioChunker()
  }
  
  // MARK: - State Management
  
  func reset() {
    pcmBuffersListRaw = []
    lastClipIndex = 0
    chunkIndex = 1
    vadAudioChunker.reset()
  }
  
  // MARK: - Audio Processing
  
  /// Process audio chunk with serialized access to shared state
  /// This ensures only one task processes audio at a time, preventing race conditions
  func processAudioChunk(
    audioEngine: AVAudioEngine,
    buffer: AVAudioPCMBuffer?,
    sessionID: UUID,
    audioChunkProcessor: AudioChunkProcessor,
    audioChunkUploader: AudioChunkUploader,
    onAmplitudeUpdate: ((Float) -> Void)?
  ) async throws {
    // Create mutable copies of state for processing
    var mutableLastClipIndex = lastClipIndex
    var mutableChunkIndex = chunkIndex
    var mutablePcmBufferListRaw = pcmBuffersListRaw
    
    // Process the audio chunk - this will modify the mutable copies
    try await audioChunkProcessor.processAudioChunk(
      audioEngine: audioEngine,
      buffer: buffer,
      vadAudioChunker: vadAudioChunker,
      sessionID: sessionID,
      lastClipIndex: &mutableLastClipIndex,
      chunkIndex: &mutableChunkIndex,
      audioChunkUploader: audioChunkUploader,
      pcmBufferListRaw: &mutablePcmBufferListRaw,
      onAmplitudeUpdate: onAmplitudeUpdate
    )
    
    // Update state atomically after processing
    pcmBuffersListRaw = mutablePcmBufferListRaw
    lastClipIndex = mutableLastClipIndex
    chunkIndex = mutableChunkIndex
  }
  
  /// Get the current PCM buffer for full audio upload
  func getPcmBuffersListRaw() -> [Int16] {
    return pcmBuffersListRaw
  }
}
