//
//  VoiceToRxStatusResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

public struct VoiceToRxStatusResponse: Codable {
  public let data: VoiceToRxStatusData?
}

public struct VoiceToRxStatusData: Codable {
  public let output: [VoiceToRxOutput]?
  public let templateResults: [VoiceToRxOutput]?
  public let additionalData: VoiceToRxContextParams?
  public let audioMatrix: AudioMatrix?
  
  enum CodingKeys: String, CodingKey {
    case output
    case templateResults = "template_results"
    case additionalData = "additional_data"
    case audioMatrix = "audio_matrix"
  }
}

public struct TemplateResults: Codable {

  public let custom: [VoiceToRxOutput]?
  
  enum CodingKeys: String, CodingKey {
    case custom
  }
}

public struct VoiceToRxOutput: Codable {
  public let templateID, value, name: String?
  public let type: TemplateType
  public let status: String?
  public let errors, warnings: [VoiceToRxError]
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
    case value, type, name, status, errors, warnings
  }
}

// MARK: - Error
public struct VoiceToRxError: Codable {
  public let type, msg, code: String?
}

public struct AudioMatrix: Codable {
    public let quality: Double?
}

public struct TemplateType: Codable {
  let json: String
  let custom: String
  let markdown: String
  
  enum CodingKeys: String, CodingKey {
    case json = "json"
    case custom = "custom"
    case markdown = "markdown"
  }
}
