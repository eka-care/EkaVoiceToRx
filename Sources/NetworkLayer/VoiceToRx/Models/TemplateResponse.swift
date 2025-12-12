//
//  TemplatesResponse.swift
//  EkaVoiceToRx
//
//  Created on 12/12/25.
//

import Foundation

public struct TemplateResponse: Codable {
    public let items: [Template]
}

public struct Template: Codable {
    public let id: String
    public let title: String
    public let desc: String?
    public let sectionIds: [String]?
    public let defaultTemplate: Bool
    public let isFavorite: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, title, desc
        case defaultTemplate = "default"
        case sectionIds = "section_ids"
        case isFavorite = "is_favorite"
    }
}

