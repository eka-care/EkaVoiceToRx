//
//  VoiceConversationModel.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//


import Foundation
import SwiftData

@Model
public final class VoiceConversationModel {
  @Attribute(.unique) public let id: UUID
  public let fileURL: String?
  public let date: Date
  public var transcriptionText: String
  
  public init(
    fileURL: String? = nil,
    date: Date,
    transcriptionText: String
  ) {
    self.id = UUID()
    self.fileURL = fileURL
    self.date = date
    self.transcriptionText = transcriptionText
  }
}

@ModelActor
public actor VoiceConversationAggregator {
  public static let shared = VoiceConversationAggregator(modelContainer: V2RxInitConfigurations.shared.modelContainer)
  
  public var getAllData: [VoiceConversationModel] {
    do {
      let fetchDescriptor = FetchDescriptor<VoiceConversationModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
      return try modelContext.fetch(fetchDescriptor)
    } catch {
      print("Failed to fetch voice conversations: \(error.localizedDescription)")
      return []
    }
  }
  
  public func saveVoice(model: VoiceConversationModel) throws {
    try modelContext.transaction {
      modelContext.insert(model)
      try modelContext.save()
    }
  }
  
  public func deleteVoice(id: UUID, completion: () -> Void) {
    do {
      let fetchDescriptor = FetchDescriptor<VoiceConversationModel>(predicate: #Predicate { $0.id == id })
      if let model = try modelContext.fetch(fetchDescriptor).first {
        modelContext.delete(model)
        completion()
      }
    } catch {
      print("Failed to Delete model with id \(id) \(error.localizedDescription)")
    }
  }
  
  public func updateVoice(id: UUID, transcriptText: String) {
    do {
      let fetchDescriptor = FetchDescriptor<VoiceConversationModel>(predicate: #Predicate { $0.id == id })
      if let model = try modelContext.fetch(fetchDescriptor).first {
        model.transcriptionText = transcriptText
      }
    } catch {
      print("Failed to Fetch model with id \(id) \(error.localizedDescription)")
    }
  }
  
  /// Function to delete all the data in swift data model
  public func deleteAll() {
    try? modelContext.delete(model: VoiceConversationModel.self, where: .true, includeSubclasses: true)
  }
}
