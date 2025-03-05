//
//  QueryHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 05/03/25.
//

import SwiftData
import Foundation

final class QueryHelper {
  static func queryForFetch(with id: UUID) -> FetchDescriptor<VoiceConversationModel> {
    var fetchDescriptor = FetchDescriptor<VoiceConversationModel>(predicate: #Predicate { $0.id == id })
    fetchDescriptor.fetchLimit = 1
    return fetchDescriptor
  }
}
