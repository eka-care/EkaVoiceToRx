//
//  CognitoProvider.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Foundation

protocol CognitoProvider {
  var networkService: Networking { get }
  
  func getAmazonCredentials(
    completion: @escaping (Result<AWSAuthResponse, Error>, Int?) -> Void
  )
}

extension CognitoProvider {
  func getAmazonCredentials(
    completion: @escaping (Result<AWSAuthResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(CognitoEndpoints.getAmazonCredentials, completion: completion)
  }
}
