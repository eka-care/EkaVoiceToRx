//
//  EOFFileMaker.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 13/08/24.
//

import Foundation
import SwiftyJSON

enum StatusFileType: String {
  case som
  case eof
}

struct StatusFileModel: Codable {
  let s3_url: String
  let uuid: String
  let files: [String]
  let doc_oid: String
  let doc_uuid: String
  let date: String
  let contextData: VoiceToRxContextParams?
  let fileChunksInfo: [String: FileChunkInfo]?
  let mode: String?
  
  enum CodingKeys: String, CodingKey {
    case s3_url = "s3_url"
    case uuid = "uuid"
    case files = "files"
    case doc_oid = "doc_oid"
    case doc_uuid = "doc_uuid"
    case date = "date"
    case contextData = "context_data"
    case fileChunksInfo = "chunks_info"
    case mode
  }
}

struct FileChunkInfo: Codable {
  let startingTime: String
  let endingTime: String
  
  enum CodingKeys: String, CodingKey {
    case startingTime = "st"
    case endingTime = "et"
  }
}

protocol StatusFileDelegate: AnyObject {
  func statusFileUrlsMapChanged(statusFileUrls: [URL])
}

final class StatusFileMaker {
  
  // MARK: - Properties
  
  weak var delegate: StatusFileDelegate?
  
  var statusFileURLs: [URL] = [] {
    didSet {
      delegate?.statusFileUrlsMapChanged(statusFileUrls: statusFileURLs)
    }
  }
  
  // MARK: - Init
  
  init(
    delegate: StatusFileDelegate?,
    statusFileURLs: [URL] = []
  ) {
    self.delegate = delegate
    self.statusFileURLs = statusFileURLs
  }
  
  func uploadStatusFile(
    docOid: String,
    uploadedFilesKeys: [String],
    fileUploadMapper: [String],
    domainName: String,
    bucketName: String,
    dateFolderName: String,
    sessionId: String,
    conversationType: VoiceConversationType?,
    fileChunksInfo: [String: FileChunkInfo]? = nil,
    contextData: VoiceToRxContextParams?,
    fileType: StatusFileType
  ) {
    let fileUploader = AmazonS3FileUploaderService()
    let statusFileModel = StatusFileModel(
      s3_url: "\(domainName)\(bucketName)/\(dateFolderName)/\(sessionId)",
      uuid: sessionId,
      files: uploadedFilesKeys,
      doc_oid: docOid,
      doc_uuid: V2RxInitConfigurations.shared.ownerUUID ?? "",
      date: Date().toIsoDateStringWithMilliSeconds(),
      contextData: contextData,
      fileChunksInfo: fileChunksInfo,
      mode: conversationType?.rawValue
    )
    let firstFolder: String = dateFolderName
    let secondFolder = sessionId
    let key = "\(firstFolder)/\(secondFolder)/\(fileType.rawValue).json"
    formStatusFile(
      fileType: fileType.rawValue,
      data: statusFileModel,
      sessionID: sessionId
    ) { fileURL in
      guard let fileURL else { return }
      fileUploader.uploadFileWithRetry(
        url: fileURL,
        key: key,
        contentType: "application/json"
      ) { result in
          switch result {
          case .success:
            /// Remove file from local after successfully uploaded
            debugPrint("Status File uploaded successfully")
          case .failure(let error):
            debugPrint("Error in uploading file -> \(error.localizedDescription)")
          }
        }
    }
  }
  
  func formStatusFile(
    fileType: String,
    data: StatusFileModel,
    sessionID: String,
    completion: @escaping (URL?) -> Void)
  {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .prettyPrinted
    
    do {
      // Encode the data into JSON
      let jsonData = try jsonEncoder.encode(data)
      
      // Create File URL
      let fileURL = FileHelper.getDocumentDirectoryURL()
        .appendingPathComponent(sessionID)
        .appendingPathComponent("\(fileType).json")
      
      // Write the JSON data to the file
      try jsonData.write(to: fileURL)
      statusFileURLs.append(fileURL)
      // Call the completion handler with the file URL
      completion(fileURL)
    } catch {
      print("Error creating JSON file: \(error)")
      completion(nil)
    }
  }
}
