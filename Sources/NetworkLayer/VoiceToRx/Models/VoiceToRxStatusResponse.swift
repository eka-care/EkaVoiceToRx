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
  public let additionalData: VoiceToRxContextParams?
  
  enum CodingKeys: String, CodingKey {
    case output
    case additionalData = "additional_data"
  }
}

public struct VoiceToRxOutput: Codable {
  public let templateID, value, type, name: String?
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
