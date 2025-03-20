//
//  V2RxInitConfigurations.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import SwiftData

public final class V2RxInitConfigurations {
  
  // MARK: - Properties
  
  public static let shared = V2RxInitConfigurations()
  
  /// Bucket name for Amazon S3
  public var awsS3BucketName: String?
  
  /// Name of the owner
  public var ownerName: String?
  
  /// UUID of the owner
  public var ownerUUID: String?
  
  /// Oid of the owner
  public var ownerOID: String?
  
  /// Name of the subOwner
  public var subOwnerName: String?
  
  /// Oid of the subOwner
  public var subOwnerOID: String?
  
  /// Model container
  public var modelContainer: ModelContainer!
  
  /// Caller id
  public var appointmentID: String?
  
  /// Voice to rx delegate
  public weak var voiceToRxDelegate: FloatingVoiceToRxDelegate?
  
  // MARK: - Init
  
  private init() {
    registerFonts()
  }
  
  private func registerFonts() {
    do {
      try Fonts.registerAllFonts()
    } catch {
      debugPrint("Failed to fetch fonts")
    }
  }
}

