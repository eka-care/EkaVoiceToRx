//
//  VoiceToRxFirestoreManager.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//


import Foundation
import FirebaseFirestore

public enum VoiceToRxErrorCode: Int {
  case noIssues = 1
  case apiError = 2
  case smallTranscript = 3
  case unassigned = 4
}

enum VoiceToRxFileUploadStatus: Int {
  case uploading = 1
  case uploaded = 2
  case error = 3
}

final class VoiceToRxFirestoreManager {
  
  // MARK: - Properties
  
  // Shared
  private init() {}
  static let shared = VoiceToRxFirestoreManager()
  
  // DB Reference
  private var db: Firestore? = Firestore.firestore(database: "doctool")
  
  // Collection Name
  private let rootCollectionName = "app_status"
  private let voiceToRxCollectionName = "V2RX"
  
  // Keys
  private let fileNameKey = "file_name"
  private let sessionIdKey = "session_id"
  
  // MARK: - Listener
  
  /// Fetch the structured Rx
  func listenForStructuredRx(
    uuid: String = V2RxInitConfigurations.shared.ownerUUID ?? "",
    sessionId: String,
    completion: @escaping (
      _ transcriptedString: String?,
      _ jsonString: String?,
      _ errorStructuredRx: VoiceToRxErrorCode?,
      _ listenerReference: (any ListenerRegistration)?) -> Void
  ) {
    let dataRef = db?
      .collection(rootCollectionName)
      .document(uuid)
      .collection(voiceToRxCollectionName).document(sessionId)
    
    /// Listen to rx structured data
    var listenerReference: (any ListenerRegistration)?
    var errorStructuredRx: VoiceToRxErrorCode?
    listenerReference = dataRef?.addSnapshotListener { snapshot, error in
      if let dataObject = snapshot?.data()?["data"] as? [String: Any] {
        let transcriptedString = dataObject["transcription"] as? String
        if let errorStatus = dataObject["error_status"] as? [String: Any],
           let errorStatusCode = errorStatus["error_structured_rx"] as? Int {
          errorStructuredRx = VoiceToRxErrorCode(rawValue: errorStatusCode)
        }
        let prescriptionString = JSONHelper().prettyPrintedJSONString(from: dataObject["prescription"])
        completion(transcriptedString, prescriptionString, errorStructuredRx, listenerReference)
      }
    }
  }
  
  func listenForFilesProcessed(
    uuid: String = V2RxInitConfigurations.shared.ownerUUID ?? "",
    sessionID: String,
    completion: @escaping (
      _ documentsProcessed: Set<String>,
      _ listenerReference: (any ListenerRegistration)?) -> Void
  ) {
    let query = fetchDocumentsQuery(for: sessionID, uuid: uuid)
    var documentsProcessed: Set<String> = []
    var listenerReference: (any ListenerRegistration)?
    typealias DocumentDataObject = [String: Any]
    
    listenerReference = query?.addSnapshotListener { snapshot, error in
      guard let documents = snapshot?.documents.compactMap({ $0.data() }) as? [DocumentDataObject] else { return }
      
      /// Add file name in files processed
      documents.forEach { [weak self] documentDataObject in
        guard let self else { return }
        if let fileName = documentDataObject[fileNameKey] as? String {
          documentsProcessed.insert(fileName)
        }
      }
      
      completion(documentsProcessed, listenerReference)
    }
  }
  
  func clearAllData() {
    db?.clearPersistence()
  }
}

// MARK: - Queries

extension VoiceToRxFirestoreManager {
  func fetchDocumentsQuery(
    for sessionID: String,
    uuid: String
  ) -> Query?  {
    return db?
      .collection(rootCollectionName)
      .document(uuid)
      .collection(voiceToRxCollectionName)
      .whereField("session_id", isEqualTo: sessionID)
  }
}
