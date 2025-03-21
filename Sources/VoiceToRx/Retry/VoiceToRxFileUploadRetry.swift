//
//  VoiceToRxFileUploadRetry.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 17/02/25.
//

import Foundation

public final class VoiceToRxFileUploadRetry {
  
  // MARK: - Properties
  
  let s3FileUploaderService = AmazonS3FileUploaderService()
  
  /// Used to check if retry is needed
  /// - Returns: Bool value indicating if retry is needed
  public static func checkIfRetryNeeded(sessionID: UUID?) -> Bool {
    guard let sessionID else { return false }
    let directory = FileHelper.getDocumentDirectoryURL().appendingPathComponent(sessionID.uuidString)
    /// If files are present in the directory return true for retry
    if let retryFiles = FileHelper.getFileURLs(in: directory) {
      /// If retry files has only full audio file return false
      if retryFiles.count == 1 &&
         retryFiles.first?.lastPathComponent == "full_audio.m4a_" {
        return false
      } else { /// If any other file present return true
        return true
      }
    }
    /// If no files present return false
    return false
  }
  
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
    guard let sessionUUID = UUID(uuidString: sessionID) else { return}
    Task {
      guard let sessionModel = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: QueryHelper.queryForFetch(with: sessionUUID)).first else { return }
      let firstFolder: String = sessionModel.date.toString(withFormat: "yyMMdd")
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
}
