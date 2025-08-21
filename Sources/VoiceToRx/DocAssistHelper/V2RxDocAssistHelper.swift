//
//  DocAssistHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 05/03/25.
//

import Foundation

public enum DocAssistV2RxState {
  case loading
  case draft
  case saved
  case retry
  case processing
  case deleted
}

public final class V2RxDocAssistHelper {
  public static func fetchV2RxState(for sessionID: UUID) -> DocAssistV2RxState {
    guard let voiceConversation = VoiceConversationDatabaseManager.shared.getVoice(fetchRequest: QueryHelper.fetchRequest(for: sessionID)) else {
      return .deleted
    }
    print("Voice conversation stage for id \(sessionID.uuidString) is -> \(voiceConversation.stage)")
    if voiceConversation.updatedSessionID != nil {
      return .saved
    } else if let stage = voiceConversation.stage, VoiceConversationAPIStage.getEnum(from: stage) == .result(success: true) {
      return .draft
    } else if let stage = voiceConversation.stage,
              VoiceConversationAPIStage.getEnum(from: stage) == .result(success: false) ||
                VoiceToRxFileUploadRetry.checkIfRetryNeeded(sessionID: sessionID) {
      return .retry
    } else {
      return .processing
    }
  }
}
