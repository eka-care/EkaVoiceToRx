//
//  VoiceToRxContextParams.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import Foundation

/// Context Params
public struct VoiceToRxContextParams: Codable {
  public let doctor: VoiceToRxDoctorProfileInfo?
  public let patient: VoiceToRxPatientProfileInfo?
  public let visitId: String?
  
  enum CodingKeys: String, CodingKey {
    case doctor = "doctor"
    case patient = "patient"
    case visitId = "visitid"
  }
}

/// Doctor Info

public struct VoiceToRxDoctorProfileInfo: Codable {
  public let id: String?
  public let profile: VoiceToRxDoctorProfile?
  
  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case profile = "profile"
  }
}

public struct VoiceToRxDoctorProfile: Codable {
  public let personal: VoiceToRxDoctorPersonal?
}

public struct VoiceToRxDoctorPersonal: Codable {
  public let name: VoiceToRxDoctorName?
}

public struct VoiceToRxDoctorName: Codable {
  public let lastName: String?
  public let firstName: String?
  
  enum CodingKeys: String, CodingKey {
    case lastName = "l"
    case firstName = "f"
  }
}

/// Patient Info

public struct VoiceToRxPatientProfileInfo: Codable {
  public let id: String?
  public let profile: VoiceToRxPatientProfile?
}

public struct VoiceToRxPatientProfile: Codable {
  public let personal: VoiceToRxPatientPersonal?
}

public struct VoiceToRxPatientPersonal: Codable {
  public let name: String?
}
