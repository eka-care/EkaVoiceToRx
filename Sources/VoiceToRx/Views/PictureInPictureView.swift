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
  let onTapDone: () -> Void
  let onTapNotYet: () -> Void
  let onTapCancel: () -> Void
  
  public init(
    title: String,
    voiceToRxViewModel: VoiceToRxViewModel,
    delegate: PictureInPictureViewDelegate?,
    onTapStop: @escaping () -> Void,
    onTapClose: @escaping () -> Void,
    onTapDone: @escaping () -> Void,
    onTapNotYet: @escaping () -> Void,
    onTapCancel: @escaping () -> Void
  ) {
    self.title = title
    self.voiceToRxViewModel = voiceToRxViewModel
    self.delegate = delegate
    self.onTapStop = onTapStop
    self.onTapClose = onTapClose
    self.onTapDone = onTapDone
    self.onTapNotYet = onTapNotYet
    self.onTapCancel = onTapCancel
  }
  
  public var body: some View {
    switch voiceToRxViewModel.screenState {
    case .retry, .startRecording, .deletedRecording:
      EmptyView()
    case .listening, .paused:
      FloatingVoiceToRxRecordingView(
        name: title,
        voiceToRxViewModel: voiceToRxViewModel,
        onTapStop: onTapStop,
        onTapDone: onTapDone,
        onTapNotYet: onTapNotYet,
        onTapCancel: onTapCancel
      )
    case .processing:
      FloatingVoiceToRxProcessingView()
    case .resultDisplay(let success, let value):
      FloatingVoiceToRxResultView(
        success: success,
        value: value,
        onTapClose: onTapClose
      )
      .contentShape(Rectangle())
      .onTapGesture {
        delegate?.onTapResultDisplayView(success: success)
      }
    }
  }
}
