//
//  FloatingVoiceToRxProcessingView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//

import SwiftUI

struct FloatingVoiceToRxProcessingView: View {
  var body: some View {
    HStack {
      Image(.colorDocAssist)
      Text("Analysing conversation...")
        .lineLimit(1)
        .font(Font.custom("Lato", size: 14))
    }
    .padding()
    .frame(width: 250)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 245/255, green: 235/255, blue: 255/255),
          Color.white
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .cornerRadius(20)
    .shadow(color: .black.opacity(0.24), radius: 25, x: 0, y: 8)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .inset(by: 0.5)
        .stroke(.white, lineWidth: 1)
      
    )
    .blur(radius: 8)
  }
}
