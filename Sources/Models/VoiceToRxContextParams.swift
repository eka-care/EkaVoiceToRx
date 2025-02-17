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
  
  public init(
    doctor: VoiceToRxDoctorProfileInfo? = nil,
    patient: VoiceToRxPatientProfileInfo? = nil,
    visitId: String? = nil
  ) {
    self.doctor = doctor
    self.patient = patient
    self.visitId = visitId
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
  
  public init(
    id: String? = nil,
    profile: VoiceToRxDoctorProfile? = nil
  ) {
    self.id = id
    self.profile = profile
  }
}

public struct VoiceToRxDoctorProfile: Codable {
  public let personal: VoiceToRxDoctorPersonal?
  
  public init(personal: VoiceToRxDoctorPersonal? = nil) {
    self.personal = personal
  }
}

public struct VoiceToRxDoctorPersonal: Codable {
  public let name: VoiceToRxDoctorName?
  
  public init(name: VoiceToRxDoctorName? = nil) {
    self.name = name
  }
}

public struct VoiceToRxDoctorName: Codable {
  public let lastName: String?
  public let firstName: String?
  
  enum CodingKeys: String, CodingKey {
    case lastName = "l"
    case firstName = "f"
  }
  
  public init(
    lastName: String? = nil,
    firstName: String? = nil
  ) {
    self.lastName = lastName
    self.firstName = firstName
  }
}

/// Patient Info

public struct VoiceToRxPatientProfileInfo: Codable {
  public let id: String?
  public let profile: VoiceToRxPatientProfile?
  
  public init(
    id: String? = nil,
    profile: VoiceToRxPatientProfile? = nil
  ) {
    self.id = id
    self.profile = profile
  }
}

public struct VoiceToRxPatientProfile: Codable {
  public let personal: VoiceToRxPatientPersonal?
  
  public init(personal: VoiceToRxPatientPersonal? = nil) {
    self.personal = personal
  }
}

public struct VoiceToRxPatientPersonal: Codable {
  public let name: String?
  
  public init(name: String? = nil) {
    self.name = name
  }
}
