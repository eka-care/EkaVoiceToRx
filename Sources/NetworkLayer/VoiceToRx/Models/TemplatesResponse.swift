//
//  TemplatesResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/12/25.
//


public struct TemplatesResponse: Codable {
    public let data: TemplateData
}

public struct TemplateData: Codable {
    public let myTemplates: [ResponseId]

    enum CodingKeys: String, CodingKey {
        case myTemplates = "my_templates"
    }
}

public struct ResponseId: Codable {
  public let id, name: String
  public let desc: String?
}
