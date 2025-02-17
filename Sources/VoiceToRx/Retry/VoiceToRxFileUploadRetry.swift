//
//  VoiceToRxFileUploadRetry.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 17/02/25.
//

import Foundation

final class VoiceToRxFileUploadRetry {
  
  // MARK: - Properties
  
  let s3FileUploaderService = AmazonS3FileUploaderService()
  
  /// Retry files upload
  func retryFilesUpload(
    unuploadedFileUrls: [URL],
    sessionID: String,
    completion: @escaping () -> Void
  ) {
    let dispatchGroup = DispatchGroup()
    
    /// Retry uploading unuploaded files
    unuploadedFileUrls.forEach { fileURL in
      dispatchGroup.enter()
      uploadFile(
        sessionID: sessionID,
        fileURL: fileURL
      ) {
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      completion()
    }
  }
  
  private func uploadFile(
    sessionID: String,
    fileURL: URL,
    completion: @escaping () -> Void
  ) {
    let firstFolder: String = s3FileUploaderService.dateFolderName
    let secondFolder = sessionID
    let lastPathComponent = fileURL.lastPathComponent
    let key = "\(firstFolder)/\(secondFolder)/\(lastPathComponent)"
    s3FileUploaderService.uploadFileWithRetry(url: fileURL, key: key) { result in
      switch result {
      case .success(_):
        // Handle success if needed
        completion()
      case .failure(_):
        // Handle failure if needed
        completion()
      }
    }
  }
}
