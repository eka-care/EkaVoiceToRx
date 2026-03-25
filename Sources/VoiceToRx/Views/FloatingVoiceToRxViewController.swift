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
  func onVoiceToRxRecordingStarted()
  func onVoiceToRxRecordingEnded()
  func onResultValueReceived(value: String)
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
  
  // State tracking to prevent multiple windows
  private var isWindowActive: Bool = false
  private var isInitializing: Bool = false
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  private init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  /// Check if the floating window is currently active or initializing
  public var isFloatingWindowBusy: Bool {
    return isWindowActive || isInitializing
  }
  
  /// Convenience method to safely show floating button with completion handler
  public func showFloatingButtonSafely(
    viewModel: VoiceToRxViewModel,
    conversationType: VoiceConversationType,
    inputLanguage: [InputLanguageType],
    templates: [OutputFormatTemplate],
    modelType: ModelType,
    liveActivityDelegate: LiveActivityDelegate?,
    completion: @escaping (Bool) -> Void
  ) {
    Task {
      if isFloatingWindowBusy {
        debugPrint("FloatingVoiceToRxViewController: Cannot show floating button - window is busy")
        await MainActor.run {
          completion(false)
        }
        return
      }
      do {
        try await showFloatingButton(
          viewModel: viewModel,
          conversationType: conversationType,
          inputLanguage: inputLanguage,
          templates: templates,
          modelType: modelType,
          liveActivityDelegate: liveActivityDelegate
        )
        await MainActor.run {
          completion(isWindowActive)
        }
      } catch {
        debugPrint("Error showing floating button: \(error.localizedDescription)")
        await MainActor.run {
          completion(false)
        }
      }
    }
  }
  
  public func showFloatingButton(
    viewModel: VoiceToRxViewModel,
    conversationType: VoiceConversationType,
    inputLanguage: [InputLanguageType],
    templates: [OutputFormatTemplate],
    modelType: ModelType = .pro,
    liveActivityDelegate: LiveActivityDelegate?
  ) async throws {
    print("[V2RX DEBUG] showFloatingButton : isWindowActive : \(isWindowActive) | isInitializing : \(isInitializing) | sessionID : \(viewModel.sessionID?.uuidString ?? "nil")")
    guard !isWindowActive && !isInitializing else {
      print("[V2RX DEBUG] showFloatingButton : BLOCKED : isWindowActive : \(isWindowActive) | isInitializing : \(isInitializing)")
      debugPrint("FloatingVoiceToRxViewController: Window is already active or initializing. Ignoring duplicate call.")
      throw EkaScribeError.floatingButtonAlreadyPresented
    }

    isInitializing = true
    defer { isInitializing = false }
    do {
      try await viewModel.startRecording(conversationType: conversationType, inputLanguage: inputLanguage, templates: templates, modelType: modelType)
    } catch {
      print("[V2RX DEBUG] showFloatingButton : startRecording FAILED : error : \(error.localizedDescription)")
      let eventlog = EventLog(eventType: .startRecordingFloatingButton,message: error.localizedDescription, status: .failure, platform: .network)
      V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventlog)
      throw error
      return
    }

    print("[V2RX DEBUG] showFloatingButton : startRecording SUCCESS : sessionID : \(viewModel.sessionID?.uuidString ?? "nil") | screenState : \(viewModel.screenState)")
    let eventlog = EventLog(
      params: ["session_id": viewModel.sessionID?.uuidString ?? "nil", "screen_state": "\(viewModel.screenState)"],
      eventType: .floatingButtonShow,
      message: "showFloatingButton : sessionID : \(viewModel.sessionID?.uuidString ?? "nil")",
      status: .success,
      platform: .network
    )
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventlog)

    isWindowActive = true
    window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
    window.isHidden = false
    window.rootViewController = self
    loadView(viewModel: viewModel)
    await MainActor.run { [weak self] in
      self?.subscribeToScreenStates()
      self?.liveActivityDelegate = liveActivityDelegate
    }
    isInitializing = false
    await liveActivityDelegate?.startLiveActivity(patientName: V2RxInitConfigurations.shared.subOwnerName ?? "Patient")
  }
  
  public func hideFloatingButton() {
    let sessionID = viewModel?.sessionID?.uuidString ?? "nil"
    let currentScreenState = viewModel != nil ? "\(viewModel!.screenState)" : "nil"
    print("[V2RX DEBUG] hideFloatingButton : isWindowActive : \(isWindowActive) | sessionID : \(sessionID) | screenState : \(currentScreenState) | thread : \(Thread.isMainThread ? "main" : "bg")")
    guard isWindowActive else {
      print("[V2RX DEBUG] hideFloatingButton : SKIPPED : window not active")
      debugPrint("FloatingVoiceToRxViewController: Window is not active. Ignoring hide request.")
      return
    }

    let eventLog = EventLog(
      params: ["session_id": sessionID, "screen_state": currentScreenState],
      eventType: .floatingButtonHide,
      message: "hideFloatingButton : sessionID : \(sessionID) | screenState : \(currentScreenState)",
      status: .success,
      platform: .network
    )
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)

    viewModel?.clearSession()
    window.windowLevel = UIWindow.Level(rawValue: 0)
    window.isHidden = true
    window.rootViewController = self
    view.subviews.forEach { $0.removeFromSuperview() }

    // Reset state to allow future window creation
    isWindowActive = false
    cancellables.removeAll()
    print("[V2RX DEBUG] hideFloatingButton : completed : isWindowActive : \(isWindowActive)")

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
        onTapStop: { [weak self] in
          self?.handleStopButton()
        },
        onTapClose: { [weak self] in
          self?.hideFloatingButton()
        },
        onTapDone: { [weak self] in
          self?.handleDoneRecording()
        },
        onTapNotYet: { [weak self] in
          self?.handleNotYetRecording()
        },
        onTapCancel: { [weak self] in
          self?.handleCancelRecording()
        },
        onDropdownStateChange: { [weak self] isDropdownOpen in
          self?.handleDropdownStateChange(isDropdownOpen: isDropdownOpen)
        }
      )
    ).view else {
      return
    }
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    button.frame = CGRect(x: (keyWindow?.frame.width ?? 0), y: (keyWindow?.frame.height ?? 0)/2, width: 200, height: 50)
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
    print("[V2RX DEBUG] handleDoneRecording : sessionID : \(viewModel?.sessionID?.uuidString ?? "nil") | screenState : \(viewModel != nil ? "\(viewModel!.screenState)" : "nil")")
    let eventlog = EventLog(eventType: .endRecordingFloatingButton, status: .success, platform: .network)
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventlog)
    Task { [weak self] in
      guard let self else { return }
      do {
        try await viewModel?.stopRecording()
        print("[V2RX DEBUG] handleDoneRecording : stopRecording SUCCESS")
      } catch {
        print("[V2RX DEBUG] handleDoneRecording : stopRecording FAILED : error : \(error.localizedDescription)")
        let eventlog = EventLog(eventType: .endRecordingFloatingButton, message: error.localizedDescription,status: .failure, platform: .network)
        V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventlog)
      }
      await liveActivityDelegate?.endLiveActivity()
    }
  }
  
  private func handleNotYetRecording() {
    debugPrint("handleNotYetRecording called")
    // Just close the dropdown, no action needed
    // The dropdown will be closed automatically by the view
  }
  
  private func handleCancelRecording() {
    print("[V2RX DEBUG] handleCancelRecording : sessionID : \(viewModel?.sessionID?.uuidString ?? "nil") | screenState : \(viewModel != nil ? "\(viewModel!.screenState)" : "nil")")
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
    let dropdownHeight: CGFloat = 150
    let totalHeight = isDropdownOpen ? baseHeight + dropdownHeight : baseHeight
    
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
  public func onResultValueReceived(value: String) {
    let delegateAlive = viewModel?.voiceToRxDelegate != nil
    print("[V2RX DEBUG] onResultValueReceived : valueLength : \(value.count) | delegateAlive : \(delegateAlive) | sessionID : \(viewModel?.sessionID?.uuidString ?? "nil")")
    let eventLog = EventLog(
      params: [
        "session_id": viewModel?.sessionID?.uuidString ?? "nil",
        "value_length": "\(value.count)",
        "delegate_alive": "\(delegateAlive)",
        "callback": "onResultValueReceived"
      ],
      eventType: .delegateCallback,
      message: "onResultValueReceived : valueLength : \(value.count) | delegateAlive : \(delegateAlive)",
      status: .success,
      platform: .network
    )
    V2RxInitConfigurations.shared.delegate?.receiveEvent(eventLog: eventLog)
    viewModel?.voiceToRxDelegate?.onResultValueReceived(value: value)
  }

  public func onTapResultDisplayView(success: Bool) {
    guard let sessionID = viewModel?.sessionID else {
      print("[V2RX DEBUG] onTapResultDisplayView : sessionID is nil → ignoring")
      return
    }
    print("[V2RX DEBUG] onTapResultDisplayView : success : \(success) | sessionID : \(sessionID.uuidString)")
    if success {
      hideFloatingButton()
      viewModel?.voiceToRxDelegate?.moveToDeepthoughtPage(id: sessionID)
    }
  }
}

