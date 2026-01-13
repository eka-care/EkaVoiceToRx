//
//  RecordConsultationState.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 09/01/26.
//


public enum RecordConsultationState: Equatable {
  case retry
  case startRecording
  case listening(conversationType: VoiceConversationType)
  case paused
  case processing
  case resultDisplay(success: Bool, value: String?)
  case deletedRecording
  
  public static func == (lhs: RecordConsultationState, rhs: RecordConsultationState) -> Bool {
    switch (lhs, rhs) {
    case
      (.retry, .retry),
      (.startRecording, .startRecording),
      (.processing, .processing),
      (.deletedRecording, .deletedRecording),
      (.paused, .paused):
      return true
    case (.listening(let lhsType), .listening(let rhsType)):
      return lhsType == rhsType
    case (.resultDisplay(let lhsSuccess), .resultDisplay(let rhsSuccess)):
      return lhsSuccess == rhsSuccess
    default:
      return false
    }
  }
}