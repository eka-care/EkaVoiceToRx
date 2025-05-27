//
//  VoiceToRxStatusResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

struct VoiceToRxStatusResponse: Codable {
  let data: VoiceToRxStatusData?
}

struct VoiceToRxStatusData: Codable {
  let output: [VoiceToRxOutput]?
  let additionalData: VoiceToRxContextParams?
  
  enum CodingKeys: String, CodingKey {
    case output
    case additionalData = "additional_data"
  }
}

struct VoiceToRxOutput: Codable {
  let templateID, value, type, name: String?
  let status: String?
  let errors, warnings: [VoiceToRxError]
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
    case value, type, name, status, errors, warnings
  }
}

// MARK: - Error
struct VoiceToRxError: Codable {
  let type, msg, code: String?
}
