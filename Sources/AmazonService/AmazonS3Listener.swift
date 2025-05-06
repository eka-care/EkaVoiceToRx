//
//  AmazonS3Listener.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Foundation

final class AWSS3Listener {
  func readAndUpdateSession(sessionID: UUID) {
    Task {
      guard let model = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: QueryHelper.queryForFetch(with: sessionID)).first else { return }
      let folderPath = VoiceConversationModel.getFolderPath(model: model)
      let transcriptPath = "\(folderPath)/clinical_notes_summary.md"
      let structuredRxPath = "\(folderPath)/structured_rx_codified.json"
    }
//    do {
//      async let isTranscriptExist = checkFileExists(bucket: Voice2RxInternalUtils.bucketName, path: transcriptPath)
//      async let isStructuredRxExist = checkFileExists(bucket: Voice2RxInternalUtils.bucketName, path: structuredRxPath)
//      
//      let (transcriptExists, structuredRxExists) = try await (isTranscriptExist, isStructuredRxExist)
//      
//      if !transcriptExists && !structuredRxExists {
//        return
//      }
//      
//      async let transcript = readFile(bucket: Voice2RxInternalUtils.bucketName, path: transcriptPath)
//      async let structuredRx = readFile(bucket: Voice2RxInternalUtils.bucketName, path: structuredRxPath)
//      
//      let updatedSession = VToRxSession(
//        id: session.id,
//        transcript: try await transcript,
//        structuredRx: try await structuredRx,
//        isProcessed: true
//      )
//      
//      try await repository?.updateSession(session: updatedSession)
//      
//    } catch {
//      print("Error reading or updating session: \(error)")
//    }
  }
}
