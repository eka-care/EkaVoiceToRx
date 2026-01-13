//
//  InputLanguageType.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 09/01/26.
//


public enum InputLanguageType: String, CaseIterable {
  case english = "en-IN"
  case hindi = "hi"
  case kannada = "kn"
  case tamil = "ta"
  case telugu = "te"
  case bengali = "bn"
  case malayalam = "ml"
  case gujarati = "gu"
  case marathi = "mr"
  case punjabi = "pa"
  
  var identifier: String { rawValue }

  var displayName: String {
    switch self {
    case .english: return "English"
    case .hindi: return "Hindi"
    case .kannada: return "Kannada"
    case .tamil: return "Tamil"
    case .telugu: return "Telugu"
    case .bengali: return "Bengali"
    case .malayalam: return "Malayalam"
    case .gujarati: return "Gujarati"
    case .marathi: return "Marathi"
    case .punjabi: return "Punjabi"
    }
  }

  public var id: String { rawValue }
}