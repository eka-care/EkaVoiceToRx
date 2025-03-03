
//
//  DraggableViewController.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 03/03/25.
//

import UIKit

public final class DraggableViewController: UIViewController {
  
  // MARK: - Properties
  
  private var draggableView: UIView
  private var initialButtonCenter: CGPoint?
  private let window: FloatingButtonWindow = FloatingButtonWindow()
  
  // MARK: - Init
  
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
  
  public init(view: UIView) {
    self.draggableView = view
    super.init(nibName: nil, bundle: nil)
  }
}

// MARK: - Load view

extension DraggableViewController {
  private func setupView() {
    draggableView.frame = CGRect(x: (UIApplication.shared.keyWindow?.frame.width ?? 0), y: (UIApplication.shared.keyWindow?.frame.height)!/4, width: 200, height: 50)
    view.addSubview(draggableView)
  }
}

// MARK: - Show/Hide views

extension DraggableViewController {
  public func showFloatingButton() {
    window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
    window.isHidden = false
    window.rootViewController = self
    setupView()
  }
  
  public func hideFloatingButton() {
    window.windowLevel = UIWindow.Level(rawValue: 0)
    window.isHidden = true
    window.rootViewController = self
  }
}

// MARK: - Action Responders

extension DraggableViewController {
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
