//
//  ConfigResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/12/25.
//


struct ConfigResponse: Codable {
    let data: ConfigData
}

struct ConfigData: Codable {
    let supportedLanguages, supportedOutputFormats: [ResponseId]?
    let consultationModes: [ResponseId]?
    let maxSelection: MaxSelection?
    let settings: Settings?
    let selectedPreferences: SelectedPreferences?
    let myTemplates: [ResponseId]?
    let userDetails: UserDetails?

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

struct MaxSelection: Codable {
    let supportedLanguages, supportedOutputFormats, consultationModes: Int?

    enum CodingKeys: String, CodingKey {
        case supportedLanguages = "supported_languages"
        case supportedOutputFormats = "supported_output_formats"
        case consultationModes = "consultation_modes"
    }
}

struct SelectedPreferences: Codable {
    let autoDownload: Bool?
    let languages: [ResponseId]?
    let outputFormats: [ResponseId]?
    let modelType: String?
    let consultationMode: String?

    enum CodingKeys: String, CodingKey {
        case autoDownload = "auto_download"
        case languages
        case outputFormats = "output_formats"
        case modelType = "model_type"
        case consultationMode = "consultation_mode"
    }
}

struct Settings: Codable {
    let modelTrainingConsent: ModelTrainingConsent?

    enum CodingKeys: String, CodingKey {
        case modelTrainingConsent = "model_training_consent"
    }
}

struct ModelTrainingConsent: Codable {
    let value, editable: Bool?
}

struct UserDetails: Codable {
    let uuid, fn: String?
    let mn: String?
    let ln, dob, gen, s: String?
    let wID, bID, wN: String?
    let isPaidDoc: Bool?

    enum CodingKeys: String, CodingKey {
        case uuid, fn, mn, ln, dob, gen, s
        case wID = "w-id"
        case bID = "b-id"
        case wN = "w-n"
        case isPaidDoc = "is_paid_doc"
    }
}
