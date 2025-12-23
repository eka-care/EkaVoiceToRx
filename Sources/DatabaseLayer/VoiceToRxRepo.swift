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
  private let service = VoiceToRxApiService()
  private let maxRetries = 3
  public static let shared = VoiceToRxRepo()
  
  // MARK: - Init
  
  private init() {}
  
  // MARK: - Create
  
  /// Used to create a new voice to rx session
  public func createVoiceToRxSession(
    contextParams: VoiceToRxContextParams?,
    conversationMode: VoiceConversationType,
    retryCount: Int = 0,
    intpuLanguage: [String],
    templates: [OutputFormatTemplate],
    modelType: String,
    patientDetails: PatientDetails?
  ) async -> (VoiceConversation?, APIError?) {
    var apiError: APIError?
    guard let contextParams else { return (nil, apiError) }
    /// Add Voice to rx session in database
    let voice = await databaseManager.addVoiceConversation(
      conversationArguement: VoiceConversationArguementModel(
        createdAt: Date(),
        sessionData: contextParams
      )
    )
    guard let voice, let sessionID = voice.sessionID else {
      initVoiceEvent(
        sessionID: nil,
        status: .failure,
        message: "No model could be created"
      )
      if retryCount < 3 {
        return await createVoiceToRxSession(contextParams: contextParams, conversationMode: conversationMode, retryCount: retryCount + 1, intpuLanguage: intpuLanguage, templates: templates, modelType: modelType, patientDetails: patientDetails)
      }
      return (nil, apiError)
    }
    return await withCheckedContinuation { continuation in
      service.initVoiceToRx(
        sessionID: sessionID.uuidString,
        request: VoiceToRxInitRequest(
          additionalData: contextParams,
          mode: conversationMode.rawValue,
          inputLanguage: intpuLanguage,
          s3URL: RecordingS3UploadConfiguration.getS3Url(sessionID: sessionID),
          outputFormatTemplate: templates,
          transfer: "vaded",
          modelType: modelType,
          patientDetails: patientDetails
        )
      ) { [weak self] result, statusCode in
        guard let self else {
          continuation.resume(returning: (voice, nil))
          return
        }
        
        switch result {
        case .success:
          initVoiceEvent(sessionID: sessionID, status: .success)
          
          databaseManager.updateVoiceConversation(
            sessionID: sessionID,
            conversationArguement: VoiceConversationArguementModel(stage: .initialise)
          )
          
          continuation.resume(returning: (voice, nil))
          
        case .failure(let error):
          initVoiceEvent(sessionID: sessionID, status: .failure, message: "Error in init voice to rx \(error.localizedDescription)")
          debugPrint("Error in init voice to rx \(error.localizedDescription)")
          /// Delete voice
          if let sessionID = voice.sessionID {
            deleteVoiceConversation(fetchRequest: QueryHelper.fetchRequest(for: sessionID))
          }
          continuation.resume(returning: (nil, error))
        }
      }
    }
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
          VoiceConversationAPIStage.getEnum(from: model.stage ?? "") == .initialise /// Init should have been done
    else {
      stopVoiceEvent(
        sessionID: sessionID,
        status: .failure,
        message: "Insufficient parameters -> Session id: \(sessionID?.uuidString ?? "") or no Model"
      )
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
        stopVoiceEvent(sessionID: sessionID, status: .success)
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .stop
          )
        )
        completion()
      case .failure(let error):
        stopVoiceEvent(sessionID: sessionID, status: .failure, message: "Error in stop voice to rx \(error.localizedDescription)")
        debugPrint("Error in stop voice to rx \(error.localizedDescription)")
        if retryCount < 3 {
          stopVoiceToRxSession(sessionID: sessionID, completion: completion, retryCount: retryCount + 1)
        }
        completion()
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
          VoiceConversationAPIStage.getEnum(from: model.stage ?? "") == .stop
    else {
      commitVoiceEvent(
        sessionID: sessionID,
        status: .failure,
        message: "Insufficient parameters -> Session id: \(sessionID?.uuidString ?? "") or no Model"
      )
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
        commitVoiceEvent(sessionID: sessionID, status: .success)
        /// Update voice conversation model to a stage
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(
            stage: .commit
          )
        )
        completion()
      case .failure(let error):
        commitVoiceEvent(sessionID: sessionID, status: .failure, message: "Error in commit voice to rx \(error.localizedDescription)")
        debugPrint("Error in commit voice to rx \(error.localizedDescription)")
        if retryCount < 3 {
          commitVoiceToRxSession(sessionID: sessionID, retryCount: retryCount + 1, completion: completion)
        }
        completion()
      }
    }
  }
  
  // MARK: - Status
  
  public func fetchVoiceToRxSessionStatus(
    sessionID: UUID?,
    completion: @escaping (Result<(Bool, String), Error>) -> Void,
    retryCount: Int = 0
  ) {
    guard let sessionID,
          let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)),
          VoiceConversationAPIStage.getEnum(from: model.stage ?? "") == .commit
    else {
      /// Status fetch event
      statusFetchEvent(sessionID: sessionID, status: .failure, message: "No model or session id")
      if retryCount < 3 {
        fetchVoiceToRxSessionStatus(
          sessionID: sessionID,
          completion: completion,
          retryCount: retryCount + 1
        )
      } else {
        /// Status fetch event
        statusFetchEvent(sessionID: sessionID, status: .failure, message: "Invalid session or stage")
        completion(.failure(NSError(domain: "VoiceToRx", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid session or stage"])))
      }
      return
    }
    
    service.getVoiceToRxStatus(sessionID: sessionID.uuidString) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success(let response):
        guard let templateResults = response.data?.templateResults?.custom, !templateResults.isEmpty else {
          /// Status fetch event
          statusFetchEvent(sessionID: sessionID, status: .failure, message: "No output in response")
          print("❌ No output in response")
          completion(.success((false, "")))
          return
        }
        let allSuccessful = templateResults.allSatisfy { $0.status == "success" }
        let value = templateResults.first(where: { $0.value != nil })?.value ?? ""
        statusFetchEvent(sessionID: sessionID, status: .success, message: "All messages fetched successfully")
        
        let clinicalNotesValue = templateResults
          .filter { $0.templateID == "clinical_notes_template" }
          .compactMap { $0.value }
          .joined(separator: "\n")
        
        print("#BB clinicalNotesValue is \(clinicalNotesValue)")
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(transcription: clinicalNotesValue, stage: .result(success: true))
        )
        completion(.success((allSuccessful, value)))
        
      case .failure(let error):
        /// Status fetch event
        statusFetchEvent(sessionID: sessionID, status: .failure, message: "Error in getting voice to rx status -> \(error)")
        debugPrint("❌ Error in getting voice to rx status -> \(error)")
        databaseManager.updateVoiceConversation(
          sessionID: sessionID,
          conversationArguement: VoiceConversationArguementModel(stage: .result(success: false))
        )
        completion(.failure(error))
      }
    }
  }
  
  public func getEkaScribeHistory(completion: @escaping (Result<EkaScribeHistoryResponse, Error>) -> Void) {
    service.getHistoryEkaScribe { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  public func fetchResultStatusResponse(sessionID: String, completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void)  {
    service.getVoiceToRxStatus(sessionID: sessionID) { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: - Helper Extension

extension VoiceToRxRepo {
  public func getTemplateID(for sessionID: UUID) -> String {
    guard let model = databaseManager.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)) else {
      return ""
    }
    return model.transcription ?? ""
  }
}

extension VoiceToRxRepo {
  public func fetchResultStatus(sessionID: String,
                                completion: @escaping (Result<(Bool, String), Error>) -> Void) {
    service.getVoiceToRxStatus(sessionID: sessionID) { [weak self] result, statusCode in
      guard let self else { return }
      switch result {
      case .success(let response):
        guard let templateResults = response.data?.templateResults?.custom, !templateResults.isEmpty else {
          /// Status fetch event
          //statusFetchEvent(sessionID: sessionID, status: .failure, message: "No output in response")
          print("❌ No output in response")
          completion(.success((false, "")))
          return
        }
        let allSuccessful = templateResults.allSatisfy { $0.status == "success" }
        let value = templateResults.first(where: { $0.value != nil })?.value ?? ""
       // statusFetchEvent(sessionID: sessionID, status: .success, message: "All messages fetched successfully")
        
        let clinicalNotesValue = templateResults
          .filter { $0.templateID == "clinical_notes_template" }
          .compactMap { $0.value }
          .joined(separator: "\n")
        
        print("#BB clinicalNotesValue is \(clinicalNotesValue)")
        completion(.success((allSuccessful, value)))
        
      case .failure(let error):
        /// Status fetch event
    //    statusFetchEvent(sessionID: sessionID, status: .failure, message: "Error in getting voice to rx status -> \(error)")
        debugPrint("❌ Error in getting voice to rx status -> \(error)")
        completion(.failure(error))
      }
    }
  }
  
  public func updateResult(sessionID: String, request: UpdateResultRequest, completion: @escaping (Result<UpdateResultResponse, Error>, Int?) -> Void)  {
    service.updateResultData(sessionID: sessionID, request: request) { result, status in
      switch result {
      case .success(let success):
        completion(.success(success), status)
      case .failure(let failure):
        completion(.failure(failure), status)
      }
    }
  }
}

// MARK: - Templates
extension VoiceToRxRepo {
  public func getTemplates(completion: @escaping (Result<TemplateResponse,Error>)-> Void) {
    service.getTemplate { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  public func createTemplate(title: String, desc: String, completion: @escaping (Result<TemplateCreationResponse,Error>)-> Void) {
    let templateEditRequest = TemplateCreateAndEditRequest(title: title, desc: desc, sectionIds: [])
    service.createTemplate(request: templateEditRequest) { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  public func saveEditedTemplate(templateID: String, title: String, sessionID: [String], desc: String, completion: @escaping (Result<TemplateCreationResponse,Error>)-> Void) {
    let templateEditRequest = TemplateCreateAndEditRequest(title: title, desc: desc, sectionIds: sessionID)
    service.saveEditedTemplate(templateID: templateID, request: templateEditRequest) { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  public func deleteTemplate(templateID: String, completion: @escaping (Result<Void,Error>)-> Void) {
    service.deleteTemplate(templateID: templateID) { result, _ in
      switch result {
      case .success(_):
        completion(.success(()))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  public func switchTemplate(templateID: String, sessionID: String,completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void) {
    service.switchTemplate(templateID: templateID, sessionID: sessionID) { result, _ in
      switch result {
      case .success(let success):
        print("response -> \(success)")
        self.service.getVoiceToRxStatus(sessionID: success.txnID) { trxnResult, _ in
          switch trxnResult {
          case .success(let data):
            completion(.success(data))
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: - Config
extension VoiceToRxRepo {
  public func getConfig(completion: @escaping (Result<ConfigResponse,Error>) -> Void ) {
    service.getConfig { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let failure):
        completion(.failure(failure))
      }
      
    }
  }
  
  public func getTemplateFromConfig(completion: @escaping (Result<TemplateResponse, Error>) -> Void) {
    service.getTemplateFromConfig { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let failure):
        completion(.failure(failure))
      }
    }
  }
  
  public func updateConfig(templates: [String], completion: @escaping (Result<String, Error>) -> Void) {
    let templateData = MyTemplatesData(myTemplates: templates)
    let request = ConfigRequest(data: templateData, requestType: "user")
    service.updateConfig(request: request) { result, _ in
      switch result {
      case .success(let response):
        completion(.success(response))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

