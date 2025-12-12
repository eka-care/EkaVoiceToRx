//
//  File.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 12/12/25.
//

import Foundation

public struct TemplateCreationResponse: Codable {
  public let msg: String
  public let templateID: String?
  
  enum CodingKeys: String, CodingKey {
      case msg
      case templateID = "template_id"
  }
}
