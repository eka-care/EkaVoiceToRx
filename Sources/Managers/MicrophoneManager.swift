import AVFoundation
import UIKit

public enum MicrophoneStatus {
  case available
  case inUseByThisApp
  case inUseByOtherApp
  case permissionDenied
  case unavailable
}

public class MicrophoneManager: NSObject {
  
  private var audioSession = AVAudioSession.sharedInstance()
  private var audioRecorder: AVAudioRecorder?
  
  // MARK: - Check microphone availability
  public func checkMicrophoneStatus(completion: @escaping (MicrophoneStatus) -> Void) {
    // First check recording permission using the new iOS 17+ API
    if #available(iOS 17.0, *) {
      switch AVAudioApplication.shared.recordPermission {
      case .denied:
        completion(.permissionDenied)
        return
      case .undetermined:
        AVAudioApplication.requestRecordPermission { granted in
          DispatchQueue.main.async {
            if granted {
              self.checkMicrophoneAvailability(completion: completion)
            } else {
              completion(.permissionDenied)
            }
          }
        }
        return
      case .granted:
        checkMicrophoneAvailability(completion: completion)
      @unknown default:
        completion(.unavailable)
      }
    } else {
      // Fallback for iOS 16 and earlier
      switch audioSession.recordPermission {
      case .denied:
        completion(.permissionDenied)
        return
      case .undetermined:
        audioSession.requestRecordPermission { granted in
          DispatchQueue.main.async {
            if granted {
              self.checkMicrophoneAvailability(completion: completion)
            } else {
              completion(.permissionDenied)
            }
          }
        }
        return
      case .granted:
        checkMicrophoneAvailability(completion: completion)
      @unknown default:
        completion(.unavailable)
      }
    }
  }
  
  private func checkMicrophoneAvailability(completion: @escaping (MicrophoneStatus) -> Void) {
    do {
      // Try to set the audio session category for recording
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
      
      // Check if we're already recording
      if audioRecorder?.isRecording == true {
        completion(.inUseByThisApp)
        return
      }
      
      // Check current audio session state
      if audioSession.isOtherAudioPlaying {
        // Another app is playing audio, but mic might still be available
        print("Other audio is playing")
      }
      
      // Try to activate the audio session
      try audioSession.setActive(true)
      
      // Try to create a dummy audio recorder to test availability
      let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent("test_recording.m4a")
      
      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      let testRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      
      // Try to prepare the recorder - this will fail if mic is in use
      if testRecorder.prepareToRecord() {
        // Test if we can actually start recording briefly
        if testRecorder.record() {
          testRecorder.stop()
          completion(.available)
        } else {
          completion(.inUseByOtherApp)
        }
      } else {
        // Mic is likely in use by another app
        completion(.inUseByOtherApp)
      }
      
    } catch let error as NSError {
      print("Audio session error: \(error.localizedDescription)")
      print("Error domain: \(error.domain), code: \(error.code)")
      
      // Check if it's an AVError
      if let avError = error as? AVError {
        switch avError.code {
        case .deviceInUseByAnotherApplication:
          completion(.inUseByOtherApp)
        case .deviceAlreadyUsedByAnotherSession:
          completion(.inUseByOtherApp)
        case .sessionWasInterrupted:
          completion(.inUseByOtherApp)
        case .deviceNotConnected:
          completion(.unavailable)
        case .sessionNotRunning:
          completion(.unavailable)
        case .mediaServicesWereReset:
          completion(.unavailable)
        case .applicationIsNotAuthorizedToUseDevice:
          completion(.permissionDenied)
        case .recordingAlreadyInProgress:
          completion(.inUseByThisApp)
        default:
          completion(.unavailable)
        }
      } else if error.domain == NSOSStatusErrorDomain {
        // OSStatus error codes - most indicate resource conflicts
        completion(.inUseByOtherApp)
      } else {
        completion(.unavailable)
      }
    }
  }
  
  // MARK: - Monitor audio session interruptions
  func startMonitoringAudioSessionInterruptions() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioSessionInterruption),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioSessionRouteChange),
      name: AVAudioSession.routeChangeNotification,
      object: audioSession
    )
  }
  
  @objc private func handleAudioSessionInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    
    switch type {
    case .began:
      print("Audio session interrupted - microphone likely taken by another app")
      // Handle interruption began
      
    case .ended:
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          print("Audio session interruption ended - can resume")
          // Handle interruption ended
        }
      }
    @unknown default:
      break
    }
  }
  
  @objc private func handleAudioSessionRouteChange(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    switch reason {
    case .categoryChange:
      print("Audio route changed due to category change")
    case .newDeviceAvailable:
      print("New audio device available")
    case .oldDeviceUnavailable:
      print("Old audio device unavailable")
    default:
      break
    }
  }
  
  // MARK: - Simple and reliable microphone check
  func isRecordingAvailable(completion: @escaping (Bool) -> Void) {
    // Check permission first
    checkMicrophoneStatus { status in
      switch status {
      case .available:
        completion(true)
      default:
        completion(false)
      }
    }
  }
  
  // Alternative method using AVAudioEngine
  func checkMicrophoneWithAudioEngine(completion: @escaping (MicrophoneStatus) -> Void) {
    let audioEngine = AVAudioEngine()
    let inputNode = audioEngine.inputNode
    
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default)
      try audioSession.setActive(true)
      
      // Try to install a tap on the input node
      let format = inputNode.outputFormat(forBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { _, _ in
        // Just a dummy tap
      }
      
      try audioEngine.start()
      
      // If we get here, mic is available
      audioEngine.stop()
      inputNode.removeTap(onBus: 0)
      completion(.available)
      
    } catch let error {
      print("AudioEngine error: \(error)")
      
      // Handle specific AVError cases
      if let avError = error as? AVError {
        switch avError.code {
        case .deviceInUseByAnotherApplication:
          completion(.inUseByOtherApp)
        case .deviceAlreadyUsedByAnotherSession:
          completion(.inUseByOtherApp)
        case .sessionWasInterrupted:
          completion(.inUseByOtherApp)
        case .applicationIsNotAuthorizedToUseDevice:
          completion(.permissionDenied)
        case .deviceNotConnected:
          completion(.unavailable)
        default:
          completion(.inUseByOtherApp)
        }
      } else {
        // If AudioEngine fails to start, mic is likely in use
        completion(.inUseByOtherApp)
      }
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
