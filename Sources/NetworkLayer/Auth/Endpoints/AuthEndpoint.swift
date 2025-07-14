//
//  AuthEndpoint.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Alamofire

enum AuthEndpoint {
  case tokenRefresh(refreshRequest: RefreshRequest)
}

extension AuthEndpoint: RequestProvider {
  var urlRequest: Alamofire.DataRequest {
    switch self {
    case .tokenRefresh(let refreshRequest):
      AF.request(
        "\(DomainConfigurations.apiEkaCareUrl)/connect-auth/v1/account/refresh-token",
        method: .post,
        parameters: refreshRequest,
        encoder: JSONParameterEncoder.default,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
