//
//  ModelType.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 09/01/26.
//


public enum ModelType: String, CaseIterable {
  case pro = "pro"
  case lite = "lite"
  public var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .pro : return "Pro"
    case .lite : return "Lite"
    }
  }
}