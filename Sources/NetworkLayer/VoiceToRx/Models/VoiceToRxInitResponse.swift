//
//  VoiceToRxInitResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

struct VoiceToRxInitResponse: Codable {
  let status, message, txnID: String?
  
  enum CodingKeys: String, CodingKey {
    case status, message
    case txnID = "txn_id"
  }
}
