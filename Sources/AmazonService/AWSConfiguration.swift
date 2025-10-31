//
//  AWSConfiguration.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 04/03/25.
//


import AWSS3
import AWSClientRuntime
import Foundation
import AWSSDKIdentity

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
  
  private(set) var s3Client: S3Client?
  private(set) var region: String = "ap-south-1"
  
  /// Configure AWS S3 using the AWS SDK for Swift (awslabs/aws-sdk-swift)
  func configureS3(credentials: Credentials, region: String = "ap-south-1") {
    guard let accessKeyID = credentials.accessKeyID,
          let secretKey = credentials.secretKey,
          let sessionToken = credentials.sessionToken else {
      print("❌ Missing AWS credentials")
      return
    }
    
    do {
      let identity = AWSCredentialIdentity(
        accessKey: accessKeyID,
        secret: secretKey,
        sessionToken: sessionToken
      )
      let resolver = StaticAWSCredentialIdentityResolver(identity)
      
      let config = try S3Client.S3ClientConfiguration(
        region: region
      )
      // Plug in explicit static credentials resolver so requests are signed with provided creds
      config.awsCredentialIdentityResolver = resolver
      
      self.s3Client = S3Client(config: config)
      self.region = region
      print("✅ Configured AWS S3Client for region: \(region)")
    } catch {
      print("❌ Failed to configure S3Client: \(error)")
    }
  }
  
  func getS3Client() -> S3Client? {
    s3Client
  }
}
