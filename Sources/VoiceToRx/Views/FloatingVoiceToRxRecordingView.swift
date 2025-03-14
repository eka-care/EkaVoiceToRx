//
//  FloatingVoiceToRxRecordingView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 04/03/25.
//

import SwiftUI

struct FloatingVoiceToRxRecordingView: View {
  let name: String
  let voiceToRxViewModel: VoiceToRxViewModel
  let onTapStop: () -> Void
  
  @State private var elapsedTime: TimeInterval = 0
  @State private var timer: Timer?
  
  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading) {
        Text(name)
          .font(.system(size: 16, weight: .semibold))
        
        Text(formatTime(elapsedTime))
          .font(.system(size: 14))
          .foregroundColor(.gray)
      }
      
      Spacer()
      
      if let conversationType = voiceToRxViewModel.voiceConversationType,
         voiceToRxViewModel.screenState == .listening(conversationType: conversationType) {
        Image(systemName: "pause.fill")
          .resizable()
          .frame(width: 20, height: 20)
          .onTapGesture {
            voiceToRxViewModel.pauseRecording()
          }
      } else if let conversationType = voiceToRxViewModel.voiceConversationType,
                voiceToRxViewModel.screenState == .paused {
        Image(systemName: "play.fill")
          .resizable()
          .frame(width: 20, height: 20)
          .onTapGesture {
            Task {
              try await voiceToRxViewModel.resumeRecording()
            }
          }
      }
      
      Image(systemName: "stop.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 20, height: 20)
        .symbolRenderingMode(.palette) // Enables multi-color rendering
        .foregroundStyle(.white, .red) // First color is for the main shape, second for the inner part
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
        .onTapGesture {
          onTapStop()
        }
    }
    .padding()
    .background(
      LinearGradient(
        colors: [
          Color(red: 233/255, green: 237/255, blue: 254/255, opacity: 1.0),
          Color(red: 248/255, green: 239/255, blue: 251/255, opacity: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .frame(width: 250)
    .cornerRadius(20)
    .shadow(color: .black.opacity(0.24), radius: 25, x: 0, y: 8)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .inset(by: 0.5)
        .stroke(.white, lineWidth: 1)
      
    )
    .onAppear {
      startTimer()
    }
  }
  
  func startTimer() {
    timer?.invalidate()
    elapsedTime = 0
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      elapsedTime += 1
    }
  }
  
  func stopTimer() {
    timer?.invalidate()
    timer = nil
    elapsedTime = 0
  }
  
  func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
