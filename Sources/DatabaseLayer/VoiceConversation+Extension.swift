//
//  File.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 26/05/25.
//

import CoreData

enum VoiceConversationAPIStage: String {
  case initialise /// Once init is done
  case stop /// Once stop is done
  case commit /// Once commit is done
  case result /// Once result is available
}

extension VoiceConversation {
  func update(from conversation: VoiceConversationArguementModel) {
    createdAt = conversation.createdAt
    transcription = conversation.transcription
    stage = conversation.stage?.rawValue
  }
}
