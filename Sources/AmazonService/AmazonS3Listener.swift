//
//  AmazonS3Listener.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Foundation
import AWSS3
import AWSClientRuntime

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
    guard let s3 = AWSConfiguration.shared.getS3Client() else {
      throw NSError(domain: "S3", code: -2, userInfo: [NSLocalizedDescriptionKey: "S3Client not configured"])
    }
    
    let input = GetObjectInput(bucket: bucket, key: key)
    let output = try await s3.getObject(input: input)
    
    guard let body = output.body else {
      throw NSError(domain: "S3", code: -3, userInfo: [NSLocalizedDescriptionKey: "Empty S3 file body"])
    }
    
    // Attempt to fully read body into Data and then String
    if let data = try await body.readData(),
       let content = String(data: data, encoding: .utf8) {
      return content
    }
    
    throw NSError(domain: "S3", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid or undecodable S3 file data"])
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
    guard let s3 = AWSConfiguration.shared.getS3Client() else {
      return false
    }
    
    do {
      let input = HeadObjectInput(bucket: bucket, key: key)
      _ = try await s3.headObject(input: input)
      return true
    } catch {
      // If the object doesn't exist or any error occurs, treat as not found for now
      return false
    }
  }
}
