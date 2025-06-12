//
//  EventLog.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/06/25.
//

/// Event Log structure
public struct EventLog {
  /// Any extra information
  public let params: [String: Any]?
  /// Event type
  public let eventType: EventType
  /// Any message for the event
  public let message: String?
  /// Status in which event is in
  public let status: EventStatusMonitor
  /// Platform on which event took place
  public let platform: EventPlatform
  
  public init(
    params: [String : Any]? = nil,
    eventType: EventType,
    message: String? = nil,
    status: EventStatusMonitor,
    platform: EventPlatform
  ) {
    self.params = params
    self.eventType = eventType
    self.message = message
    self.status = status
    self.platform = platform
  }
}

public enum EventType: String {
  case create
  case read
  case update
  case delete
  case initSession
  case stop
  case commit
  case fetchStatus
  
  public var eventName: String {
    switch self {
    case .create:
      return "VoiceToRx_CREATE"
    case .read:
      return "VoiceToRx_READ"
    case .update:
      return "VoiceToRx_UPDATE"
    case .delete:
      return "VoiceToRx_DELETE"
    case .initSession:
      return "VoiceToRx_INIT"
    case .stop:
      return "VoiceToRx_STOP"
    case .commit:
      return "VoiceToRx_COMMIT"
    case .fetchStatus:
      return "VoiceToRx_STATUS"
    }
  }
}

/// Event Status
public enum EventStatusMonitor: String {
  case success
  case failure
}

/// Event platform
public enum EventPlatform: String {
  case database
  case network
}
