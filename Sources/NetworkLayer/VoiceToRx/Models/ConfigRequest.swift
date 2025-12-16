//
//  ConfigRequest.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/12/25.
//

struct ConfigRequest: Codable {
    let data: MyTemplatesData
    let requestType: String?

    enum CodingKeys: String, CodingKey {
        case data
        case requestType = "request_type"
    }
}

struct MyTemplatesData: Codable {
    let myTemplates: [String]

    enum CodingKeys: String, CodingKey {
        case myTemplates = "my_templates"
    }
}
