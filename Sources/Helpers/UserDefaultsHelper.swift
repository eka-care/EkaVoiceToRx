//
//  UserDefaultsHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 07/03/25.
//

import Foundation

final class UserDefaultsHelper {
  static func fetch<T>(valueOfType type: T.Type, usingKey key: String) -> T? {
    return UserDefaults.standard.value(forKey: key) as? T
  }

  static func save<T>(customValue value: T, withKey key: String) {
    UserDefaults.standard.setValue(value, forKey: key)
  }
}
