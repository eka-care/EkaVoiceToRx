//
//  VoiceToRxRepo.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

import Foundation
import CoreData

final class VoiceToRxRepo {
  
  // MARK: - Properties
  
  private let databaseManager = VoiceConversationDatabaseManager.shared
  let service = VoiceToRxApiService()
  let maxRetries = 3
  
  // MARK: - Create
  
  /// Used to create a new voice to rx session
  public func createVoiceToRxSession(
    contextParams: VoiceToRxContextParams?,
    conversationMode: VoiceConversationType
  ) async -> VoiceConversation? {
    guard let contextParams else { return nil }
    /// Add Voice to rx session in database
    let voice = await databaseManager.addVoiceConversation(
      conversationArguement: VoiceConversationArguementModel(
        createdAt: Date(),
        sessionData: contextParams
      )
    )
    guard let voice, let sessionID = voice.sessionID else { return nil }
    /// Call the init api
    service.initVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxInitRequest(
        additionalData: contextParams,
        mode: conversationMode.rawValue,
        inputLanguage: [],
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
        debugPrint("Error in init voice to rx")
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
  
  // MARK: - Read
  
  public func fetchVoiceConversation(
    fetchRequest: NSFetchRequest<VoiceConversation>
  ) -> VoiceConversation? {
    databaseManager.getVoice(fetchRequest: fetchRequest)
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
    completion: @escaping () -> Void
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
          VoiceConversationAPIStage(rawValue: model.stage ?? "") == .initialise /// Init should have been done
    else { return }
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
        debugPrint("Error in stop voice to rx \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - Commit
  
  public func commitVoiceToRxSession(sessionID: UUID?) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
          VoiceConversationAPIStage(rawValue: model.stage ?? "") == .stop
    else { return }
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
      case .failure(let error):
        debugPrint("Error in commit voice to rx \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - Status
  
  public func fetchVoiceToRxSessionStatus(
    sessionID: UUID?,
    completion: @escaping (Bool) -> Void
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
    VoiceConversationAPIStage(rawValue: model.stage ?? "") == .commit
    else { return }
    service.getVoiceToRxStatus(sessionID: sessionID.uuidString) { result, statusCode in
      switch result {
      case .success(let response):
        guard let outputs = response.data?.output, !outputs.isEmpty else {
          print("❌ No output in response")
          completion(false)
          return
        }
        let allSuccessful = outputs.allSatisfy { $0.status == "success" }
        completion(allSuccessful)
      case .failure(let error):
        debugPrint("Error in getting voice to rx status -> \(error)")
        completion(false)
      }
    }
  }
}
