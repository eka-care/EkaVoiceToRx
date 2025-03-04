//
//  PictureInPictureView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//


import SwiftUI

public struct PictureInPictureView: View {
  
  let voiceToRxViewModel: VoiceToRxViewModel
  let stopVoiceRecording:() -> Void
  
  init(
    voiceToRxViewModel: VoiceToRxViewModel,
    stopVoiceRecording: @escaping () -> Void
  ) {
    self.voiceToRxViewModel = voiceToRxViewModel
    self.stopVoiceRecording = stopVoiceRecording
  }
  
  public var body: some View {
    switch voiceToRxViewModel.screenState {
    case .retry, .startRecording:
      EmptyView()
    case .listening(let conversationType):
      FloatingVoiceToRxRecordingView(
        name: "Amit Bhart",
        voiceToRxViewModel: voiceToRxViewModel,
        stopVoiceRecording: {}
      )
    case .processing:
      FloatingVoiceToRxProcessingView()
    case .resultDisplay(let success):
      FloatingVoiceToRxResultView(success: success)
    }
  }
}
