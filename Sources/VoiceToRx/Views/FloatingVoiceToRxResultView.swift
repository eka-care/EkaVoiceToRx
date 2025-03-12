//
//  FloatingVoiceToRxResultView.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 04/03/25.
//

import SwiftUI

struct FloatingVoiceToRxResultView: View {
  
  var success: Bool
  let onTapClose: () -> Void
  
  var body: some View {
    HStack(spacing: 10) {
      Image(success ? .smartReportSuccess :  .smartReportFailure)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(success ? "Smart notes are ready!" : "Audio analysis failed.")
          .textStyle(ekaFont: .calloutRegular, color: .black)
        
        Text(success ? "Tap to View" : "Tap to try again ")
          .textStyle(ekaFont: .calloutBold, color: UIColor(resource: .primary500))
      }
      
      Spacer()
    }
    .padding()
    .frame(width: 250)
    .background(
      LinearGradient(
        gradient: Gradient(
          colors: [ success ?
                    Color(
                      red: 235/255,
                      green: 250/255,
                      blue: 240/255
                    ) : Color(
                      red: 250/255,
                      green: 235/255,
                      blue: 235/255
                    ),
                    Color.white
                  ]
        ),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .addCircularBorder(color: .white, lineWidth: 1)
    .shadow(color: .black.opacity(0.24), radius: 25, x: 0, y: 8)
  }
}
