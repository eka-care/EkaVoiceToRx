//
//  FloatingVoiceToRxViewController.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//

import UIKit
import SwiftUI
import Combine
import AVFoundation
import WebKit

public protocol FloatingVoiceToRxDelegate: AnyObject {
  func onCreateVoiceToRxSession(id: UUID?, params: VoiceToRxContextParams?, error: APIError?)
  func moveToDeepthoughtPage(id: UUID)
  func errorReceivingPrescription(
    id: UUID,
    errorCode: VoiceToRxErrorCode,
    transcriptText: String
  )
  func updateAppointmentsData(appointmentID: String, voiceToRxID: String)
}

public protocol LiveActivityDelegate: AnyObject {
  func startLiveActivity(patientName: String) async
  func endLiveActivity() async
}

// TODO: - To refractor this for loading view etc

public class FloatingVoiceToRxViewController: UIViewController {
  private(set) var button: UIView!
  private let window: FloatingButtonWindow = FloatingButtonWindow()
  public static let shared: FloatingVoiceToRxViewController = FloatingVoiceToRxViewController()
  private var initialButtonCenter: CGPoint?
  public var viewModel: VoiceToRxViewModel?
  public weak var liveActivityDelegate: LiveActivityDelegate?
  var cancellables = Set<AnyCancellable>()
  let keyWindow = UIApplication.shared.connectedScenes
    .compactMap({ $0 as? UIWindowScene })
    .flatMap({ $0.windows })
    .first(where: { $0.isKeyWindow })
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  public init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  public func showFloatingButton(
    viewModel: VoiceToRxViewModel,
    conversationType: String,
    inputLanguage: [String],
    templateId: [String],
    liveActivityDelegate: LiveActivityDelegate?
  ) async {    
    let success = await viewModel.startRecording(conversationType: conversationType, inputLanguage: inputLanguage, templateId: templateId)
    guard success else { return }
    window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
    window.isHidden = false
    window.rootViewController = self
    loadView(viewModel: viewModel)
    await MainActor.run { [weak self] in
      guard let self else { return }
      subscribeToScreenStates()
      self.liveActivityDelegate = liveActivityDelegate
    }
    getAmazonCredentials()
    Task {
      await liveActivityDelegate?.startLiveActivity(patientName: V2RxInitConfigurations.shared.subOwnerName ?? "Patient")
    }
  }
  
  public func hideFloatingButton() {
    viewModel?.clearSession()
    window.windowLevel = UIWindow.Level(rawValue: 0)
    window.isHidden = true
    window.rootViewController = self
    view.subviews.forEach { $0.removeFromSuperview() }
    Task {
      await liveActivityDelegate?.endLiveActivity()
    }
  }
  
  private func loadView(viewModel: VoiceToRxViewModel) {
    self.viewModel = viewModel
    guard let button = UIHostingController(
      rootView: PictureInPictureView(
        title: V2RxInitConfigurations.shared.subOwnerName ?? "Patient",
        voiceToRxViewModel: viewModel,
        delegate: self,
        onTapStop: handleStopButton,
        onTapClose: hideFloatingButton,
        onTapDone: handleDoneRecording,
        onTapNotYet: handleNotYetRecording,
        onTapCancel: handleCancelRecording,
        onDropdownStateChange: handleDropdownStateChange
      )
    ).view else {
      return
    }
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    button.frame = CGRect(x: (keyWindow?.frame.width ?? 0), y: (keyWindow?.frame.height ?? 0)/4, width: 200, height: 50)
    view.addSubview(button)
    self.button = button
    window.button = button
    
    animateToNearestCorner(button)
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    button.addGestureRecognizer(panGesture)
  }
  
  private func containsWKWebView(in view: UIView?) -> Bool {
    guard let view else { return false }
    if view is WKWebView { return true }
    return view.subviews.contains { containsWKWebView(in: $0) }
  }
  
  private func handleStopButton() {
    // This method is now handled by the dropdown in the recording view
    // The stop button now toggles the dropdown instead of showing an alert
  }
  
  private func handleDoneRecording() {
    debugPrint("handleDoneRecording called")
    Task { [weak self] in
      guard let self else { return }
      await viewModel?.stopRecording()
      await liveActivityDelegate?.endLiveActivity()
    }
  }
  
  private func handleNotYetRecording() {
    debugPrint("handleNotYetRecording called")
    // Just close the dropdown, no action needed
    // The dropdown will be closed automatically by the view
  }
  
  private func handleCancelRecording() {
    debugPrint("handleCancelRecording called")
    viewModel?.stopAudioRecording()
    Task {
      await liveActivityDelegate?.endLiveActivity()
    }
    if let sessionID = viewModel?.sessionID {
      viewModel?.deleteRecording(id: sessionID)
    }
    viewModel?.screenState = .deletedRecording
    hideFloatingButton()
  }
  
