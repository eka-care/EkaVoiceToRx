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
  
  // Sequential processing
  private let processingQueue = DispatchQueue(label: "s3.processing.queue", qos: .utility)
  private var isProcessing = false
  private var pendingUploads: [(url: URL, key: String, sessionID: String?, bid: String?, completion: (Result<String, Error>) -> Void)] = []
  
  func uploadFileWithRetry(
    url: URL,
    key: String,
    retryCount: Int = 3,
    sessionID: String?,
    bid: String?,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    processingQueue.async { [weak self] in
      guard let self = self else {
        completion(.failure(NSError(domain: "S3Upload", code: -999, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
        return
      }
      
      // Add to queue
      self.pendingUploads.append((url: url, key: key, sessionID: sessionID, bid: bid, completion: completion))
      debugPrint("v2rx 📝 Added upload to queue. Queue size: \(self.pendingUploads.count)")
      
      // Start processing if not already processing
      if !self.isProcessing {
        self.processNextUpload()
      }
    }
  }
  
  private func processNextUpload() {
    processingQueue.async { [weak self] in
      guard let self = self,
            !self.pendingUploads.isEmpty else {
        self?.isProcessing = false
        debugPrint("v2rx ✅ Upload queue empty, stopping processing")
        return
      }
      
      self.isProcessing = true
      let uploadItem = self.pendingUploads.removeFirst()
      
      debugPrint("v2rx 🚀 Processing upload: \(uploadItem.key)")
      
      // Make content type
      var contentType = ""
      let lastPathComponent = uploadItem.url.lastPathComponent
      
      if lastPathComponent.hasSuffix(".m4a") || lastPathComponent.hasSuffix(".m4a_") {
        contentType = "audio/wav"
      } else if lastPathComponent.hasSuffix(".json") {
        contentType = "application/json"
      } else {
        contentType = "application/json"
      }
      
      self.performSingleUpload(
        url: uploadItem.url,
        key: uploadItem.key,
        contentType: contentType,
        sessionID: uploadItem.sessionID,
        bid: uploadItem.bid,
        retryCount: 3
      ) { [weak self] result in
        // Call the original completion handler
        uploadItem.completion(result)
        
        // Process next upload after a small delay to prevent overwhelming the service
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
          self?.processNextUpload()
        }
      }
    }
  }
  
  private func performSingleUpload(
    url: URL,
    key: String,
    contentType: String,
    sessionID: String?,
    bid: String?,
    retryCount: Int,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    uploadFile(url: url, key: key, contentType: contentType, sessionID: sessionID, bid: bid) { [weak self] result in
      switch result {
      case .success(let fileUploadedKey):
        debugPrint("v2rx ✅ Successfully uploaded: \(fileUploadedKey)")
        if url.lastPathComponent != "full_audio.m4a_" {
          FileHelper.removeFile(at: url)
        }
        completion(.success(fileUploadedKey))
        
      case .failure(let error):
        if retryCount > 0 {
          debugPrint("v2rx 🔄 Retrying upload (\(retryCount) retries left) for: \(key)")
          DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            self?.performSingleUpload(
              url: url,
              key: key,
              contentType: contentType,
              sessionID: sessionID,
              bid: bid,
              retryCount: retryCount - 1,
              completion: completion
            )
          }
        } else {
          debugPrint("v2rx ❌ Upload failed permanently for: \(key)")
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
    debugPrint("v2rx 🔵 ENTER uploadFile for key: \(key)")
    
    guard let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: RecordingS3UploadConfiguration.transferUtilKey) else {
      let error = NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer Utility could not be formed"])
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
    
    // Timeout protection
    var completionCalled = false
    let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
      if !completionCalled {
        completionCalled = true
        debugPrint("v2rx ⏰ Upload timeout for key: \(key)")
        let error = NSError(domain: "S3Upload", code: -3, userInfo: [NSLocalizedDescriptionKey: "Upload timeout after 30 seconds"])
        completion(.failure(error))
      }
    }
    
    let uploadTask = transferUtility.uploadFile(
      url,
      bucket: bucketName,
      key: key,
      contentType: contentType,
      expression: expression
    ) { task, error in
      timeoutTimer.invalidate()
      
      guard !completionCalled else {
        debugPrint("v2rx ⚠️ Completion already called for key: \(key)")
        return
      }
      completionCalled = true
      
      if let error = error {
        debugPrint("v2rx ❌ Upload completion handler error: \(error.localizedDescription)")
        completion(.failure(error))
      } else {
        debugPrint("v2rx ✅ Upload completion handler success for key: \(key)")
        completion(.success(key))
      }
    }
    
    uploadTask.continueWith { t in
      if let error = t.error {
        timeoutTimer.invalidate()
        if !completionCalled {
          completionCalled = true
          debugPrint("v2rx ❌ Upload task creation failed: \(error.localizedDescription)")
          completion(.failure(error))
        }
      } else if let result = t.result {
        debugPrint("v2rx ✅ Upload task created with status: \(result.status.rawValue)")
      }
      return nil
    }
  }
}
