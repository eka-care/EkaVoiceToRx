//
//  EkaScribeLimitViewController.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/07/25.
//

import UIKit
import SwiftUI

public class EkaScribeLimitViewController: UIViewController {
  
  private let onTapCta: () -> Void
  
  // MARK: - Subviews
  
  private lazy var hostingController: UIHostingController<EkaScribeLimitView> = {
    let swiftUIView = EkaScribeLimitView(header: "You're out of free Eka Scribe sessions for today!", buttonImage: "headphones", buttonText: "Talk to sales to upgrade plan", onTapCta: onTapCta)
    let controller = UIHostingController(rootView: swiftUIView)
    controller.view.backgroundColor = .systemBackground // optional
    return controller
  }()
  
  // MARK: - Init
  
  public init(onTapCta: @escaping () -> Void) {
    self.onTapCta = onTapCta
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    addChild(hostingController)
    view.addSubview(hostingController.view)
    // Disable autoresizing mask translation
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    
    // Pin to all edges of the parent view
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    hostingController.didMove(toParent: self)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }
}
