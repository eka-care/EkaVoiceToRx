//
//  FontRegistration.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/03/25.
//

import UIKit
import CoreGraphics
import CoreText

enum FontError: Swift.Error {
  case failedToRegisterFont
}

/// Used to register a font with the system
/// - Parameter name: Name of the font to register
/// - Throws: Throws an error if the font registration fails
func registerFont(named name: String) throws {
  // Attempt to load the font asset from the .xcassets
  guard let asset = NSDataAsset(name: "Fonts/\(name)", bundle: Bundle.module) else {
    throw FontError.failedToRegisterFont
  }
  
  // Create a CGFont from the asset data
  guard let provider = CGDataProvider(data: asset.data as CFData),
        let font = CGFont(provider) else {
    throw FontError.failedToRegisterFont
  }
  
  // Register the font with the system
  var error: Unmanaged<CFError>?
  if !CTFontManagerRegisterGraphicsFont(font, &error) {
    throw error?.takeRetainedValue() ?? FontError.failedToRegisterFont
  }
}

public struct Fonts {
  enum CustomFontNames: String, CaseIterable {
    case italic = "Lato-Italic"
    case lightItalic = "Lato-LightItalic"
    case thin = "Lato-Thin"
    case bold = "Lato-Bold"
    case black = "Lato-Black"
    case regular = "Lato-Regular"
    case blackItalic = "Lato-BlackItalic"
    case boldItalic = "Lato-BoldItalic"
    case light = "Lato-Light"
    case thinItalic = "Lato-ThinItalic"
  }
  
  public static func registerAllFonts() throws {
    try CustomFontNames.allCases.forEach {
      try registerFont(named: $0.rawValue)
    }
  }
}

enum EkaFont {
  
  // MARK: - Default
  
  case displayRegular
  case largeTitleRegular
  case title1Regular
  case title2Regular
  case title3Regular
  case headlineBold
  case bodyRegular
  case subheadlineRegular
  case calloutRegular
  case footnoteRegular
  case labelRegular
  case caption1Medium
  case caption2SemiBold
  
  // MARK: - Emphasis
  
  case displayBold
  case largeTitleBold
  case title1Bold
  case title2Bold
  case title3Bold
  case headlineExtraBold
  case bodyBold
  case subheadlineBold
  case calloutBold
  case footnoteBold
  case labelBold
  case caption1Bold
  case caption2ExtraBold
  
  // MARK: - Italics
  
  case bodyItalics
  case calloutItalics
  case footnoteItalics
  
  // MARK: - Font
  
  var font: UIFont {
    switch self {
    case .displayRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 51.0)!
    case .largeTitleRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 34.0)!
    case .title1Regular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 28.0)!
    case .title2Regular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 24.0)!
    case .title3Regular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 20.0)!
    case .headlineBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 18.0)!
    case .bodyRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 16.0)!
    case .subheadlineRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 15.0)!
    case .calloutRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 14.0)!
    case .footnoteRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 13.0)!
    case .labelRegular:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 12.0)!
    case .caption1Medium:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 12.0)!
    case .caption2SemiBold:
      return UIFont(name: Fonts.CustomFontNames.regular.rawValue, size: 11.0)!
      
    case .displayBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 51.0)!
    case .largeTitleBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 34.0)!
    case .title1Bold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 28.0)!
    case .title2Bold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 24.0)!
    case .title3Bold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 20.0)!
    case .headlineExtraBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 18.0)!
    case .bodyBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 16.0)!
    case .subheadlineBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 15.0)!
    case .calloutBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 14.0)!
    case .footnoteBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 13.0)!
    case .labelBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 12.0)!
    case .caption1Bold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 51.0)!
    case .caption2ExtraBold:
      return UIFont(name: Fonts.CustomFontNames.bold.rawValue, size: 11.0)!
      
    case .bodyItalics:
      return UIFont(name: Fonts.CustomFontNames.italic.rawValue, size: 16.0)!
    case .calloutItalics:
      return UIFont(name: Fonts.CustomFontNames.italic.rawValue, size: 14.0)!
    case .footnoteItalics:
      return UIFont(name: Fonts.CustomFontNames.italic.rawValue, size: 13.0)!
    }
  }
}
