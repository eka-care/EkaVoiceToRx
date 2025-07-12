
//
//  EkaScribeLimitView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/07/25.
//

import SwiftUI

public struct EkaScribeLimitView: View {
  // MARK: - Properties
  
  public let onTapCta: () -> Void
  
  // MARK: - Init
  
  public init(onTapCta: @escaping () -> Void) {
    self.onTapCta = onTapCta
  }
  
  // MARK: - Body
  
  public var body: some View {
    VStack(spacing: 24) {
      
      // Background with image and overlay
      ZStack {
        //        Image("EkaScribeBackground")
        //          .resizable()
        //          .scaledToFit()
        
        //        VStack(spacing: 16) {
        //          Image("waveformIcon")
        //            .resizable()
        //            .frame(width: 72, height: 72)
        //            .background(Circle().fill(Color.white))
        //            .shadow(radius: 4)
        //
        //          RoundedRectangle(cornerRadius: 20)
        //            .fill(Color.white.opacity(0.5))
        //            .frame(height: 160)
        //            .overlay(
        //              VStack(alignment: .leading, spacing: 8) {
        //                Label("Symptoms", systemImage: "cross.case")
        //                  .font(.headline)
        //                  .foregroundColor(.primary)
        //
        //                VStack(alignment: .leading, spacing: 4) {
        //                  Text("Fever").bold() + Text("  Since 2 Days").foregroundColor(.secondary)
        //                  Text("Cough").bold() + Text("  Since 7 Days").foregroundColor(.secondary)
        //                }
        //
        //                Text("+ Add another symptom")
        //                  .foregroundColor(.blue)
        //                  .font(.subheadline)
        //              }
        //                .padding()
        //            )
        //            .padding(.horizontal)
        //        }
        //        .padding(.top, 40)
      }
      .frame(height: 320)
      
      // Main message
      Text("You’re out of free Eka Scribe sessions for today!")
        .textStyle(ekaFont: .title1Bold, color: .black)
      
      // Feature list
      VStack(spacing: 16) {
        HStack(spacing: 16) {
          featureCard(icon: "doc.text.magnifyingglass", text: "Get medically relevant data from voice")
          featureCard(icon: "doc.text", text: "Get medical notes transcribed easily")
        }
        HStack(spacing: 16) {
          featureCard(icon: "lock.shield", text: "We never store your voice recordings")
          featureCard(icon: "square.and.arrow.up", text: "Share the output with patients easily")
        }
      }
      .padding(.horizontal)
      
      Spacer()
      
      // CTA Button
      Button(action: {
        onTapCta()
      }) {
        HStack {
          Image(systemName: "headphones")
            .foregroundStyle(Color.white)
          Text("Talk to sales to upgrade plan")
            .textStyle(ekaFont: .bodyBold, color: .white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(14)
        .padding(.horizontal)
      }
    }
    .padding(.vertical)
    .background(Color.white)
  }
  
  @ViewBuilder
  func featureCard(icon: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: icon)
        .renderingMode(.template)
        .foregroundStyle(Color.purple)
      Text(text)
        .textStyle(ekaFont: .bodyRegular, color: .black)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 120)
    .background(Color(UIColor.systemGray6))
    .cornerRadius(12)
  }
}

#Preview {
  EkaScribeLimitView(onTapCta: {})
}
