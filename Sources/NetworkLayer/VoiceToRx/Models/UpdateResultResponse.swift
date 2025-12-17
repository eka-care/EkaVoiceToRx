//
//  UpdateResultResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 17/12/25.
//


public struct UpdateResultResponse: Codable {
    public let status, message, txnID, bID: String

    enum CodingKeys: String, CodingKey {
        case status, message
        case txnID = "txn_id"
        case bID = "b_id"
    }
}
