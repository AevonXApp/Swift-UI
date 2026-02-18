//
//  HookPluginViewModel.swift
//  AevonX
//
//  ViewModel for managing plugin command execution state.
//  Each plugin component instance owns one of these to track loading/success/error.
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - Hook Plugin ViewModel

/// Manages the execution state for a single plugin component instance
@MainActor
public final class HookPluginViewModel: ObservableObject {

    // MARK: - State

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isSuccess: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var resultOutput: String?
    @Published public private(set) var showModal: Bool = false

    private let dispatcher = PluginCommandDispatcher.shared

    // MARK: - Execution

    /// Executes a plugin command and updates state accordingly
    public func execute(
        command: HookPluginCommand,
        pluginId: String,
        serverId: String,
        context: [String: String] = [:]
    ) async {
        guard !isLoading else { return }

        isLoading = true
        isSuccess = false
        errorMessage = nil
        resultOutput = nil

        do {
            let result = try await dispatcher.dispatch(
                command: command,
                pluginId: pluginId,
                serverId: serverId,
                context: context
            )
            isLoading = false
            isSuccess = true
            resultOutput = result.output
            // Auto-clear success state after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                isSuccess = false
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// Resets all state
    public func reset() {
        isLoading = false
        isSuccess = false
        errorMessage = nil
        resultOutput = nil
    }

    /// Toggles modal visibility
    public func toggleModal() {
        showModal.toggle()
    }
}
