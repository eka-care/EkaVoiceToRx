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
    if let createdAt = conversation.createdAt {
      self.createdAt = createdAt
    }
    if let transcription = conversation.transcription {
      self.transcription = transcription
    }
    if let stage = conversation.stage {
      self.stage = stage.rawValue
    }
    if let sessionData = conversation.sessionData {
      self.sessionData = convertToBinaryData(sessionData)
    }
  }
  
  private func convertToBinaryData(_ contextParams: VoiceToRxContextParams) -> Data? {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(contextParams)
      return data
    } catch {
      print("Failed to encode VoiceToRxContextParams: \(error)")
      return nil
    }
  }
}

// MARK: - Helper functions

extension VoiceConversation {
  /// Used to get all the file names from a voice entry
  /// - Returns: Array of the file names
  func getFileNames() -> [String] {
    (self.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.compactMap { $0.fileName } ?? []
  }
  
  /// Used to get file chunk info from the voice entry
  /// - Returns: File chunk info against the file name
  func getFileChunkInfo() -> [String: FileChunkInfo] {
    var filesChunkInfo: [String: FileChunkInfo] = [:]
    
    (self.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.forEach {
      if let fileName = $0.fileName {
        filesChunkInfo[fileName] = FileChunkInfo(
          startingTime: $0.startTime ?? "",
          endingTime: $0.endTime ?? ""
        )
      }
    }
    
    return filesChunkInfo
  }
}
