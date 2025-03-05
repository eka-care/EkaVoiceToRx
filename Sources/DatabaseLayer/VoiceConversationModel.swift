//
//  VoiceConversationModel.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//


import Foundation
import SwiftData

public typealias VoiceConversationModel = VoiceConversations.VoiceConversationModelV1

public enum VoiceConversations: VersionedSchema {
  public static var models: [any PersistentModel.Type] {
    [VoiceConversationModelV1.self]
  }
  
  public static var versionIdentifier = Schema.Version(1, 0, 0)
  
  @Model
  public final class VoiceConversationModelV1: Sendable {
    @Attribute(.unique) public var id: UUID
    public var fileURL: String?
    public var date: Date
    public var transcriptionText: String
    public var updatedSessionID: UUID?
    
    public init(
      fileURL: String? = nil,
      date: Date,
      transcriptionText: String,
      updatedSessionID: UUID? = nil
    ) {
      self.id = UUID()
      self.fileURL = fileURL
      self.date = date
      self.transcriptionText = transcriptionText
      self.updatedSessionID = updatedSessionID
    }
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
  
  public func fetchVoiceConversation(
    using fetchDescriptor: FetchDescriptor<VoiceConversationModel>
  ) -> [VoiceConversationModel] {
    do {
      return try modelContext.fetch(fetchDescriptor)
    } catch {
      print("Failed to fetch voice conversations: \(error.localizedDescription)")
      return []
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
