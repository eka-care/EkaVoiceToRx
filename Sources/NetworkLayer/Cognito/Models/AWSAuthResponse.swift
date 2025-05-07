//
//  AWSAuthResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//


import Foundation

// MARK: - AWSAuthResponse

struct AWSAuthResponse: Codable {
  let token, identityID: String?
  let expiry: Int?
  let credentials: Credentials?
  
  enum CodingKeys: String, CodingKey {
    case token
    case identityID = "identity_id"
    case expiry, credentials
  }
}

// MARK: - Credentials

struct Credentials: Codable {
  let accessKeyID, secretKey, sessionToken, expiration: String?
  
  enum CodingKeys: String, CodingKey {
    case accessKeyID = "AccessKeyId"
    case secretKey = "SecretKey"
    case sessionToken = "SessionToken"
    case expiration = "Expiration"
  }
}