extension FloatingVoiceToRxViewController {
  private func subscribeToScreenStates() {
    print("[V2RX DEBUG] subscribeToScreenStates : subscribing | isWindowActive : \(isWindowActive) | sessionID : \(viewModel?.sessionID?.uuidString ?? "nil")")
    viewModel?.$screenState.sink { [weak self] screenState in
      guard let self else { return }
      let sessionID = viewModel?.sessionID?.uuidString ?? "nil"
      print("[V2RX DEBUG] subscribeToScreenStates : received : screenState : \(screenState) | isWindowActive : \(isWindowActive) | sessionID : \(sessionID)")
      switch screenState {
      case .startRecording, .listening, .processing, .retry, .deletedRecording, .paused:
        debugPrint("Subscribed screen state is -> \(screenState)")
      case .resultDisplay:
        debugPrint("Subscribed screen state is -> \(screenState)")
        print("[V2RX DEBUG] subscribeToScreenStates : resultDisplay : scheduling auto-hide in 5s | sessionID : \(sessionID)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
          guard let self else {
            print("[V2RX DEBUG] subscribeToScreenStates : auto-hide : self is nil → skipping")
            return
          }
          print("[V2RX DEBUG] subscribeToScreenStates : auto-hide : executing hideFloatingButton | isWindowActive : \(self.isWindowActive)")
          self.hideFloatingButton()
        }
      }
    }.store(in: &cancellables)
  }
}
