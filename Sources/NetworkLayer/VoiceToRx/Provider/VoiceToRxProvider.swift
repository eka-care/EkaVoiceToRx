//
//  VoiceToRxProvider.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

protocol VoiceToRxProvider {
  var networkService: Networking { get }
  
  /// Init
  func initVoiceToRx(
    sessionID: String,
    request: VoiceToRxInitRequest,
    _ completion: @escaping (Result<VoiceToRxInitResponse, APIError>, Int?) -> Void
  )
  
  /// Stop
  func stopVoiceToRx(
    sessionID: String,
    request: VoiceToRxStopRequest,
    _ completion: @escaping (Result<VoiceToRxStopResponse, Error>, Int?) -> Void
  )
  
  /// Commit
  func commitVoiceToRx(
    sessionID: String,
    request: VoiceToRxCommitRequest,
    _ completion: @escaping (Result<VoiceToRxCommitResponse, Error>, Int?) -> Void
  )
  
  /// Status
  func getVoiceToRxStatus(
    sessionID: String,
    _ completion: @escaping (Result<VoiceToRxStatusResponse, Error>, Int?) -> Void
  )
  
  /// History
  func getHistoryEkaScribe(_ completion: @escaping (Result<EkaScribeHistoryResponse, Error>, Int?) -> Void)
}

extension VoiceToRxProvider {
  /// init
  func initVoiceToRx(
    sessionID: String,
    request: VoiceToRxInitRequest,
    _ completion: @escaping (Result<VoiceToRxInitResponse, APIError>, Int?) -> Void
  ) {
    networkService.execute(VoiceToRxEndpoint.initVoiceToRx(request: request, sessionID: sessionID), completion: completion)
  }
  
  /// Stop
  func stopVoiceToRx(
    sessionID: String,
    request: VoiceToRxStopRequest,
    _ completion: @escaping (Result<VoiceToRxStopResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(VoiceToRxEndpoint.stopVoiceToRx(request: request, sessionID: sessionID), completion: completion)
  }
  
  /// Commit
  func commitVoiceToRx(
    sessionID: String,
    request: VoiceToRxCommitRequest,
    _ completion: @escaping (Result<VoiceToRxCommitResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(VoiceToRxEndpoint.commitVoiceToRx(request: request, sessionID: sessionID), completion: completion)
  }
  
  /// Status
  func getVoiceToRxStatus(
    sessionID: String,
    _ completion: @escaping (Result<VoiceToRxStatusResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(VoiceToRxEndpoint.getVoiceToRxStatus(sessionID: sessionID), completion: completion)
  }
  
  /// History
  func getHistoryEkaScribe(_ completion: @escaping (Result<EkaScribeHistoryResponse, Error>, Int?) -> Void) {
    networkService.execute(VoiceToRxEndpoint.getHistoryEkaScribe, completion: completion)
  }
}
