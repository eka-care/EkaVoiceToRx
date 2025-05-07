//
//  CognitoEndpoints.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Alamofire

enum CognitoEndpoints {
  case getAmazonCredentials
}

extension CognitoEndpoints: RequestProvider {
  var urlRequest: DataRequest {
    switch self {
    case .getAmazonCredentials:
      return AF.request(
        "\(DomainConfigurations.cogUrl)/credentials",
        method: .get,
        headers: HTTPHeaders([.contentType(HTTPHeader.contentTypeJson.rawValue)]),
        interceptor: NetworkRequestInterceptor()
      )
      .validate()
    }
  }
}
