//
//  EkaScribeHistoryResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 23/09/25.
//

import Foundation

public struct EkaScribeHistoryResponse: Codable {
    public let status: Status
    public let data: [ScribeData]
    public let retrievedCount: Int?

    enum CodingKeys: String, CodingKey {
        case status, data
        case retrievedCount = "retrieved_count"
    }
}

public struct ScribeData: Codable {
  public let bID: String?
  public let createdAt: String?
  private let flavourString: String?
  private let modeString: String?
  public let oid: String?
  private let processingStatusString: String?
  public let txnID: String?
  private let userStatusString: String?
  public let uuid, version: String?
  public let patientDetails: PatientDetails?
  
  public var flavour: Flavour? {
    guard let flavourString else { return nil }
    return Flavour(rawValue: flavourString)
  }
  
  public var mode: Mode? {
    .init(rawValue: modeString ?? "")
  }
  
  public var processingStatus: ProcessingStatus? {
    .init(rawValue: processingStatusString ?? "")
  }
  
  public var userStatus: UserStatus? {
    .init(rawValue: userStatusString ?? "")
  }
  
  public enum CodingKeys: String, CodingKey {
    case bID = "b_id"
    case createdAt = "created_at"
    case flavourString = "flavour"
    case modeString = "mode"
    case oid
    case processingStatusString = "processing_status"
    case txnID = "txn_id"
    case userStatusString = "user_status"
    case uuid, version
    case patientDetails = "patient_details"
  }
}

public enum Flavour: String {
  case android
  case empty = ""
  case flavourExtension = "extension"
  case io
  case ip
  case web
  case scribeAndroid = "scribe-android"
  case scribeIOS = "scribe-ios"
}

public enum Mode: String {
  case consultation
  case dictation
}


public struct PatientDetails: Codable {
    public let oid: String?
    public let age: Int?
    public let biologicalSex, username: String?
}

public enum Status: String, Codable {
    case cancelled = "cancelled"
    case inProgress = "in-progress"
    case success = "success"
    case systemFailure = "system_failure"
}

public enum UserStatus: String {
    case commit
    case userInit = "init"
    case stopped
    case cancelled
}

public enum ProcessingStatus: String {
  case success
  case inProgress = "in-progress"
  case systemFailure = "system_failure"
  case requestFailure = "request_failure"
  case cancelled
}

