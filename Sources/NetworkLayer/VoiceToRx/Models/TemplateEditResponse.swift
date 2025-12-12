//
//  File.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 12/12/25.
//

import Foundation

public struct TemplateEditResponse: Codable {
  public let msg: String
  
  enum CodingKeys: CodingKey {
    case msg
  }
}
