//
//  VoiceToRxRepo.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

import Foundation
import CoreData

public final class VoiceToRxRepo {
  
  // MARK: - Properties
  
  private let databaseManager = VoiceConversationDatabaseManager.shared
  let service = VoiceToRxApiService()
  let maxRetries = 3
  
  // MARK: - Init
  
  public init() {}
  
  // MARK: - Create
  
  /// Used to create a new voice to rx session
  public func createVoiceToRxSession(
    contextParams: VoiceToRxContextParams?,
    conversationMode: VoiceConversationType,
    retryCount: Int = 0
  ) async -> VoiceConversation? {
    guard let contextParams else { return nil }
    /// Add Voice to rx session in database
    let voice = await databaseManager.addVoiceConversation(
      conversationArguement: VoiceConversationArguementModel(
        createdAt: Date(),
        sessionData: contextParams
      )
    )
    guard let voice, let sessionID = voice.sessionID else {
      if retryCount < 3 {
        return await createVoiceToRxSession(contextParams: contextParams, conversationMode: conversationMode, retryCount: retryCount + 1)
      }
      return nil
    }
    /// Call the init api
    service.initVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxInitRequest(
        additionalData: contextParams,
        mode: conversationMode.rawValue,
        inputLanguage: ["en-IN", "hi"],
        s3URL: RecordingS3UploadConfiguration.getS3Url(sessionID: sessionID),
        outputFormatTemplate: [
          OutputFormatTemplate(templateID: "eka_emr_to_fhir_template")
        ],
        transfer: "vaded"
      )
    ) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success:
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .initialise
          )
        )
      case .failure(let error):
        debugPrint("Error in init voice to rx \(error.localizedDescription)")
      }
    }
    return voice
  }
  
  // MARK: - Update
  
  /// Used to update voice to rx chunk info
  /// - Parameters:
  ///   - sessionID: session id of the given voice to rx session
  ///   - chunkInfo: model for passing voice chunk info that is to be updated
  public func updateVoiceToRxChunkInfo(
    sessionID: UUID,
    chunkInfo: VoiceChunkInfoArguementModel
  ) {
    databaseManager.updateVoiceChunk(
      sessionID: sessionID,
      chunkArguement: chunkInfo
    )
  }
  /// Used to update voice to rx session info
  /// - Parameters:
  ///   - sessionID: session id of the given voice to rx session
  ///   - voiceInfo: voice to rx session info that is to be updated
  public func updateVoiceToRxSessionData(
    sessionID: UUID,
    voiceInfo: VoiceConversationArguementModel
  ) {
    databaseManager.updateVoiceConversation(
      sessionID: sessionID,
      conversationArguement: voiceInfo
    )
  }
  
  // MARK: - Read
  
  public func fetchVoiceConversation(
    fetchRequest: NSFetchRequest<VoiceConversation>
  ) -> VoiceConversation? {
    databaseManager.getVoice(fetchRequest: fetchRequest)
  }
  
  // MARK: - Delete
  
  /// Used to delete a specific voice conversation
  /// - Parameter fetchRequest: fetch request to delete a voice conversation
  public func deleteVoiceConversation(
    fetchRequest: NSFetchRequest<VoiceConversation>
  ) {
    databaseManager.deleteVoice(fetchRequest: fetchRequest)
  }
  
  /// Used to delete all the voices
  public func deleteAllVoices() {
    databaseManager.deleteAllVoices()
  }
  
  /// Used to observe upload status changes for a session id
  /// - Parameters:
  ///   - sessionID: sessionID of the voice session for which changes are to be observed
  ///   - completion: operation to be done on upload of all documents
  public func observeUploadStatusChangesFor(sessionID: UUID?, completion: @escaping () -> Void) {
    guard let sessionID else { return }
    databaseManager.observeUploadStatus(for: sessionID, completion: completion)
  }
  
  // MARK: - Stop
  
  public func stopVoiceToRxSession(
    sessionID: UUID?,
    completion: @escaping () -> Void,
    retryCount: Int = 0
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
          VoiceConversationAPIStage(rawValue: model.stage ?? "") == .initialise /// Init should have been done
    else {
      if retryCount < 3 {
        stopVoiceToRxSession(sessionID: sessionID, completion: completion, retryCount: retryCount + 1)
      }
      return
    }
    let fileNames = model.getFileNames()
    let chunksInfo = model.getChunksInfo()
    
    service.stopVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxStopRequest(
        audioFiles: fileNames,
        chunkInfo: chunksInfo
      )
    ) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success:
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .stop
          )
        )
        completion()
      case .failure(let error):
        if retryCount < 3 {
          stopVoiceToRxSession(sessionID: sessionID, completion: completion, retryCount: retryCount + 1)
        }
        debugPrint("Error in stop voice to rx \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - Commit
  
  public func commitVoiceToRxSession(
    sessionID: UUID?,
    retryCount: Int = 0,
    completion: @escaping () -> Void
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
          VoiceConversationAPIStage(rawValue: model.stage ?? "") == .stop
    else {
      if retryCount < 3 {
        commitVoiceToRxSession(sessionID: sessionID, retryCount: retryCount + 1, completion: completion)
      }
      return
    }
    let fileNames = model.getFileNames()
    let filesChunkInfo = model.getChunksInfo()
    
    service.commitVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxCommitRequest(
        audioFiles: fileNames,
        chunkInfo: filesChunkInfo
      )
    ) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success:
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .commit
          )
        )
        completion()
      case .failure(let error):
        if retryCount < 3 {
          commitVoiceToRxSession(sessionID: sessionID, retryCount: retryCount + 1, completion: completion)
        }
        debugPrint("Error in commit voice to rx \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - Status
  
  public func fetchVoiceToRxSessionStatus(
    sessionID: UUID?,
    completion: @escaping (Bool) -> Void,
    retryCount: Int = 0
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
    VoiceConversationAPIStage(rawValue: model.stage ?? "") == .commit
    else {
      if retryCount < 3 {
        fetchVoiceToRxSessionStatus(sessionID: sessionID, completion: completion, retryCount: retryCount + 1)
      }
      return
    }
    service.getVoiceToRxStatus(sessionID: sessionID.uuidString) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success(let response):
        guard let outputs = response.data?.output, !outputs.isEmpty else {
          print("❌ No output in response")
          completion(false)
          return
        }
        let allSuccessful = outputs.allSatisfy { $0.status == "success" }
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .result
          )
        )
        completion(allSuccessful)
      case .failure(let error):
        debugPrint("Error in getting voice to rx status -> \(error)")
        completion(false)
      }
    }
  }
}
