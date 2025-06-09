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
        outputFormatTemplate: [],
        transfer: "vaded"
      )
    ) { result, statusCode in }
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
  
  // MARK: - Stop
  
  public func stopVoiceToRxSession(sessionID: UUID?) {
    guard let sessionID,
    let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)) else { return }
    let fileNames = model.getFileNames()
    let filesChunkInfo = model.getFileChunkInfo()
    
    service.stopVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxStopRequest(
        audioFiles: fileNames,
        fileChunksInfo: filesChunkInfo
      )
    ) { result, statusCode in
      
    }
  }
  
  // MARK: - Commit
  
  public func commitVoiceToRxSession(sessionID: UUID?) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)) else { return }
    let fileNames = model.getFileNames()
    let filesChunkInfo = model.getFileChunkInfo()

    service.commitVoiceToRx(
      sessionID: sessionID.uuidString,
      request: VoiceToRxCommitRequest(
        audioFiles: fileNames,
        fileChunksInfo: filesChunkInfo
      )
    ) { result, statusCode in
      
    }
  }
  
  // MARK: - Status
  
  public func fetchVoiceToRxSessionStatus(sessionID: UUID?) {
    guard let sessionID else { return }
    service.getVoiceToRxStatus(sessionID: sessionID.uuidString) { result, statusCode in }
  }
}
