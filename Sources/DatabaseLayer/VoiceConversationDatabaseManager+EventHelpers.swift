//
//  VoiceConversationDatabaseManager+EventHelpers.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/06/25.
//

import Foundation

// MARK: - VoiceConversationDatabaseManager Event Logs

extension VoiceConversationDatabaseManager {
  
  // MARK: - Add Voice
  
  func logAddVoiceEvent(
    sessionID: UUID?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": AuthTokenHolder.shared.bid ?? ""
      ],
      eventType: .create,
      message: message,
      status: status,
      platform: .database
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update Conversation
  
  func logUpdateConversationEvent(
    sessionID: UUID?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": AuthTokenHolder.shared.bid ?? ""
      ],
      eventType: .update,
      message: message,
      status: status,
      platform: .database
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Update Chunk
  
  func logUpdateChunkEvent(
    sessionID: UUID?,
    fileName: String?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": AuthTokenHolder.shared.bid ?? "",
        "fileName": fileName ?? ""
      ],
      eventType: .update,
      message: message,
      status: status,
      platform: .database
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete Voice
  
  func logDeleteVoiceEvent(
    sessionID: UUID?,
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    guard let sessionID else { return }
    
    let eventLog = EventLog(
      params: [
        "sessionID": sessionID.uuidString,
        "bid": AuthTokenHolder.shared.bid ?? ""
      ],
      eventType: .delete,
      message: message,
      status: status,
      platform: .database
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
  
  // MARK: - Delete All
  
  func logDeleteAllVoicesEvent(
    status: EventStatusMonitor,
    message: String? = nil
  ) {
    let eventLog = EventLog(
      params: [
        "bid": AuthTokenHolder.shared.bid ?? ""
      ],
      eventType: .delete,
      message: message,
      status: status,
      platform: .database
    )
    
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
  }
}
