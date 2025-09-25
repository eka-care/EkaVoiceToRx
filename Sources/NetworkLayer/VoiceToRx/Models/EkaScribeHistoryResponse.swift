//
//  EkaScribeHistoryResponse.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 23/09/25.
//

import Foundation

struct EkaScribeHistoryResponse: Codable {
    let status: Status
    let data: [ScribeData]
    let retrievedCount: Int

    enum CodingKeys: String, CodingKey {
        case status, data
        case retrievedCount = "retrieved_count"
    }
}

struct ScribeData: Codable {
    let bID: String
    let createdAt: String
    let flavour: Flavour
    let mode: Mode
    let oid: String
    let processingStatus: Status
    let txnID: String
    let userStatus: UserStatus
    let uuid, version: String
    let patientDetails: PatientDetails?

    enum CodingKeys: String, CodingKey {
        case bID = "b_id"
        case createdAt = "created_at"
        case flavour, mode, oid
        case processingStatus = "processing_status"
        case txnID = "txn_id"
        case userStatus = "user_status"
        case uuid, version
        case patientDetails = "patient_details"
    }
}

enum Flavour: String, Codable {
    case android = "android"
    case empty = ""
    case flavourExtension = "extension"
    case io = "io"
    case ip = "ip"
    case web = "web"
}

enum Mode: String, Codable {
    case consultation = "consultation"
    case dictation = "dictation"
}

struct PatientDetails: Codable {
    let age: Int
    let biologicalSex, username: String
}

enum Status: String, Codable {
    case cancelled = "cancelled"
    case inProgress = "in-progress"
    case success = "success"
    case systemFailure = "system_failure"
}

enum UserStatus: String, Codable {
    case commit = "commit"
    case userStatusInit = "init"
}
