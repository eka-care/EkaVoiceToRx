//
//  AmazonS3FileUploaderService.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import AWSS3

enum RecordingS3UploadConfiguration {
  static let bucketName = "m-prod-voice2rx"
  static let domain = "s3://"
  
  static func getDateFolderName() -> String {
    return Date().toString(withFormat: "yyMMdd")
  }
}

final class AmazonS3FileUploaderService {
  
  // MARK: - Properties
  
  let transferUtility = AWSS3TransferUtility.default()
  let domainName = RecordingS3UploadConfiguration.domain
  let bucketName = RecordingS3UploadConfiguration.bucketName
  let dateFolderName = RecordingS3UploadConfiguration.getDateFolderName()
  
  func uploadFileWithRetry(
    url: URL,
    key: String,
    retryCount: Int = 3,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    // Make content type
    var contentType = ""
    let lastPathComponent = url.lastPathComponent
    debugPrint("S3 content type Last path component: \(lastPathComponent)")
    
    if lastPathComponent.hasSuffix(".m4a") || lastPathComponent.hasSuffix(".m4a_") {
      contentType = "audio/wav"
    } else if lastPathComponent.hasSuffix(".json") {
      contentType = "application/json"
    } else {
      // Handle other file types or set a default content type
      contentType = "application/json"
    }
    debugPrint("S3 content type Content type: \(contentType)")
    
    uploadFile(url: url, key: key, contentType: contentType) { [weak self] result in
      guard let self else { return }
      
      switch result {
      case .success(let fileUploadedKey):
        debugPrint("Successfully uploaded hence removing file at url \(url)")
        if url.lastPathComponent != "full_audio.m4a_" { /// If its full audio don't remove
          /// Remove file once uploaded
          FileHelper.removeFile(at: url)
        }
        completion(.success(fileUploadedKey))
      case .failure(let error):
        if retryCount > 0 {
          let retryDelay = DispatchTime.now() + 2.0 // 2 seconds backoff time
          DispatchQueue.global().asyncAfter(deadline: retryDelay) {
            debugPrint("Retrying upload (\(retryCount) retries left)...")
            self.uploadFileWithRetry(url: url, key: key, retryCount: retryCount - 1, completion: completion)
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
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    debugPrint("Key is \(key)")
    transferUtility.uploadFile(url, bucket: bucketName, key: key, contentType: contentType, expression: nil) { task, error in
      if let error {
        debugPrint("Error is -> \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
      
      completion(.success(key))
    }
  }
}
