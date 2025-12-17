//
//  UpdateResultRequest.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 17/12/25.
//


public struct UpdateResultRequest: Codable {
  public let template: String
  public let data: String
  
  enum CodingKeys: String, CodingKey  {
    case template = "template-id"
    case data
  }
}