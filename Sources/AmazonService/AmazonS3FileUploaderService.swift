//
//  AmazonS3FileUploaderService.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import AWSS3

final class AmazonS3FileUploaderService {
  
  // MARK: - Properties
  
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
    
    let delay = key.contains("full_audio") ? 1.0 : 0.0
    
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self = self else {
        completion(.failure(NSError(domain: "S3Upload", code: -999, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
        return
      }
      self.uploadFile(url: url, key: key, contentType: contentType, sessionID: sessionID, bid: bid) { [weak self] result in
      print("#BB inside uploadfileWithRetry")
      guard let self else { return }
      print("#BB giving out completion")
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
  }
  
//  private func uploadFile(
//    url: URL,
//    key: String,
//    contentType: String = "audio/wav",
//    retryCount: Int = 3,
//    sessionID: String?,
//    bid: String?,
//    completion: @escaping (Result<String, Error>) -> Void
//  ) {
//    debugPrint("Key is \(key)")
//    guard let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: RecordingS3UploadConfiguration.transferUtilKey) else {
//      print("Transfer Utility could not be formed")
//      let error = NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer Utility could not be formed"])
//      completion(.failure(error))
//      return
//    }
//    
//    // 1. Ensure file is readable
//    guard FileManager.default.isReadableFile(atPath: url.path) else {
//      print("File not readable at path: \(url.path)")
//      let error = NSError(domain: "S3Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "File not readable at path: \(url.path)"])
//      completion(.failure(error))
//      return
//    }
//    
//    let expression = AWSS3TransferUtilityUploadExpression()
//    
//    // Add comprehensive metadata only if values are not nil
//    if let bid = bid {
//      expression.setValue(bid, forRequestHeader: "x-amz-meta-bid")
//    }
//    if let sessionID = sessionID {
//      expression.setValue(sessionID, forRequestHeader: "x-amz-meta-txnid")
//    }
//    
//    debugPrint(
//      "Upload information url -> \(url), bucket: \(bucketName), key: \(key), contentType: \(contentType), expression: \(expression)"
//    )
//    
//    let uploadTask = transferUtility.uploadFile(
//      url,
//      bucket: bucketName,
//      key: key,
//      contentType: contentType,
//      expression: expression
//    ) { task, error in
//      if let error {
//        debugPrint("Upload completion handler error: \(error.localizedDescription)")
//        completion(.failure(error))
//        return
//      }
//      
//      debugPrint("Upload completion handler success for key: \(key)")
//      completion(.success(key))
//    }
//    
//    uploadTask.continueWith { t in
//      if let error = t.error {
//        debugPrint("Upload task creation failed: \(error.localizedDescription)")
//        completion(.failure(error))
//      } else if let result = t.result {
//        debugPrint("Upload task status: \(result.status.rawValue)")
//      }
//      return nil
//    }
//  }
  
  private func uploadFile(
    url: URL,
    key: String,
    contentType: String = "audio/wav",
    retryCount: Int = 3,
    sessionID: String?,
    bid: String?,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    debugPrint("v2rx🔵 ENTER uploadFile for key: \(key)")
    debugPrint("v2rx🔵 File URL: \(url)")
    debugPrint("v2rx🔵 Thread: \(Thread.current)")
    
    guard let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: RecordingS3UploadConfiguration.transferUtilKey) else {
      debugPrint("v2rx❌ Transfer Utility could not be formed")
      let error = NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer Utility could not be formed"])
      completion(.failure(error))
      return
    }
    debugPrint("v2rx✅ Transfer Utility created successfully")
    
    // 1. Ensure file is readable
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      debugPrint("v2rx❌ File not readable at path: \(url.path)")
      let error = NSError(domain: "S3Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "File not readable at path: \(url.path)"])
      completion(.failure(error))
      return
    }
    debugPrint("v2rx✅ File is readable")
    
    // Check file size
    do {
      let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
      debugPrint("v2rx📊 File size: \(fileSize) bytes")
    } catch {
      debugPrint("v2rx⚠️ Could not get file size: \(error)")
    }
    
    let expression = AWSS3TransferUtilityUploadExpression()
    
    // Add comprehensive metadata only if values are not nil
    if let bid = bid {
      expression.setValue(bid, forRequestHeader: "x-amz-meta-bid")
    }
    if let sessionID = sessionID {
      expression.setValue(sessionID, forRequestHeader: "x-amz-meta-txnid")
    }
    
    debugPrint("v2rx🔵 About to call transferUtility.uploadFile")
    debugPrint("v2rx🔵 Bucket: \(bucketName), Key: \(key), ContentType: \(contentType)")
    
    let uploadTask = transferUtility.uploadFile(
      url,
      bucket: bucketName,
      key: key,
      contentType: contentType,
      expression: expression
    ) { task, error in
      debugPrint("v2rx🟡 UPLOAD COMPLETION HANDLER CALLED")
      debugPrint("v2rx🟡 Thread: \(Thread.current)")
      debugPrint("v2rx🟡 Task: \(String(describing: task))")
      debugPrint("v2rx🟡 Error: \(String(describing: error))")
      
      if let error {
        debugPrint("v2rx❌ Upload completion handler error: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
      
      debugPrint("v2rx✅ Upload completion handler success for key: \(key)")
      completion(.success(key))
    }
    
    debugPrint("v2rx🔵 Upload task created: \(String(describing: uploadTask))")
    
    uploadTask.continueWith { t in
      debugPrint("v2rx🟡 CONTINUE WITH BLOCK CALLED")
      debugPrint("v2rx🟡 Thread: \(Thread.current)")
      debugPrint("v2rx🟡 Task error: \(String(describing: t.error))")
      debugPrint("v2rx🟡 Task result: \(String(describing: t.result))")
      
      if let error = t.error {
        debugPrint("v2rx❌ Upload task creation failed: \(error.localizedDescription)")
        completion(.failure(error))
      } else if let result = t.result {
        debugPrint("v2rx✅ Upload task status: \(result.status.rawValue)")
        debugPrint("v2rx✅ Upload task: \(result)")
      }
      return nil
    }
    
    debugPrint("v2rx🔵 EXIT uploadFile for key: \(key)")
  }
}
