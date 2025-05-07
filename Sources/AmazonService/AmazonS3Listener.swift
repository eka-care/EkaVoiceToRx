//
//  AmazonS3Listener.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Foundation
import AWSS3

/// A utility class to handle AWS S3 file operations such as checking existence and reading file content.
final class AWSS3Listener {
  
  init() {}
  
  /// Polls the `readTranscriptAndStructuredRx` function every 5 seconds until both transcript and structuredRx are available.
  ///
  /// - Parameters:
  ///   - sessionID: The UUID of the session to poll.
  ///   - timeout: Optional timeout duration in seconds. Default is 60 seconds.
  /// - Returns: A tuple with `transcript` and `structuredRx` once both are available, or `nil` if timeout occurs.
  func pollTranscriptAndRx(
    sessionID: UUID,
    timeout: TimeInterval = 60
  ) async throws -> (transcript: String, structuredRx: String)? {
    let startTime = Date()
    print("Poll transcript is called")
    while Date().timeIntervalSince(startTime) < timeout {
      if let result = try await readTranscriptAndStructuredRx(sessionID: sessionID),
         let transcript = result.transcript,
         let structuredRx = result.structuredRx {
        return (transcript, structuredRx)
      }
      
      try await Task.sleep(nanoseconds: 5 * 1_000_000_000) // 5 seconds
    }
    
    return nil // Timeout
  }
  
  /// Reads the transcript and structured Rx content for a given session ID from S3 if available.
  ///
  /// - Parameter sessionID: The UUID of the session.
  /// - Returns: A tuple containing optional transcript and structuredRx strings if found, or `nil` if neither file exists.
  /// - Throws: An error if reading or checking either file fails.
  func readTranscriptAndStructuredRx(sessionID: UUID) async throws -> (transcript: String?, structuredRx: String?)? {
    print("Read transcript is called")
    guard let model = await VoiceConversationAggregator.shared
      .fetchVoiceConversation(using: QueryHelper.queryForFetch(with: sessionID))
      .first else {
      return nil
    }
    
    let folderPath = VoiceConversationModel.getFolderPath(model: model)
    let transcriptPath = "\(folderPath)/clinical_notes_summary.md"
    let structuredRxPath = "\(folderPath)/structured_rx_codified.json"
    let bucket = RecordingS3UploadConfiguration.bucketName
    
    async let isTranscriptExist = checkS3FileExists(bucket: bucket, key: transcriptPath)
    async let isStructuredRxExist = checkS3FileExists(bucket: bucket, key: structuredRxPath)
    
    let (transcriptExists, structuredRxExists) = try await (isTranscriptExist, isStructuredRxExist)
    
    if !transcriptExists && !structuredRxExists {
      return nil
    }
    
    async let transcript: String? = transcriptExists
    ? readS3File(bucket: bucket, key: transcriptPath)
    : nil
    
    async let structuredRx: String? = structuredRxExists
    ? readS3File(bucket: bucket, key: structuredRxPath)
    : nil
    
    return try await (transcript: transcript, structuredRx: structuredRx)
  }
  
  /// Reads the contents of a file from S3 at the specified bucket and key.
  ///
  /// - Parameters:
  ///   - bucket: The S3 bucket name.
  ///   - key: The S3 key (path) of the file.
  /// - Returns: The file content as a string.
  /// - Throws: An error if the file cannot be read or decoded.
  private func readS3File(bucket: String, key: String) async throws -> String {
    print("Read s3 is called")
    let s3 = AWSS3.s3(forKey: RecordingS3UploadConfiguration.s3ClientKey)
    
    let request = AWSS3GetObjectRequest()!
    request.bucket = bucket
    request.key = key
    
    return try await withCheckedThrowingContinuation { continuation in
      s3.getObject(request).continueWith { task in
        if let error = task.error {
          continuation.resume(throwing: error)
        } else if let data = task.result?.body as? Data,
                  let content = String(data: data, encoding: .utf8) {
          continuation.resume(returning: content)
        } else {
          continuation.resume(throwing: NSError(domain: "S3", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or empty S3 file data"]))
        }
        return nil
      }
    }
  }
  
  /// Checks whether a file exists at the specified bucket and key in S3.
  ///
  /// - Parameters:
  ///   - bucket: The S3 bucket name.
  ///   - key: The S3 key (path) of the file.
  /// - Returns: A Boolean indicating whether the file exists.
  /// - Throws: An error if the S3 request fails (other than file-not-found).
  private func checkS3FileExists(bucket: String, key: String) async throws -> Bool {
    print("Check s3 files is called")
    let s3 = AWSS3.s3(forKey: RecordingS3UploadConfiguration.s3ClientKey)
    
    let request = AWSS3HeadObjectRequest()!
    request.bucket = bucket
    request.key = key
    
    return try await withCheckedThrowingContinuation { continuation in
      s3.headObject(request).continueWith { task in
        if let error = task.error as NSError? {
          if error.domain == AWSS3ErrorDomain && error.code == AWSS3ErrorType.noSuchKey.rawValue {
            continuation.resume(returning: false)
          } else {
            continuation.resume(throwing: false)
          }
        } else {
          continuation.resume(returning: true)
        }
        return nil
      }
    }
  }
}
