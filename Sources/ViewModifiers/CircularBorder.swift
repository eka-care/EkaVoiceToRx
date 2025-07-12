//
//  CircularBorder.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/03/25.
//


import SwiftUI

struct CircularBorder: ViewModifier {
  var color: Color
  var lineWidth: CGFloat
  
  func body(content: Content) -> some View {
    content
      .overlay(
        Circle()
          .stroke(color, lineWidth: lineWidth)
      )
  }
}

struct CapsuleBorder: ViewModifier {
  var color: Color
  var lineWidth: CGFloat
  
  func body(content: Content) -> some View {
    content
      .overlay(
        Capsule()
          .stroke(color, lineWidth: lineWidth)
      )
  }
}

extension View {
  func addCircularBorder(color: Color, lineWidth: CGFloat) -> some View {
    self.modifier(CircularBorder(color: color, lineWidth: lineWidth))
  }
  
  func addCapsuleBorder(color: Color, lineWidth: CGFloat = 1) -> some View {
    self.modifier(CapsuleBorder(color: color, lineWidth: lineWidth))
  }
}

struct BorderWithCornerRadius: ViewModifier {
  let cornerRadius: CGFloat
  let borderColor: UIColor
  let strokeWidth: CGFloat
  
  func body(content: Content) -> some View {
    content
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color(borderColor), lineWidth: strokeWidth)
      )
  }
}

extension View {
  public func addBorderWithCornerRadius(
    cornerRadius: CGFloat,
    borderColor: UIColor,
    strokeWidth: CGFloat = 1
  ) -> some View {
    modifier(
      BorderWithCornerRadius(
        cornerRadius: cornerRadius,
        borderColor: borderColor,
        strokeWidth: strokeWidth
      )
    )
  }
}
