//
//  ConfigResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/12/25.
//


public struct ConfigResponse: Codable {
  public let data: ConfigData
}

public struct ConfigData: Codable {
  public let supportedLanguages, supportedOutputFormats: [ResponseId]?
  public let consultationModes: [ResponseId]?
  public let maxSelection: MaxSelection?
  public let settings: Settings?
  public let selectedPreferences: SelectedPreferences?
  public let myTemplates: [ResponseId]?
  public let userDetails: UserDetails?
  
  enum CodingKeys: String, CodingKey {
    case supportedLanguages = "supported_languages"
    case supportedOutputFormats = "supported_output_formats"
    case consultationModes = "consultation_modes"
    case maxSelection = "max_selection"
    case settings
    case selectedPreferences = "selected_preferences"
    case myTemplates = "my_templates"
    case userDetails = "user_details"
  }
}

public struct MaxSelection: Codable {
  public let supportedLanguages, supportedOutputFormats, consultationModes: Int?
  
  enum CodingKeys: String, CodingKey {
    case supportedLanguages = "supported_languages"
    case supportedOutputFormats = "supported_output_formats"
    case consultationModes = "consultation_modes"
  }
}

public struct SelectedPreferences: Codable {
  public let autoDownload: Bool?
  public let languages: [ResponseId]?
  public let outputFormats: [ResponseId]?
  public let modelType: String?
  public let consultationMode: String?
  
  enum CodingKeys: String, CodingKey {
    case autoDownload = "auto_download"
    case languages
    case outputFormats = "output_formats"
    case modelType = "model_type"
    case consultationMode = "consultation_mode"
  }
}

public struct Settings: Codable {
  public let modelTrainingConsent: ModelTrainingConsent?
  
  enum CodingKeys: String, CodingKey {
    case modelTrainingConsent = "model_training_consent"
  }
}

public struct ModelTrainingConsent: Codable {
  public let value, editable: Bool?
}

public struct UserDetails: Codable {
  public let uuid, fn: String?
  public let mn: String?
  public let ln, dob, gen, s: String?
  public let wID, bID, wN: String?
  public let isPaidDoc: Bool?
  
  enum CodingKeys: String, CodingKey {
    case uuid, fn, mn, ln, dob, gen, s
    case wID = "w-id"
    case bID = "b-id"
    case wN = "w-n"
    case isPaidDoc = "is_paid_doc"
  }
}
