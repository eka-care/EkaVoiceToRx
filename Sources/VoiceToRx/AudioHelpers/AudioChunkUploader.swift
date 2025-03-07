//
//  AudioChunkUploader.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 13/08/24.
//

import AVFoundation

protocol AudioChunkUploaderDelegate: AnyObject {
  func fileUploadMapperDidChange(_ updatedMap: [String])
}

final class AudioChunkUploader {
  
  let s3FileUploaderService: AmazonS3FileUploaderService
  let audioFormat: AVAudioCommonFormat = .pcmFormatInt16
  var audioBufferToM4AConverter = AudioBufferToM4AConverter()
  /// Array of files that are in queue for upload
  var fileUploadMapper: [String] = [] {
    didSet {
      /// Listen this in the caller
      delegate?.fileUploadMapperDidChange(fileUploadMapper)
    }
  }
  let fullAudioFileKey = "full_audio"
  let channelCount: Int = 1
  var fileChunksInfo: [String: FileChunkInfo] = [:]
  var uploadedFileKeys: [String] = []
  weak var delegate: AudioChunkUploaderDelegate?
  
  init(
    delegate: AudioChunkUploaderDelegate?,
    s3FileUploaderService: AmazonS3FileUploaderService
  ) {
    self.delegate = delegate
    self.s3FileUploaderService = s3FileUploaderService
  }
  
  func reset() {
    fileUploadMapper = []
    fileChunksInfo = [:]
    uploadedFileKeys = []
    audioBufferToM4AConverter = AudioBufferToM4AConverter()
  }
  
  func uploadChunkToS3(
    startingFrame: Int,
    endingFrame: Int,
    chunkIndex: Int,
    sessionId: String,
    audioBuffer: UnsafeBufferPointer<Int16>,
    completion: @escaping () -> Void
  ) {
    let currentSegment = audioBuffer.baseAddress! + startingFrame
    let segmentLength = endingFrame - startingFrame
    guard let singleBuffer = AudioHelper.shared.createBuffer(
      from: currentSegment,
      format: audioFormat,
      frameCount: AVAudioFrameCount(segmentLength),
      channels: AVAudioChannelCount(channelCount),
      sampleRate: Double(RecordingConfiguration.shared.requiredSampleRate)
    ) else { return }
    guard startingFrame < endingFrame else { return }
    fileUploadMapper.append(String(chunkIndex))
    let fileChunkName = "\(String(chunkIndex))\(AudioFileFormat.m4aFile.extensionString)"
    uploadedFileKeys.append(fileChunkName)
    /// Add the key into the upload checker array
    fileChunksInfo[fileChunkName] = getFileChunkInfo(
      startIndex: startingFrame,
      endIndex: endingFrame
    )
    debugPrint("Starting frame is \(startingFrame) and Ending frame is \(endingFrame)")
    audioBufferToM4AConverter.writePCMBufferToM4A(
      pcmBuffer: singleBuffer,
      fileKey: String(chunkIndex),
      sessionId: sessionId
    ) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .success(let fileURL):
        let firstFolder: String = s3FileUploaderService.dateFolderName
        let secondFolder = sessionId
        let lastPathComponent = fileURL.lastPathComponent
        let key = "\(firstFolder)/\(secondFolder)/\(lastPathComponent)"
        s3FileUploaderService.uploadFileWithRetry(url: fileURL, key: key) { [weak self] result in
          guard let self = self else { return }
          switch result {
          case .success:
            updateUploadSuccessMap(chunkIndex: String(chunkIndex))
            debugPrint("Successfully uploaded file")
            completion()
          case .failure(let error):
            debugPrint("Failed uploading with error -> \(error.localizedDescription)")
          }
        }
      case .failure(let error):
        debugPrint("Error in converting file to m4a with error -> \(error.localizedDescription)")
      }
    }
  }
  
  private func getFileChunkInfo(
    startIndex: Int,
    endIndex: Int
  ) -> FileChunkInfo {
    FileChunkInfo(
      startingTime: AudioHelper.shared.formTimeFromAudioIndex(index: startIndex),
      endingTime: AudioHelper.shared.formTimeFromAudioIndex(index: endIndex)
    )
  }
  
  private func updateUploadSuccessMap(chunkIndex: String) {
    /// Remove the key from checker array
    if let indexOfKey = fileUploadMapper.firstIndex(where: { $0 == chunkIndex }) {
      fileUploadMapper.remove(at: indexOfKey)
    }
    debugPrint("Updated Upload success map is -> \(fileUploadMapper)")
  }
  
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
      audioBufferToM4AConverter.writePCMBufferToM4A(
        pcmBuffer: audioBuffer,
        fileKey: fullAudioFileKey,
        sessionId: sessionID.uuidString,
        fileExtension: ".m4a_"
      ) { [weak self] result in
        guard let self = self else { return }
        switch result {
        case .success(let fileURL):
          Task { [weak self] in
            guard let self else { return }
            /// Add full audio to database
            await VoiceConversationAggregator.shared.updateVoice(id: sessionID, fileURL: fileURL)
            /// Upload full audio to S3
            let firstFolder: String = s3FileUploaderService.dateFolderName
            let secondFolder = sessionID
            let key = "\(firstFolder)/\(secondFolder)/\(fileURL.lastPathComponent)"
            s3FileUploaderService.uploadFileWithRetry(url: fileURL, key: key) { result in
              switch result {
              case .success:
                debugPrint("Successfully uploaded full audio file")
              case .failure(let error):
                debugPrint("Failed uploading with error -> \(error.localizedDescription)")
              }
            }
          }
        case .failure(let error):
          debugPrint("Error in converting file to m4a with error -> \(error.localizedDescription)")
        }
      }
    }
  }
}

