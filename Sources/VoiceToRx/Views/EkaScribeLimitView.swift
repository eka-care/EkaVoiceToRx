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
  
  public var body: some View {
    Group {
      if UIDevice.current.userInterfaceIdiom == .pad {
        cardContent
          .padding()
          .frame(maxWidth: 500, maxHeight: .infinity)
          .background(Color(.neutrals100))
      } else {
        cardContent
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.neutrals50))
      }
    }
  }
  
  // MARK: - Card Content
  private var cardContent: some View {
    VStack(spacing: 24) {
      // Top Illustration
      Image(.ekaScribeLimit)
        .resizable()
        .scaledToFit()
        .frame(height: 180)
      
      // Main message
      Text(header)
        .textStyle(ekaFont: .title1Bold, color: .black)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
      // Feature Grid
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        featureCard(icon: "doc.text.magnifyingglass", text: "Get medically relevant data from voice")
        featureCard(icon: "doc.text", text: "Get medical notes transcribed easily")
        featureCard(icon: "lock.shield", text: "We never store your voice recordings")
        featureCard(icon: "square.and.arrow.up", text: "Share the output with patients easily")
      }
      .padding(.horizontal)
      
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
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.primary500))
        .cornerRadius(14)
      }
      .padding(.horizontal)
    }
    .padding(.vertical, 24)
    .background(Color(.neutrals50))
    .cornerRadius(24)
    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
  }
  
  // MARK: - Feature Card
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
    .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
    .background(Color(.neutrals50))
    .cornerRadius(12)
    .addBorderWithGivenCornerRadius(
      cornerRadius: 12,
      borderColor: UIColor(resource: .neutrals200),
      strokeWidth: 0.5
    )
  }
}
