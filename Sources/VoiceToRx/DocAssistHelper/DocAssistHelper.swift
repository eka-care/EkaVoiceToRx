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
}

public final class V2RxDocAssistHelper {
  public static func fetchV2RxState(for sessionID: UUID) async -> DocAssistV2RxState? {
    let voiceConversationModel = await VoiceConversationAggregator.shared.fetchVoiceConversation(
      using: QueryHelper.queryForFetch(with: sessionID)
    )
    /// Fetch the model
    guard let model = voiceConversationModel.first else { return nil }
    /// If session has updatedSession ID, then it is saved
    if model.updatedSessionID != nil {
      return .saved
    } else if VoiceToRxFileUploadRetry.checkIfRetryNeeded(sessionID: sessionID) { /// If session id requires retry then return retry
      return .retry
    } else if model.didFetchResult == true {
      return .draft
    } else { /// Otherwise its draft, it will be saved once the use clicks save in the rx
      return .loading
    }
  }
}
