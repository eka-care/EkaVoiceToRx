//
//  UIViewController.swift
//  EkaVoiceToRx
//
//  Created by Brunda  B on 16/09/25.
//
import UIKit

extension UIViewController {
  func topMostViewController() -> UIViewController {
    if let presented = self.presentedViewController {
      return presented.topMostViewController()
    }
    if let nav = self as? UINavigationController {
      return nav.visibleViewController?.topMostViewController() ?? nav
    }
    if let tab = self as? UITabBarController {
      return tab.selectedViewController?.topMostViewController() ?? tab
    }
    return self
  }
}
