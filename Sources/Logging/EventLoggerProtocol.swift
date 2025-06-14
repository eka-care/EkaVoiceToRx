//
//  EventLoggerProtocol.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/06/25.
//

public protocol EventLoggerProtocol: AnyObject {
  func receiveEvent(eventLog: EventLog)
}
