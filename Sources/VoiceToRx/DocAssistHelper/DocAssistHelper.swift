//
//  DocAssistHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 05/03/25.
//

import Foundation

public enum DocAssistV2RxState {
  case draft
  case saved
  case retry
}

public final class V2RxDocAssistHelper {
  public static func fetchV2RxState(for sessionID: UUID) async -> DocAssistV2RxState? {
    let voiceConversationModel = await VoiceConversationAggregator.shared.fetchVoiceConversation(
      using: QueryHelper.queryForFetch(with: sessionID)
    )
    /// If session has updatedSession ID, then it is saved
    if voiceConversationModel.first?.updatedSessionID != nil {
      return .saved
    } else if VoiceToRxFileUploadRetry.checkIfRetryNeeded(sessionID: sessionID) { /// If session id requires retry then return retry
      return .retry
    } else { /// Otherwise its draft, it will be saved once the use clicks save in the rx
      return .draft
    }
  }
}
