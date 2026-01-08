//
//  ScribeTranslationResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 15/12/25.
//


struct ScribeTransactionResponse: Codable {
    let status, message, templateID, txnID: String
    let bID: String

    enum CodingKeys: String, CodingKey {
        case status, message
        case templateID = "template_id"
        case txnID = "txn_id"
        case bID = "b_id"
    }
}
