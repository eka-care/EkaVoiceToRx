//
//  EkaScribeError.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 02/01/26.
//


public enum EkaScribeError: Error {
  case microphonePermissionDenied
  case floatingButtonAlreadyPresented
  case freeSessionLimitReached
  case audioEngineStartFailed
  case vadDetectorFailed
  case noSessionId
  case audioSessionSetupFailed
}
