//
//  AWSConfiguration.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 04/03/25.
//


import AWSCore
import AWSS3

final class AWSConfiguration {
  static let shared = AWSConfiguration()
  private init() {}
  
  func configureAWSS3(credentials: Credentials) -> AWSServiceConfiguration? {
    guard let accessKeyID = credentials.accessKeyID,
          let secretKey = credentials.secretKey,
          let sessionToken = credentials.sessionToken else { return nil }
    
    let sessionCredentials = AWSBasicSessionCredentialsProvider(
      accessKey: accessKeyID,
      secretKey: secretKey,
      sessionToken: sessionToken
    )
    
    let clientConfiguration = AWSServiceConfiguration(
      region: .APSouth1, // Change to your region
      credentialsProvider: sessionCredentials
    )
    
    return clientConfiguration
//
//    AWSServiceManager.default().defaultServiceConfiguration = clientConfiguration
//    AWSS3.register(with: clientConfiguration!, forKey: "s3")
  }
}
