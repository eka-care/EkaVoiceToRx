//
//  QueryHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 05/03/25.
//

import SwiftData
import Foundation
import CoreData

public final class QueryHelper {
  public static func queryForFetch(with id: UUID) -> FetchDescriptor<VoiceConversationModel> {
    var fetchDescriptor = FetchDescriptor<VoiceConversationModel>(predicate: #Predicate { $0.id == id })
    fetchDescriptor.fetchLimit = 1
    return fetchDescriptor
  }
  
  public static func fetchRequest(for sessionID: UUID) -> NSFetchRequest<VoiceConversation> {
    let request: NSFetchRequest<VoiceConversation> = VoiceConversation.fetchRequest()
    request.predicate = NSPredicate(format: "sessionID == %@", sessionID as CVarArg)
    request.fetchLimit = 1
    return request
  }
  
  public static func fetchChunkInfo() {
    
  }
}
