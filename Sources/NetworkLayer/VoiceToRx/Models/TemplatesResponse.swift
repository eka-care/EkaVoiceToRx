//
//  TemplatesResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/12/25.
//


struct TemplatesResponse: Codable {
    let data: TemplateData
}

struct TemplateData: Codable {
    let myTemplates: [ResponseId]

    enum CodingKeys: String, CodingKey {
        case myTemplates = "my_templates"
    }
}

struct ResponseId: Codable {
  let id, name: String
  let desc: String?
}
