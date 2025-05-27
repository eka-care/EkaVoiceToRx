//
//  VoiceToRxStopRequest.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

struct VoiceToRxStopRequest: Codable {
  let audioFiles: [String]
  let fileChunksInfo: [String: FileChunkInfo]?
  
  enum CodingKeys: String, CodingKey {
    case audioFiles = "audio_files"
    case fileChunksInfo = "chunk_info"
  }
}
