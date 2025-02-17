//
//  JSONHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//


import Foundation

public final class JSONHelper {
  
  public init() {}
  
  /// Returns pretty printed json string from Any Object
  public func prettyPrintedJSONString(from object: Any?) -> String? {
    guard let object else { return nil }
    // Ensure the object is a valid JSON object (either Dictionary or Array)
    guard JSONSerialization.isValidJSONObject(object) else {
      print("Invalid JSON object")
      return nil
    }
    
    do {
      // Convert the JSON object to Data with pretty printing option
      let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
      
      // Convert the Data to a String
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        return jsonString
      } else {
        print("Failed to convert JSON data to string")
        return nil
      }
    } catch {
      print("Error serializing JSON object: \(error)")
      return nil
    }
  }
}