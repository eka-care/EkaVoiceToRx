//
//  TextStyle.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/03/25.
//


import SwiftUI

struct TextStyle: ViewModifier {
  let ekaFont: EkaFont
  let uiColor: UIColor
  
  init(ekaFont: EkaFont, uiColor: UIColor) {
    self.ekaFont = ekaFont
    self.uiColor = uiColor
  }
  
  func body(content: Content) -> some View {
    content
      .font(Font(ekaFont.font))
      .foregroundColor(Color(uiColor))
  }
}

extension View {
  func textStyle(ekaFont: EkaFont, color: UIColor) -> some View {
    modifier(TextStyle(ekaFont: ekaFont, uiColor: color))
  }
}