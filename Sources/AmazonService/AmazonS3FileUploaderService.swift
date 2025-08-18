//
//  AmazonS3FileUploaderService.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import AWSS3

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
    debugPrint("Key is \(key)")
    
    // ✅ Use dynamic active key instead of static key
    guard let transferUtility = AWSConfiguration.shared.getTransferUtility() else {
      let error = NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active AWS Transfer Utility"])
      completion(.failure(error))
      return
    }
    
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      let error = NSError(domain: "S3Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "File not readable at path: \(url.path)"])
      completion(.failure(error))
      return
    }
    
    let expression = AWSS3TransferUtilityUploadExpression()
    
    if let bid = bid {
      expression.setValue(bid, forRequestHeader: "x-amz-meta-bid")
    }
    if let sessionID = sessionID {
      expression.setValue(sessionID, forRequestHeader: "x-amz-meta-txnid")
    }
    
    debugPrint("Upload information url -> \(url), bucket: \(bucketName), key: \(key), contentType: \(contentType)")
    
    let uploadTask = transferUtility.uploadFile(
      url,
      bucket: bucketName,
      key: key,
      contentType: contentType,
      expression: expression
    ) { task, error in
      if let error {
        debugPrint("Upload completion handler error: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
      debugPrint("Upload completion handler success for key: \(key)")
      completion(.success(key))
    }
    
    uploadTask.continueWith { t in
      if let error = t.error {
        debugPrint("Upload task creation failed: \(error.localizedDescription)")
        completion(.failure(error))
      } else if let result = t.result {
        debugPrint("Upload task status: \(result.status.rawValue)")
      }
      return nil
    }
  }
}
