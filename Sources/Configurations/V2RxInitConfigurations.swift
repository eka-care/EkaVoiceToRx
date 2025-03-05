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
  
  /// Model container
  public var modelContainer: ModelContainer!
  
  // MARK: - Init
  
  private init() {}
}

