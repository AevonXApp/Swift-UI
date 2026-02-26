//
//  HookPluginViewModel.swift
//  AevonX
//
//  ViewModel for managing hook command execution state.
//  Each hook component instance owns one of these to track loading/success/error.
//

import SwiftUI
import Combine
import AevonXCore

// MARK: - Hook Plugin ViewModel

@MainActor
public final class HookPluginViewModel: ObservableObject {

    // MARK: - State

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isSuccess: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var resultOutput: String?
    @Published public private(set) var showModal: Bool = false

    private let dispatcher = HookCommandDispatcher.shared

    // MARK: - Execution

    public func execute(
        command: HookPluginCommand,
        pluginId: String,
        serverId: String,
        context: [String: String] = [:],
        namespace: String? = nil
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
                context: context,
                namespace: namespace
            )
            isLoading = false
            isSuccess = true
            resultOutput = result.output

            if let msg = command.onSuccess, !msg.isEmpty {
                HookToastManager.shared.success(msg)
            }

            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                isSuccess = false
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription

            if let msg = command.onError, !msg.isEmpty {
                HookToastManager.shared.error(msg)
            } else {
                HookToastManager.shared.error(error.localizedDescription)
            }
        }
    }

    public func reset() {
        isLoading = false
        isSuccess = false
        errorMessage = nil
        resultOutput = nil
        chainProgress = 0
        chainTotal = 0
    }

    public func toggleModal() {
        showModal.toggle()
    }

    // MARK: - Command Chaining

    @Published public private(set) var chainProgress: Int = 0
    @Published public private(set) var chainTotal: Int = 0

    public func executeChain(
        commands: [HookPluginCommand],
        pluginId: String,
        serverId: String,
        context: [String: String] = [:],
        namespace: String? = nil
    ) async {
        guard !isLoading, !commands.isEmpty else { return }

        isLoading = true
        isSuccess = false
        errorMessage = nil
        resultOutput = nil
        chainProgress = 0
        chainTotal = commands.count

        var lastOutput: String? = nil

        for (index, command) in commands.enumerated() {
            chainProgress = index + 1

            do {
                let result = try await dispatcher.dispatch(
                    command: command,
                    pluginId: "\(pluginId)_step\(index)",
                    serverId: serverId,
                    context: context,
                    namespace: namespace
                )
                lastOutput = result.output

                if let msg = command.onSuccess, !msg.isEmpty {
                    HookToastManager.shared.success(msg)
                }
            } catch {
                isLoading = false
                errorMessage = "Step \(index + 1)/\(commands.count) failed: \(error.localizedDescription)"

                if let msg = command.onError, !msg.isEmpty {
                    HookToastManager.shared.error(msg)
                } else {
                    HookToastManager.shared.error("Step \(index + 1) failed")
                }
                return
            }
        }

        isLoading = false
        isSuccess = true
        resultOutput = lastOutput
        chainProgress = chainTotal

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            isSuccess = false
        }
    }
}
