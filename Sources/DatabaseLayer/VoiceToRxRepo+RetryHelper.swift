//
//  VoiceToRxRepo+RetryHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 10/06/25.
//

import Foundation

extension VoiceToRxRepo {
  // MARK: - Retry Helper
  
  func retryOperation<T>(
    maxAttempts: Int = 3,
    operation: @escaping (@escaping (Result<T, Error>) -> Void) -> Void,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    var currentAttempt = 0
    
    func attemptOperation() {
      currentAttempt += 1
      operation { result in
        switch result {
        case .success:
          completion(result)
        case .failure(let error):
          if currentAttempt < maxAttempts {
            // Add a small delay between retries
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
              attemptOperation()
            }
          } else {
            completion(result)
          }
        }
      }
    }
    
    attemptOperation()
  }
}
