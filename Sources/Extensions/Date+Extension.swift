//
//  Date+Extension.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import Foundation

extension Date {
  /// Returns date in specified format
  func toString(withFormat format: String = "YYYY-MM-dd") -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    dateFormatter.timeZone = .current
    return dateFormatter.string(from: self)
  }
  
  /// Returns date in `yyyy-MM-dd'T'HH:mm:ssZ` format
  func toISO8601DateString() -> String {
    let formatter = ISO8601DateFormatter()
    return formatter.string(from: self)
  }
  
  /// Returns date in `yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'` format
  func toIsoDateStringWithMilliSeconds() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    let formattedDate = formatter.string(from: self)
    return formattedDate
  }
}
