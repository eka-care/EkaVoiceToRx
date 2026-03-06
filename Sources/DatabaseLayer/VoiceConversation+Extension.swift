//
//  File.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 26/05/25.
//

import CoreData

public enum VoiceConversationAPIStage : Equatable {
  case initialise /// Once init is done
  case stop /// Once stop is done
  case commit /// Once commit is done
  case result(success: Bool) /// Once result is available
  
  var databaseString: String {
    switch self {
    case .initialise:
      return "initialise"
    case .stop:
      return "stop"
    case .commit:
      return "commit"
    case .result(let success):
      return success ? "result" : "error"
    }
  }
  
  static func getEnum(from databaseString: String) -> VoiceConversationAPIStage {
    switch databaseString {
    case "initialise":
      return .initialise
    case "stop":
      return .stop
    case "commit":
      return .commit
    case "result":
      return .result(success: true)
    case "error":
      return .result(success: false)
    default:
      return .result(success: false) // Or consider returning nil or throwing
    }
  }
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
      self.stage = stage.databaseString
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
    let fileNames = (self.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.compactMap { $0.fileName } ?? []
    let sortedFileName = fileNames.sorted { extractNumericValue(from: $0) < extractNumericValue(from: $1) }
    return fileNames.sorted { extractNumericValue(from: $0) < extractNumericValue(from: $1) }
  }
  
  /// Used to get file chunk info from the voice entry
  /// - Returns: An array of file chunk info dictionaries, each containing one file name as the key, sorted by file name in ascending order
  func getChunksInfo() -> [[String: ChunkInfo]] {
    var chunkInfoList: [[String: ChunkInfo]] = []
    
    (self.toVoiceChunkInfo as? Set<VoiceChunkInfo>)?.forEach {
      if let fileName = $0.fileName {
        let fileChunkInfo: [String: ChunkInfo] = [
          fileName: ChunkInfo(
            st: $0.startTime ?? "",
            et: $0.endTime ?? ""
          )
        ]
        chunkInfoList.append(fileChunkInfo)
      }
    }
    
    return chunkInfoList.sorted { dict1, dict2 in
      let numericValue1 = extractNumericValue(from: dict1.keys.first ?? "")
      let numericValue2 = extractNumericValue(from: dict2.keys.first ?? "")
      return numericValue1 < numericValue2
    }
  }
  
  /// Extracts numeric value from file name (e.g. "1.m4a" -> 1, "10.m4a" -> 10)
  private func extractNumericValue(from fileName: String) -> Int {
    Int(fileName.components(separatedBy: ".").first ?? "") ?? 0
  }
}
