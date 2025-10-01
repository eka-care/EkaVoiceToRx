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
  let modelType: String?
  let patientDetails: PatientDetails?
  
  enum CodingKeys: String, CodingKey {
    case mode, transfer
    case inputLanguage = "input_language"
    case s3URL = "s3_url"
    case outputFormatTemplate = "output_format_template"
    case modelType = "model_type"
    case patientDetails = "patient_details"
    case additionalData = "additional_data"
  }
}

// MARK: - OutputFormatTemplate
struct OutputFormatTemplate: Codable {
  let templateID: String
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
  }
}
