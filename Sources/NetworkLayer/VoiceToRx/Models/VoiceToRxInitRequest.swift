//
//  VoiceToRxInitRequest.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

struct VoiceToRxInitRequest: Codable {
  let additionalData: VoiceToRxContextParams?
  let mode: String?
  let inputLanguage: [String]?
  let s3URL: String?
  let outputFormatTemplate: [OutputFormatTemplate]?
  let transfer: String?
  
  enum CodingKeys: String, CodingKey {
    case additionalData, mode, transfer
    case inputLanguage = "input_language"
    case s3URL = "s3_url"
    case outputFormatTemplate = "output_format_template"
  }
}

// MARK: - OutputFormatTemplate
struct OutputFormatTemplate: Codable {
  let templateID: String
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
  }
}
