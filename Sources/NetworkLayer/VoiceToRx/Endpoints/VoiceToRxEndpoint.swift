//
//  VoiceToRxEndpoint.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

import Alamofire

enum VoiceToRxEndpoint {
  /// Init
  case initVoiceToRx(request: VoiceToRxInitRequest, sessionID: String)
  /// Stop
  case stopVoiceToRx(request: VoiceToRxStopRequest, sessionID: String)
  /// Commit
  case commitVoiceToRx(request: VoiceToRxCommitRequest, sessionID: String)
  /// Result
  case getVoiceToRxStatus(sessionID: String)
  /// History
  case getHistoryEkaScribe
}

extension VoiceToRxEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
      /// Init
    case .initVoiceToRx(let request, let sessionID):
      AF.request(
        "\(DomainConfigurations.apiEkaCareUrl)/voice/api/v2/transaction/init/\(sessionID)",
        method: .post,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      /// Stop
    case .stopVoiceToRx(let request, let sessionID):
      AF.request(
        "\(DomainConfigurations.apiEkaCareUrl)/voice/api/v2/transaction/stop/\(sessionID)",
        method: .post,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      /// Commit
    case .commitVoiceToRx(let request, let sessionID):
      AF.request(
        "\(DomainConfigurations.apiEkaCareUrl)/voice/api/v2/transaction/commit/\(sessionID)",
        method: .post,
        parameters: request,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      /// Result
    case .getVoiceToRxStatus(let sessionID):
      AF.request(
        "\(DomainConfigurations.apiEkaCareUrl)/voice/api/v3/status/\(sessionID)",
        method: .get,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
      
    case .getHistoryEkaScribe:
      AF.request("\(DomainConfigurations.apiEkaCareUrl)/voice/api/v2/transaction/history?count=50",
      method: .get,
      headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
      interceptor: NetworkRequestInterceptor()
      )
    .validate()
    }
  }
}
