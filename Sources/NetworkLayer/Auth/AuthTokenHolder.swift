//
//  AuthTokenHolder.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

/**
 This class holds auth token and refresh token until app is running.
 This is set on app launch and removed on app termination.
 */

public final class AuthTokenHolder {
  
  // MARK: - Properties
  
  public static let shared = AuthTokenHolder()
  
  public init() {}
  public var authToken: String?
  public var refreshToken: String?
}
