
//
//  EkaScribeLimitView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/07/25.
//

import SwiftUI

public struct EkaScribeLimitView: View {
  // MARK: - Properties
  public let header: String
  public let buttonImage: String?
  public let buttonText: String
  public let onTapCta: () -> Void
  
  // MARK: - Init
  public init(header: String, buttonImage: String?, buttonText: String, onTapCta: @escaping () -> Void) {
    self.header = header
    self.buttonImage = buttonImage
    self.buttonText = buttonText
    self.onTapCta = onTapCta
  }
  
  // MARK: - Body
  
  public var body: some View{
      VStack {
        Image(.ekaScribeLimitPhone)
          .resizable()
          .scaledToFit()
        // Main message
        Text(header)
          .textStyle(ekaFont: .title1Bold, color: .black)
          .fixedSize(horizontal: false, vertical: true)
        
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
            if let buttonImage {
              Image(systemName: buttonImage)
                .foregroundStyle(Color.white)
            }
            Text(buttonText)
              .textStyle(ekaFont: .bodyBold, color: .white)
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color(.primary500))
          .foregroundColor(.white)
          .cornerRadius(14)
          .padding(.horizontal)
        }
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 16)
      }
      .background(Color(.neutrals50))
  }
  
  @ViewBuilder
  func featureCard(icon: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: icon)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .foregroundStyle(Color(.primary500))
        .frame(width: 22, height: 22)
        .padding(.top, 12)
      Spacer()
      Text(text)
        .textStyle(ekaFont: .bodyRegular, color: .black)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding()
    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 200 : .infinity, alignment: .leading)
    .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 150)
    .background(Color(.neutrals50))
    .cornerRadius(12)
    .addBorderWithGivenCornerRadius(cornerRadius: 12, borderColor: UIColor(resource: .neutrals200), strokeWidth: 0.5)
  }
}
