//
//  FloatingVoiceToRxViewController.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 03/03/25.
//

import UIKit
import SwiftUI
import Combine

public protocol FloatingVoiceToRxDelegate: AnyObject {
  func moveToDeepthoughtPage(id: UUID)
}

// TODO: - To refractor this for loading view etc

public class FloatingVoiceToRxViewController: UIViewController {
  private(set) var button: UIView!
  private let window: FloatingButtonWindow = FloatingButtonWindow()
  public static let shared: FloatingVoiceToRxViewController = FloatingVoiceToRxViewController()
  private var initialButtonCenter: CGPoint?
  private var viewModel: VoiceToRxViewModel?
  public weak var voiceToRxDelegate: FloatingVoiceToRxDelegate?
  var cancellables = Set<AnyCancellable>()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  public init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  public func showFloatingButton(viewModel: VoiceToRxViewModel) {
    window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
    window.isHidden = false
    window.rootViewController = self
    loadView(viewModel: viewModel)
    subscribeToScreenStates()
  }
  
  public func hideFloatingButton() {
    window.windowLevel = UIWindow.Level(rawValue: 0)
    window.isHidden = true
    window.rootViewController = self
  }
  
  private func loadView(viewModel: VoiceToRxViewModel) {
    self.viewModel = viewModel
    guard let button = UIHostingController(
      rootView: PictureInPictureView(
        title: V2RxInitConfigurations.shared.subOwnerName ?? "Patient",
        voiceToRxViewModel: viewModel,
        delegate: self,
        onTapStop: showConfirmationAlert,
        onTapClose: hideFloatingButton
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
  
  private func showConfirmationAlert() {
    let alertController = UIAlertController(
      title: "Are you done with the conversation?",
      message: "Make sure you record entire conversation to get accurate medical notes.",
      preferredStyle: .alert
    )
    
    alertController.addAction(UIAlertAction(
      title: "Yes I'm done",
      style: .default,
      handler: { [weak self] _ in
        guard let self else { return }
        viewModel?.stopRecording()
      }
    ))
    
    //    alertController.addAction(UIAlertAction(
    //      title: "Not yet",
    //      style: .default,
    //      handler: { [weak self] _ in
    //        guard let self else { return }
    //      }
    //    ))
    //
    alertController.addAction(UIAlertAction(
      title: "Cancel recording",
      style: .default,
      handler: { [weak self] _ in
        guard let self else { return }
        viewModel?.stopAudioRecording()
        hideFloatingButton()
      }
    ))
    
    let controller = UIApplication.shared.windows.first?.rootViewController
    controller?.present(alertController, animated: true)
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
    
    if let keyWindow = UIApplication.shared.windows.first {
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
    let buttonPoint = convert(point, to: button)
    return button.point(inside: buttonPoint, with: event)
  }
}

extension FloatingVoiceToRxViewController: PictureInPictureViewDelegate {
  public func onTapResultDisplayView(success: Bool) {
    guard let sessionID = viewModel?.sessionID else { return }
    if success {
      hideFloatingButton()
      voiceToRxDelegate?.moveToDeepthoughtPage(id: sessionID)
    }
  }
}

extension FloatingVoiceToRxViewController {
  private func subscribeToScreenStates() {
    viewModel?.$screenState.sink { [weak self] screenState in
      guard let self else { return }
      switch screenState {
      case .startRecording:
        debugPrint("Subscribed screen state is -> \(screenState)")
      case .listening:
        debugPrint("Subscribed screen state is -> \(screenState)")
      case .processing:
        debugPrint("Subscribed screen state is -> \(screenState)")
      case .resultDisplay:
        debugPrint("Subscribed screen state is -> \(screenState)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
          guard let self else { return }
          self.hideFloatingButton()
        }
      case .retry:
        debugPrint("Subscribed screen state is -> \(screenState)")
        debugPrint("")
      }
    }.store(in: &cancellables)
  }
}
