//
//  File.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 12/12/25.
//

import Foundation

public struct TemplateCreateAndEditRequest: Codable {
    public let title: String?
    public let desc: String?
    public let sectionIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title, desc
        case sectionIds = "section_ids"
    }
    
    public init(title: String = "", desc: String? = nil, sectionIds: [String] = []) {
        self.title = title
        self.desc = desc
        self.sectionIds = sectionIds
    }
}
