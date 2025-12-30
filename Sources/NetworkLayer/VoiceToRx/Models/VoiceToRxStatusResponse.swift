//
//  VoiceToRxStatusResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

public struct VoiceToRxStatusResponse: Codable {
 public var data: VoiceToRxStatusData?
}

public struct VoiceToRxStatusData: Codable {
  public var output: [VoiceToRxOutput]?
  public var templateResults: TemplateResults?
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

  public var custom: [VoiceToRxOutput]?
  public var transcript: [VoiceToRxOutput]?
  
  enum CodingKeys: String, CodingKey {
    case custom
    case transcript
  }
}

public struct VoiceToRxOutput: Codable {
  public var templateID, value, name: String?
  public let type: TemplateType?
  public let status: String?
  public let errors, warnings: [VoiceToRxError]
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
    case value, type, name, status, errors, warnings
  }
}

// MARK: - Error
public struct VoiceToRxError: Codable {
 public var type, msg, code: String?
}

public struct AudioMatrix: Codable {
    public let quality: Double?
}

public enum TemplateType: String, Codable {
  case json, custom, markdown, transcript
}
