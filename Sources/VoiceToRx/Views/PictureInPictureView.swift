//
//  PictureInPictureView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//


import SwiftUI

public protocol PictureInPictureViewDelegate: AnyObject {
  func onTapResultDisplayView(success: Bool)
}

public struct PictureInPictureView: View {
  
  let title: String
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  weak var delegate: PictureInPictureViewDelegate?
  let onTapStop: () -> Void
  let onTapClose: () -> Void
  
  public init(
    title: String,
    voiceToRxViewModel: VoiceToRxViewModel,
    delegate: PictureInPictureViewDelegate?,
    onTapStop: @escaping () -> Void,
    onTapClose: @escaping () -> Void
  ) {
    self.title = title
    self.voiceToRxViewModel = voiceToRxViewModel
    self.delegate = delegate
    self.onTapStop = onTapStop
    self.onTapClose = onTapClose
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
    case .resultDisplay(let success):
      FloatingVoiceToRxResultView(
        success: success,
        onTapClose: onTapClose
      )
      .contentShape(Rectangle())
      .onTapGesture {
        delegate?.onTapResultDisplayView(success: success)
      }
    }
  }
}
