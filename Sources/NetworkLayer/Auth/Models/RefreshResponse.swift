//
//  RefreshResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//


import Foundation

// MARK: - RefreshResponse
struct RefreshResponse: Codable {
  let refresh: String?
  let sess: String?
  
  enum CodingKeys: String, CodingKey {
    case refresh = "refresh_token"
    case sess = "access_token"
  }
}
 
