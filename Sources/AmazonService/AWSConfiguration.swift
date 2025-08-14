//
//  AWSConfiguration.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 04/03/25.
//


import AWSCore
import AWSS3
import Foundation

enum RecordingS3UploadConfiguration {
  static let bucketName = "m-prod-voice-record"
  static let domain = "s3://"
  static let transferUtilKey = "S3TransferUtility"
  static let s3ClientKey = "s3Client"
  
  static func getDateFolderName() -> String {
    return Date().toString(withFormat: "yyMMdd")
  }
  
  static func getS3Url(sessionID: UUID) -> String {
    "\(domain)\(bucketName)/\(getDateFolderName())/\(sessionID.uuidString)"
  }
}

final class AWSConfiguration {
  static let shared = AWSConfiguration()
  private init() {}
  
  var awsClient: AWSServiceConfiguration?
  private(set) var activeTransferKey: String?
  
  func configureAWSS3(credentials: Credentials) {
    guard let accessKeyID = credentials.accessKeyID,
          let secretKey = credentials.secretKey,
          let sessionToken = credentials.sessionToken else {
      print("❌ Missing AWS credentials")
      return
    }
    
    let sessionCredentials = AWSBasicSessionCredentialsProvider(
      accessKey: accessKeyID,
      secretKey: secretKey,
      sessionToken: sessionToken
    )
    
    let clientConfiguration = AWSServiceConfiguration(
      region: .APSouth1, // Change to your region
      credentialsProvider: sessionCredentials
    )
    awsClient = clientConfiguration
    
    let transferUtilityConfiguration = AWSS3TransferUtilityConfiguration()
    transferUtilityConfiguration.isAccelerateModeEnabled = false
    
    // Generate a NEW key each time credentials change
    let newKey = "S3TransferUtility-\(UUID().uuidString)"
    activeTransferKey = newKey
    
    AWSS3TransferUtility.register(
      with: clientConfiguration!,
      transferUtilityConfiguration: transferUtilityConfiguration,
      forKey: newKey
    )
    
    AWSS3.register(
      with: clientConfiguration!,
      forKey: "s3Client-\(UUID().uuidString)"
    )
    
    print("✅ Registered AWS S3 TransferUtility with key: \(newKey)")
  }
  
  func getTransferUtility() -> AWSS3TransferUtility? {
    guard let key = activeTransferKey else {
      print("❌ No active TransferUtility key set")
      return nil
    }
    return AWSS3TransferUtility.s3TransferUtility(forKey: key)
  }
}
