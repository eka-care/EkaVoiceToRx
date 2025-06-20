//
//  VoiceToRxCommitRequest.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

struct VoiceToRxCommitRequest: Codable {
  let audioFiles: [String]
  let chunkInfo: [[String: ChunkInfo]]
  
  enum CodingKeys: String, CodingKey {
    case audioFiles = "audio_files"
    case chunkInfo = "chunk_info"
  }
}