  private func handleDropdownStateChange(isDropdownOpen: Bool) {
    updateButtonFrame(isDropdownOpen: isDropdownOpen)
  }
  
  private func updateButtonFrame(isDropdownOpen: Bool) {
    guard let button = self.button else { return }
    
    let baseHeight: CGFloat = 50
    let dropdownHeight: CGFloat = 180 // Increased height for dropdown (3 items + padding + shadow + margins)
    let totalHeight = isDropdownOpen ? baseHeight + dropdownHeight + 20 : baseHeight // +20 for top padding and extra space
    
    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
      button.frame.size.height = totalHeight
    }, completion: nil)
  }
  
  
  @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    let buttonView = gesture.view!
    
    switch gesture.state {
    case .began:
      initialButtonCenter = buttonView.center
      
    case .changed:
      let translation = gesture.translation(in: view)
      buttonView.center = CGPoint(
        x: buttonView.center.x + translation.x,
        y: buttonView.center.y + translation.y
      )
      gesture.setTranslation(.zero, in: view)
      
      let screenBounds = UIScreen.main.bounds
      let halfButtonWidth = buttonView.bounds.width / 2
      let halfButtonHeight = buttonView.bounds.height / 2
      
      if buttonView.center.x < halfButtonWidth {
        buttonView.center.x = halfButtonWidth
      } else if buttonView.center.x > screenBounds.width - halfButtonWidth {
        buttonView.center.x = screenBounds.width - halfButtonWidth
      }
      
      if buttonView.center.y < halfButtonHeight {
        buttonView.center.y = halfButtonHeight
      } else if buttonView.center.y > screenBounds.height - halfButtonHeight {
        buttonView.center.y = screenBounds.height - halfButtonHeight
      }
      
    case .ended, .cancelled:
      animateToNearestCorner(buttonView)
      
    default:
      break
    }
  }
  
  private func animateToNearestCorner(_ buttonView: UIView) {
    let screenBounds = UIScreen.main.bounds
    let buttonWidth = buttonView.bounds.width
    let buttonHeight = buttonView.bounds.height
    let margin: CGFloat = 10.0
    
    let currentX = buttonView.center.x
    let currentY = buttonView.center.y
    
    let distanceToLeftEdge = currentX
    let distanceToRightEdge = screenBounds.width - currentX
    let distanceToTopEdge = currentY
    let distanceToBottomEdge = screenBounds.height - currentY
    
    let minDistance = min(distanceToLeftEdge, distanceToRightEdge, distanceToTopEdge, distanceToBottomEdge)
    
    var targetPoint = buttonView.center
    
    if let keyWindow {
      let safeAreaInsets = keyWindow.safeAreaInsets
      
      if minDistance == distanceToLeftEdge {
        targetPoint.x = buttonWidth / 2 + margin
      } else if minDistance == distanceToRightEdge {
        targetPoint.x = screenBounds.width - buttonWidth / 2 - margin
      } else if minDistance == distanceToTopEdge {
        targetPoint.y = max(safeAreaInsets.top + buttonHeight / 2 + margin, buttonHeight / 2 + margin)
      } else {
        targetPoint.y = screenBounds.height - buttonHeight / 2 - margin
      }
    }
    
    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
      buttonView.center = targetPoint
    }, completion: nil)
  }
  
  private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
    let xDistance = point1.x - point2.x
    let yDistance = point1.y - point2.y
    return sqrt(xDistance * xDistance + yDistance * yDistance)
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }
}

private class FloatingButtonWindow: UIWindow {
  var button: UIView?
  
  init() {
    super.init(frame: UIScreen.main.bounds)
    backgroundColor = nil
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      guard let button = button else { return false }
      if button.point(inside: convert(point, to: button), with: event) {
          return true
      }
      for subview in button.subviews {
          if subview.point(inside: convert(point, to: subview), with: event) {
              return true
          }
      }
      return false
  }
}

extension FloatingVoiceToRxViewController: PictureInPictureViewDelegate {
  public func onTapResultDisplayView(success: Bool) {
    guard let sessionID = viewModel?.sessionID else { return }
    if success {
      hideFloatingButton()
      viewModel?.voiceToRxDelegate?.moveToDeepthoughtPage(id: sessionID)
    }
  }
}

extension FloatingVoiceToRxViewController {
  private func subscribeToScreenStates() {
    viewModel?.$screenState.sink { [weak self] screenState in
      guard let self else { return }
      switch screenState {
      case .startRecording, .listening, .processing, .retry, .deletedRecording, .paused:
        debugPrint("Subscribed screen state is -> \(screenState)")
      case .resultDisplay:
        debugPrint("Subscribed screen state is -> \(screenState)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
          guard let self else { return }
          self.hideFloatingButton()
        }
      }
    }.store(in: &cancellables)
  }
}

extension FloatingVoiceToRxViewController {
  private func getAmazonCredentials() {
    viewModel?.getAmazonCredentials()
  }
}

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


