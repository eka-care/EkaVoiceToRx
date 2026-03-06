//
//  AmazonS3FileUploaderService.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import AWSS3
import Foundation
import AWSClientRuntime
import enum Smithy.ByteStream

final class AmazonS3FileUploaderService {
  
  let domainName = RecordingS3UploadConfiguration.domain
  let bucketName = RecordingS3UploadConfiguration.bucketName
  let dateFolderName = RecordingS3UploadConfiguration.getDateFolderName()
  
  func uploadFileWithRetry(
    url: URL,
    key: String,
    retryCount: Int = 3,
    sessionID: String?,
    bid: String?,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    var contentType = ""
    let lastPathComponent = url.lastPathComponent
    debugPrint("S3 content type Last path component: \(lastPathComponent)")
    
    if lastPathComponent.hasSuffix(".m4a") || lastPathComponent.hasSuffix(".m4a_") {
      contentType = "audio/wav"
    } else if lastPathComponent.hasSuffix(".json") {
      contentType = "application/json"
    } else {
      contentType = "application/json"
    }
    debugPrint("S3 content type Content type: \(contentType)")
    
    uploadFile(url: url, key: key, contentType: contentType, sessionID: sessionID, bid: bid) { [weak self] result in
      guard let self else { return }
      switch result {
      case .success(let fileUploadedKey):
        debugPrint("Successfully uploaded hence removing file at url \(url)")
        if url.lastPathComponent != "full_audio.m4a_" {
          FileHelper.removeFile(at: url)
        }
        completion(.success(fileUploadedKey))
      case .failure(let error):
        if retryCount > 0 {
          let retryDelay = DispatchTime.now() + 2.0
          DispatchQueue.global().asyncAfter(deadline: retryDelay) {
            debugPrint("Retrying upload (\(retryCount) retries left)...")
            self.uploadFileWithRetry(
              url: url,
              key: key,
              retryCount: retryCount - 1,
              sessionID: sessionID,
              bid: bid,
              completion: completion
            )
          }
        } else {
          completion(.failure(error))
        }
      }
    }
  }
  
  private func uploadFile(
    url: URL,
    key: String,
    contentType: String = "audio/wav",
    retryCount: Int = 3,
    sessionID: String?,
    bid: String?,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    print("Key is \(key)")
    
    guard let s3Client = AWSConfiguration.shared.getS3Client() else {
      let error = NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "S3Client not configured"])
      completion(.failure(error))
      return
    }
    
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      let error = NSError(domain: "S3Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "File not readable at path: \(url.path)"])
      completion(.failure(error))
      return
    }
    
    var metadata: [String: String]? = nil
    if bid != nil || sessionID != nil {
      var meta: [String: String] = [:]
      if let bid { meta["bid"] = bid }
      if let sessionID { meta["txnid"] = sessionID }
      metadata = meta
    }
    
    print("Upload information url -> \(url), bucket: \(bucketName), key: \(key), contentType: \(contentType)")
    
    Task {
      do {
        let body = try ByteStream.from(fileHandle: .init(forReadingFrom: url))
        let input = PutObjectInput(
          body: body,
          bucket: bucketName,
          contentType: contentType,
          key: key,
          metadata: metadata
        )
        _ = try await s3Client.putObject(input: input)
        debugPrint("Upload success for key: \(key)")
        completion(.success(key))
      } catch {
        debugPrint("Upload failed: \(error.localizedDescription)")
        completion(.failure(error))
      }
    }
  }
}
