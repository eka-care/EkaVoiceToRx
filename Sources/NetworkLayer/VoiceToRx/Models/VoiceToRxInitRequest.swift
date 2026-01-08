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
public struct OutputFormatTemplate: Codable {
  public enum TemplateType: String {
    case defaultType = "default"
    case customType = "custom"
  }
  
  let templateID: String
  let templateType: String
  let templateName: String
  
  public init(
    templateID: String,
    templateType: TemplateType,
    templateName: String
  ) {
    self.templateID = templateID
    self.templateType = templateType.rawValue
    self.templateName = templateName
  }
  
  enum CodingKeys: String, CodingKey {
    case templateID = "template_id"
    case templateType = "template_type"
    case templateName = "template_name"
  }
}

