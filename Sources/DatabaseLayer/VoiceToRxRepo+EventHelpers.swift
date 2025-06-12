//
//  VoiceToRxRepo+EventHelpers.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/06/25.
//

import Foundation

// MARK: - VoiceToRx Event Helpers

extension VoiceToRxRepo {
  
  // MARK: - Init API
  
  func initVoiceEvent(
    sessionID: UUID?,
    bid: String?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID, let bid else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": bid
      ],
      eventType: .initSession,
      message: message,
      status: status,
      platform: .network
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Stop
  
  func stopVoiceEvent(
    sessionID: UUID?,
    bid: String?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID, let bid else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": bid
      ],
      eventType: .stop,
      message: message,
      status: status,
      platform: .network
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Commit
  
  func commitVoiceEvent(
    sessionID: UUID?,
    bid: String?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID, let bid else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": bid
      ],
      eventType: .commit,
      message: message,
      status: status,
      platform: .network
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Fetch Status
  
  func statusFetchEvent(
    sessionID: UUID?,
    bid: String?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID, let bid else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": bid
      ],
      eventType: .fetchStatus,
      message: message,
      status: status,
      platform: .network
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}
