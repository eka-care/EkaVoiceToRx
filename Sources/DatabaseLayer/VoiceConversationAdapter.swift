//
//  VoiceConversationAdapter.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 26/05/25.
//

import Foundation

/// Used to pass the arguments to any core data model
public struct VoiceConversationArguementModel {
  let createdAt: Date? // Conversation created at date
  let fileURL: String? // URI of the audio file
  var transcription: String? // Transcription text of the conversation
  var stage: VoiceConversationAPIStage? // Raw value of VoiceConversationAPIStage
  var updatedSessionID: String? // Updated session id of the conversation done from BE "PP" addition
  let sessionData: VoiceToRxContextParams? // Additional session data for init like doc ID etc
  
  public init(
    createdAt: Date? = nil,
    fileURL: String? = nil,
    transcription: String? = nil,
    stage: VoiceConversationAPIStage? = nil,
    updatedSessionID: String? = nil,
    sessionData: VoiceToRxContextParams? = nil
  ) {
    self.createdAt = createdAt
    self.fileURL = fileURL
    self.transcription = transcription
    self.stage = stage
    self.updatedSessionID = updatedSessionID
    self.sessionData = sessionData
  }
}

public struct VoiceChunkInfoArguementModel {
  let startTime: String? /// Start time of the chunk
  let endTime: String? /// End time of the chunk
  let fileURL: String? /// File uri of the chunk
  let fileName: String /// File name like "1.m4a"
  var isFileUploaded: Bool = false /// Is the file uploaded
  
  public init(
    startTime: String? = nil,
    endTime: String? = nil,
    fileURL: String? = nil,
    fileName: String,
    isFileUploaded: Bool = false
  ) {
    self.startTime = startTime
    self.endTime = endTime
    self.fileURL = fileURL
    self.fileName = fileName
    self.isFileUploaded = isFileUploaded
  }
}

