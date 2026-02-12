//
//  ShareViewController.swift
//  EditorBoxShareExtension
//
//  Created by Codex on 2026/02/12.
//

import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareImportView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionContext else { return }
        let rootView = ShareImportView(
            viewModel: ShareImportViewModel(extensionContext: extensionContext)
        )
        let hostingController = UIHostingController(rootView: rootView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)

        self.hostingController = hostingController
    }
}
