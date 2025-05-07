//
//  AuthProvider.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Foundation

protocol AuthProvider {
  var networkService: Networking { get }
  
  /// Use this endpoint with the refresh token to get a new session token
  /// - Parameters:
  ///   - refreshRequest: RefreshRequest
  ///   - completion: Completion callback
  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  )
}

extension AuthProvider {
  func refreshToken(
    refreshRequest: RefreshRequest,
    _ completion: @escaping (Result<RefreshResponse, Error>, Int?) -> Void
  ) {
    networkService.execute(AuthEndpoint.tokenRefresh(refreshRequest: refreshRequest), completion: completion)
  }
}
