//
//  EventLoggerProtocol.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/06/25.
//

public protocol VoicerToRxCommunicationDelegate: AnyObject {
  func receiveEvent(eventLog: EventLog)
  /// called when eka auth refresh fails
  func logoutUser()
}
