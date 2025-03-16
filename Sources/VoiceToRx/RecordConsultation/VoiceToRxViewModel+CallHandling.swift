//
//  VoiceToRxViewModel+CallHandling.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 16/03/25.
//

import UIKit
import AVFAudio

// MARK: - Call Handling

extension VoiceToRxViewModel {
  func addInterruptionObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }
  
  @objc func handleInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    
    switch type {
    case .began:
      /// Interruption began, pause the recording
      pauseRecording()
    case .ended:
      /// Interruption ended, check if it should resume
      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      if options.contains(.shouldResume) {
        // Resume the recording
        Task {
          try? await resumeRecording()
        }
      }
    default:
      break
    }
  }
  
  func removeInterruptionObserver() {
    NotificationCenter.default
      .removeObserver(
        self,
        name: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance()
      )
  }
}
