//
//  FloatingVoiceToRxDropdownView.swift
//  EkaVoiceToRx
//
//  Created by Assistant on 03/03/25.
//

import SwiftUI

struct FloatingVoiceToRxDropdownView: View {
  let onTapDone: () -> Void
  let onTapNotYet: () -> Void
  let onTapCancel: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      // Done button
      Button(action: {
        debugPrint("Done button tapped in dropdown")
        onTapDone()
      }) {
        HStack {
          Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
          Text("Yes I'm done")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      
      Divider()
        .background(Color.gray.opacity(0.3))
      
      // Not yet button
      Button(action: {
        debugPrint("Not yet button tapped in dropdown")
        onTapNotYet()
      }) {
        HStack {
          Image(systemName: "clock.fill")
          .foregroundColor(.orange)
          Text("Not yet")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      
      Divider()
        .background(Color.gray.opacity(0.3))
      
      // Cancel recording button
      Button(action: {
        debugPrint("Cancel button tapped in dropdown")
        onTapCancel()
      }) {
        HStack {
          Image(systemName: "xmark.circle.fill")
          .foregroundColor(.red)
          Text("Cancel recording")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
    }
    .background(Color.white)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .inset(by: 0.5)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    )
    .frame(width: 200)
  }
}
