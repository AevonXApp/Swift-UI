//
//  AXLaunchProgressBubbleViewModel.swift
//  AevonX
//
//  ViewModel for the floating progress bubble overlay.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class AXLaunchProgressBubbleViewModel: ObservableObject {
    @Published var isVisible = false
    @Published var progress: AXLaunchProgress = .idle
    @Published var domainName: String = ""
    @Published var launchID: String?
    @Published var isComplete = false
    @Published var isFailed = false

    private let service = AXLaunchService.shared
    private var pollingTask: Task<Void, Never>?

    var showReopenSheet: (() -> Void)?

    func startTracking(launchID: String, domain: String) {
        self.launchID = launchID
        self.domainName = domain
        isVisible = true
        isComplete = false
        isFailed = false
        startPolling()
    }

    func dismiss() {
        pollingTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) { isVisible = false }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self, let id = self.launchID else { return }
            while !Task.isCancelled {
                let p = await self.service.getProgress(launchID: id)
                self.progress = p

                if p.status == "success" {
                    self.isComplete = true
                    try? await Task.sleep(for: .seconds(3))
                    self.dismiss()
                    break
                } else if p.status == "failed" || p.status == "cancelled" {
                    self.isFailed = true
                    break
                }
                try? await Task.sleep(for: .milliseconds(800))
            }
        }
    }
}
