//
//  NetworkRequestInterceptor.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Alamofire
import Foundation
import UIKit

final class NetworkRequestInterceptor: Alamofire.RequestInterceptor {
  
  // MARK: - Properties
  
  let retryLimit = 1
  typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
  let authService = AuthApiService()
  private let isProto: Bool
  
  // MARK: - Init
  
  init(isProto: Bool = false) {
    self.isProto = isProto
  }
  
  // MARK: - Adapt
  
  func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    /// If the request does not require authentication, we can directly return it as unmodified.
    guard let url = urlRequest.url?.absoluteString, url.hasPrefix("") == true else {
      return completion(.success(urlRequest))
    }
    
    var urlRequest = urlRequest
    addEkaStaticHeaders(&urlRequest)
    completion(.success(urlRequest))
  }
  
  // MARK: - Retry
  
  /// Retry Logic
  func retry(
    _ request: Request,
    for session: Session,
    dueTo error: Error,
    completion: @escaping (RetryResult) -> Void
  ) {
    guard let response = request.task?.response as? HTTPURLResponse,
          response.statusCode == 401,
          request.retryCount < retryLimit else {
      /// Return the original error and don't retry the request.
      completion(.doNotRetryWithError(error))
      return
    }
    debugPrint("401, attempting token refresh")
    /// Call refresh token api call
    refreshTokens(
      refreshToken: AuthTokenHolder.shared.refreshToken,
      accessToken: AuthTokenHolder.shared.authToken
    ) { succeeded, accessToken in
      /// If we have new token then retry immediately
      if succeeded {
        completion(.retry)
      }
    }
  }
}

// MARK: - Helper Functions

extension NetworkRequestInterceptor {
  /// API call to get new access token
  func refreshTokens(
    refreshToken: String?,
    accessToken: String?,
    completion: @escaping RefreshCompletion
  ) {
    guard let refreshToken,
          let accessToken else { return }
    let refreshRequest = RefreshRequest(refresh: refreshToken, sess: accessToken)
    authService.refreshToken(refreshRequest: refreshRequest) { result, statusCode in
      switch result {
      case .success(let response):
        // Error in response
        if let success = response.success, !success {
          debugPrint("Error refreshing token")
          completion(false, nil)
          return
        }
        
        if let data = response.data,
           let newToken = data.sess,
           let newRefreshToken = data.refresh {
          /// Set the token in the shared instance
          AuthTokenHolder.shared.authToken = newToken
          AuthTokenHolder.shared.refreshToken = newRefreshToken
          completion(true, newToken)
          debugPrint("✅ Refreshed access token - \(newToken)")
        }
        // Failure
      case .failure(let error):
        completion(false, nil)
        debugPrint("Error refreshing token \(error)")
      }
    }
  }
  
  /// Use this to add eka headers to an API request
  /// - Parameters:
  ///   - urlRequest: The API request
  ///   - isAPIcall: Use this to add auth token in the header. Default is true.
  func addEkaStaticHeaders(_ urlRequest: inout URLRequest, addAuthHeader: Bool = true) {
    
    if isProto {
      urlRequest.headers.add(name: "Accept", value: "application/x-protobuf")
    }
    
    urlRequest.headers.add(name: "client-id", value: "doctor-app-ios")
    urlRequest.headers.add(name: "flavour", value: UIDevice.current.userInterfaceIdiom == .phone ? "io" : "ip")
    urlRequest.headers.add(name: "locale", value: String(Locale.preferredLanguages.first?.prefix(2) ?? "en"))
    
    /// Device information
    urlRequest.headers.add(name: "make", value: "Apple")
    
    if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
      urlRequest.headers.add(name: "version", value: appVersion)
    }
    
    let deviceID = UIDevice.current.identifierForVendor?.uuidString
    urlRequest.headers.add(name: "device-id", value: deviceID!)
    
    if addAuthHeader {
      if let accessToken = AuthTokenHolder.shared.authToken {
        /// Set the Authorization header value using the access token.
        urlRequest.headers.add(name: "auth", value: accessToken)
      }
    }
  }
}
