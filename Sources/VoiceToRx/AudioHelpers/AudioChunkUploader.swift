//
//  AudioChunkUploader.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 13/08/24.
//

import AVFoundation

final class AudioChunkUploader {
  
  let s3FileUploaderService: AmazonS3FileUploaderService
  let audioFormat: AVAudioCommonFormat = .pcmFormatInt16
  var audioBufferToM4AConverter = AudioBufferToM4AConverter()
  let fullAudioFileKey = "full_audio"
  let channelCount: Int = 1
  let voiceToRxRepo: VoiceToRxRepo
  var uploadedFileKeys: [String] = []
  
  init(
    s3FileUploaderService: AmazonS3FileUploaderService,
    voiceToRxRepo: VoiceToRxRepo
  ) {
    self.s3FileUploaderService = s3FileUploaderService
    self.voiceToRxRepo = voiceToRxRepo
  }
  
  func reset() {
    uploadedFileKeys = []
    audioBufferToM4AConverter = AudioBufferToM4AConverter()
  }
  
  func createChunkM4AFileAndUploadToS3(
    startingFrame: Int,
    endingFrame: Int,
    chunkIndex: Int,
    sessionId: UUID,
    audioBuffer: [Int16]
  ) async throws {
    // Validate frame indices
    guard startingFrame < endingFrame && startingFrame >= 0 && endingFrame <= audioBuffer.count else {
      return
    }
    
    // Extract the segment from the audio buffer
    let segmentLength = endingFrame - startingFrame
    let audioSegment = Array(audioBuffer[startingFrame..<endingFrame])
    
    /// Used to create a single buffer out of the segment
    guard let singleBuffer = AudioHelper.shared.createBuffer(
      from: audioSegment,
      format: audioFormat,
      frameCount: AVAudioFrameCount(segmentLength),
      channels: AVAudioChannelCount(channelCount),
      sampleRate: Double(RecordingConfiguration.shared.requiredSampleRate)
    ) else { return }
    
    /// Get Chunk Info
    guard startingFrame < endingFrame else { return }
    let fileChunkName = "\(String(chunkIndex))\(AudioFileFormat.m4aFile.extensionString)"
    uploadedFileKeys.append(fileChunkName)
    let fileChunkInfo = getFileChunkInfo(
      startIndex: startingFrame,
      endIndex: endingFrame
    )
    debugPrint("#BB Starting frame is \(startingFrame) and Ending frame is \(endingFrame)")
    
    /// Create chunk
    let m4aUrl = try await audioBufferToM4AConverter.writePCMBufferToM4A(
      pcmBuffer: singleBuffer,
      fileKey: String(chunkIndex),
      sessionId: sessionId.uuidString
    )
    
    /// Update chunk info in database with initial values.
    /// Note: - Here we don't pass isFileUploaded as it has not been uploaded yet
    updateChunkInfoInDatabse(
      sessionId: sessionId,
      fileName: m4aUrl.lastPathComponent,
      fileURL: m4aUrl.pathComponents.suffix(2).joined(separator: "/"),
      chunkInfo: fileChunkInfo
    )
    
    print("#BB upload chunk to s3 is getting called")
    /// Upload Chunk to s3
    uploadChunkToS3(
      sessionId: sessionId.uuidString,
      fileURL: m4aUrl,
      lastPathComponent: m4aUrl.lastPathComponent
    ) { [weak self] in
      guard let self else { return }
      /// Update chunk info to make uploaded true
      updateChunkInfoInDatabse(
        sessionId: sessionId,
        fileName: m4aUrl.lastPathComponent,
        fileURL: m4aUrl.pathComponents.suffix(2).joined(separator: "/"),
        chunkInfo: fileChunkInfo,
        isFileUploaded: true
      )
    }
    
    print("#BB upload chunk to s3 finished")
  }
  
  private func uploadChunkToS3(
    sessionId: String,
    fileURL: URL,
    lastPathComponent: String,
    completion: @escaping () -> Void
  ) {
    print("#BB inside uploadChunkToS3 function")
    let firstFolder: String = s3FileUploaderService.dateFolderName
    let secondFolder = sessionId
    let lastPathComponent = fileURL.lastPathComponent
    let key = "\(firstFolder)/\(secondFolder)/\(lastPathComponent)"
    s3FileUploaderService.uploadFileWithRetry(
      url: fileURL,
      key: key,
      sessionID: sessionId,
      bid: AuthTokenHolder.shared.bid
    ) { result in
      switch result {
      case .success:
        debugPrint("#BB Successfully uploaded file")
        completion()
      case .failure(let error):
        debugPrint("#BB Failed uploading with error -> \(error.localizedDescription)")
      }
    }
  }
  
  /// Used to update chunk info in database
  /// - Parameters:
  ///   - sessionId: session id of the chunk that has been created
  ///   - fileName: file name of the chunk like "1.m4a"
  ///   - fileURL: file url of the chunk
  ///   - fileChunkInfo: file chunk info
  ///   - isFileUploaded: tells wether file has been uploaded or not
  private func updateChunkInfoInDatabse(
    sessionId: UUID,
    fileName: String,
    fileURL: String,
    chunkInfo: ChunkInfo,
    isFileUploaded: Bool = false
  ) {
    print("session id \(sessionId.uuidString) chunk index \(fileName) marked as \(isFileUploaded)")
    voiceToRxRepo.updateVoiceToRxChunkInfo(
      sessionID: sessionId,
      chunkInfo: VoiceChunkInfoArguementModel(
        startTime: chunkInfo.st,
        endTime: chunkInfo.et,
        fileURL: fileURL,
        fileName: fileName,
        isFileUploaded: isFileUploaded
      )
    )
  }
  
  private func getFileChunkInfo(
    startIndex: Int,
    endIndex: Int
  ) -> ChunkInfo {
    ChunkInfo(
      st: AudioHelper.shared.formTimeFromAudioIndex(index: startIndex),
      et: AudioHelper.shared.formTimeFromAudioIndex(index: endIndex)
    )
  }
  
  // MARK: - Full Audio
  
  func uploadFullAudio(
    pcmBufferListRaw: [Int16],
    sessionID: UUID
  ) {
    pcmBufferListRaw.withUnsafeBufferPointer { audioBufferPointer in
      guard let audioBuffer = AudioHelper.shared.createBuffer(
        from: audioBufferPointer.baseAddress!,
        format: audioFormat,
        frameCount: AVAudioFrameCount(pcmBufferListRaw.count),
        channels: AVAudioChannelCount(channelCount),
        sampleRate: Double(RecordingConfiguration.shared.requiredSampleRate)
      ) else { return }
      Task {
        let m4aURL = try await audioBufferToM4AConverter.writePCMBufferToM4A(
          pcmBuffer: audioBuffer,
          fileKey: fullAudioFileKey,
          sessionId: sessionID.uuidString,
          isFullAudio: true,
          fileExtension: ".m4a_"
        )
        uploadChunkToS3(
          sessionId: sessionID.uuidString,
          fileURL: m4aURL,
          lastPathComponent: m4aURL.lastPathComponent
        ) {}
      }
    }
  }
}

