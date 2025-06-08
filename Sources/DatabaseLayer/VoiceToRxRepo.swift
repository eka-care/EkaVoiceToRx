//
//  VoiceToRxRepo.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

import Foundation

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
        outputFormatTemplate: []
      )
    ) { result, statusCode in }
    return voice
  }
  
  // MARK: - Stop
  
  public func stopVoiceToRxSession(voiceModel: VoiceConversation?) {
    guard let voiceModel, let sessionID = voiceModel.sessionID?.uuidString else { return }
    /// Get audio file names from one to one relationship
    let fileNames = (voiceModel.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.compactMap { $0.fileName } ?? []
    service.stopVoiceToRx(
      sessionID: sessionID,
      request: VoiceToRxStopRequest(
        audioFiles: fileNames,
        fileChunksInfo: [:]
      )
    ) { result, statusCode in
      
    }
  }
  
  // MARK: - Commit
  
  public func commitVoiceToRxSession(voiceModel: VoiceConversation?) {
    guard let voiceModel, let sessionID = voiceModel.sessionID?.uuidString else { return }
    /// Get audio file names from one to one relationship
    let fileNames = (voiceModel.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.compactMap { $0.fileName } ?? []
    service.commitVoiceToRx(
      sessionID: sessionID,
      request: VoiceToRxCommitRequest(
        audioFiles: fileNames,
        fileChunksInfo: [:]
      )
    ) { result, statusCode in
      
    }
  }
  
  // MARK: - Status
  
  public func fetchVoiceToRxSessionStatus(voiceModel: VoiceConversation?) {
    guard let voiceModel, let sessionID = voiceModel.sessionID?.uuidString else { return }
    service.getVoiceToRxStatus(sessionID: sessionID) { result, statusCode in }
  }
}
