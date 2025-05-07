//
//  RefreshResponse.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//


import Foundation

// MARK: - RefreshResponse
struct RefreshResponse: Codable {
  let success: Bool?
  let data: RefreshDataClass?
}

// MARK: - DataClass
struct RefreshDataClass: Codable {
  let resJwt: String?
  let profile: RefreshProfile?
  let sess, refresh: String?
  let new: Bool?
  let firebaseToken: String?
  
  enum CodingKeys: String, CodingKey {
    case firebaseToken = "firebase_token"
    case resJwt, profile, sess, refresh, new
  }
}

// MARK: - Profile
struct RefreshProfile: Codable {
  let uuid, mobile: String?
  let isP: Bool?
  let mn, ln, at: String?
  let dobValid: Bool?
  let dob, fn, oid, gen: String?
  
  enum CodingKeys: String, CodingKey {
    case uuid, mobile
    case isP = "is-p"
    case mn, ln, at
    case dobValid = "dob-valid"
    case dob, fn, oid, gen
  }
}