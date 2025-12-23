//
//  MicrophonePermissionManager.swift
//  EkaVoiceToRx
//
//  Created on [Current Date]
//

import Foundation
import AVFoundation

/// Enum representing the status of microphone permission and availability
public enum MicrophonePermissionStatus {
  case available
  case microphonePermissionDenied
  case microphoneIsInUse
}

/// Manager for handling microphone permissions and availability checks
public struct MicrophoneManager {
  
  // MARK: - Public Methods
  
  /// Checks the overall microphone status including permission and availability
  /// - Returns: The current microphone permission status
  public static func checkMicrophoneStatus() -> MicrophonePermissionStatus {
    guard isMicrophonePermissionGranted() else {
      return .microphonePermissionDenied
    }
    
    guard isMicrophoneFreeToUse() else {
      return .microphoneIsInUse
    }
    
    return .available
  }
  
  /// Checks if microphone permission has been granted
  /// - Returns: `true` if permission is granted, `false` otherwise
  public static func isMicrophonePermissionGranted() -> Bool {
    let status = AVAudioApplication.shared.recordPermission
    return status == .granted
  }
  
  /// Checks if the microphone is free to use (not in use by another app)
  /// - Returns: `true` if microphone is available, `false` if it's in use
  public static func isMicrophoneFreeToUse() -> Bool {
    let session = AVAudioSession.sharedInstance()
    
    do {
      try session.setCategory(.playAndRecord, mode: .default, options: [])
      try session.setActive(true, options: [.notifyOthersOnDeactivation])
    } catch {
      return false
    }
    
    // Check if audio inputs are available
    if session.availableInputs?.isEmpty ?? true {
      return false
    }
    
    // Check if input is available
    if !session.isInputAvailable {
      return false
    }
    
    return true
  }
  
  /// Requests microphone permission from the user
  /// - Parameter completion: Completion handler called with the permission result
  public static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    AVAudioApplication.requestRecordPermission { granted in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
}

