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
  static let bucketName = "m-prod-voice2rx"
  static let domain = "s3://"
  static let transferUtilKey = "S3TransferUtility"
  static let s3ClientKey = "s3Client"
  
  static func getDateFolderName() -> String {
    return Date().toString(withFormat: "yyMMdd")
  }
}

final class AWSConfiguration {
  static let shared = AWSConfiguration()
  private init() {}
  var awsClient: AWSServiceConfiguration?
  
  func configureAWSS3(credentials: Credentials) {
    guard let accessKeyID = credentials.accessKeyID,
          let secretKey = credentials.secretKey,
          let sessionToken = credentials.sessionToken else { return }
    
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
    
    // Register transfer utility configuration
    let transferUtilityConfiguration = AWSS3TransferUtilityConfiguration()
    transferUtilityConfiguration.isAccelerateModeEnabled = false
    
    AWSS3TransferUtility.register(
      with: clientConfiguration!,
      transferUtilityConfiguration: transferUtilityConfiguration,
      forKey: RecordingS3UploadConfiguration.transferUtilKey
    )
    
    AWSS3.register(
      with: clientConfiguration!,
      forKey: RecordingS3UploadConfiguration.s3ClientKey
    )
  }
}
