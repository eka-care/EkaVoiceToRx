//
//  PictureInPictureView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//


import SwiftUI

public struct PictureInPictureView: View {
  
  let title: String
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let onTapStop: () -> Void
  
  init(
    title: String,
    voiceToRxViewModel: VoiceToRxViewModel,
    onTapStop: @escaping () -> Void
  ) {
    self.title = title
    self.voiceToRxViewModel = voiceToRxViewModel
    self.onTapStop = onTapStop
  }
  
  public var body: some View {
    switch voiceToRxViewModel.screenState {
    case .retry, .startRecording:
      EmptyView()
    case .listening:
      FloatingVoiceToRxRecordingView(
        name: title,
        voiceToRxViewModel: voiceToRxViewModel,
        onTapStop: onTapStop
      )
    case .processing:
      FloatingVoiceToRxProcessingView()
    case .resultDisplay(_, let success):
      FloatingVoiceToRxResultView(success: success)
    }
  }
}
