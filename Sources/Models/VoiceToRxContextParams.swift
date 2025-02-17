//
//  VoiceToRxContextParams.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import Foundation

/// Context Params
public struct VoiceToRxContextParams: Codable {
  let doctor: VoiceToRxDoctorProfileInfo?
  let patient: VoiceToRxPatientProfileInfo?
  let visitId: String?
  
  enum CodingKeys: String, CodingKey {
    case doctor = "doctor"
    case patient = "patient"
    case visitId = "visitid"
  }
}

/// Doctor Info

struct VoiceToRxDoctorProfileInfo: Codable {
  let id: String?
  let profile: VoiceToRxDoctorProfile?
  
  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case profile = "profile"
  }
}

struct VoiceToRxDoctorProfile: Codable {
  let personal: VoiceToRxDoctorPersonal?
}

struct VoiceToRxDoctorPersonal: Codable {
  let name: VoiceToRxDoctorName?
}

struct VoiceToRxDoctorName: Codable {
  let lastName: String?
  let firstName: String?
  
  enum CodingKeys: String, CodingKey {
    case lastName = "l"
    case firstName = "f"
  }
}

/// Patient Info

struct VoiceToRxPatientProfileInfo: Codable {
  let id: String?
  let profile: VoiceToRxPatientProfile?
}

struct VoiceToRxPatientProfile: Codable {
  let personal: VoiceToRxPatientPersonal?
}

struct VoiceToRxPatientPersonal: Codable {
  let name: String?
}
