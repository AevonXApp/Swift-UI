//
//  AXStepInstallerView.swift
//  AevonX
//
//  Reusable step-by-step installer component with animated progress.
//  Designed to work across the entire project: PHP, databases, services, etc.
//

import SwiftUI
import Combine

// MARK: - Step Model

/// Represents a single installation step
public struct AXInstallStep: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let icon: String
    
    public var status: StepStatus = .pending
    public var output: String?
    
    public enum StepStatus: Equatable {
        case pending
        case running
        case completed
        case failed(String)
        case skipped
        
        var color: Color {
            switch self {
            case .pending: return .axTextMuted
            case .running: return .axAccentBlue
            case .completed: return .axSuccess
            case .failed: return .axError
            case .skipped: return .axTextTertiary
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "circle"
            case .running: return "arrow.trianglehead.2.counterclockwise"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .skipped: return "minus.circle.fill"
            }
        }
    }
    
    public init(title: String, description: String, icon: String) {
        self.title = title
        self.description = description
        self.icon = icon
    }
}

// MARK: - Step Runner Protocol

/// Define steps and their execution logic
public protocol AXStepRunnable {
    var steps: [AXInstallStep] { get }
    func execute(step: AXInstallStep, serverId: String) async throws -> String?
}

// MARK: - Step Installer ViewModel

@MainActor
public final class AXStepInstallerViewModel: ObservableObject {
    @Published public var steps: [AXInstallStep]
    @Published public var currentStepIndex: Int = -1
    @Published public var isRunning = false
    @Published public var isComplete = false
    @Published public var hasFailed = false
    @Published public var elapsedSeconds: Int = 0
    
    private var timerTask: Task<Void, Never>?
    
    public var overallProgress: Double {
        guard !steps.isEmpty else { return 0 }
        let completedCount = steps.filter {
            if case .completed = $0.status { return true }
            if case .skipped = $0.status { return true }
            return false
        }.count
        let runningBonus: Double = isRunning && currentStepIndex >= 0 ? 0.5 : 0
        return (Double(completedCount) + runningBonus) / Double(steps.count)
    }
    
    public var currentStepTitle: String {
        guard currentStepIndex >= 0, currentStepIndex < steps.count else {
            return isComplete ? "Complete" : "Preparing..."
        }
        return steps[currentStepIndex].title
    }
    
    public init(steps: [AXInstallStep]) {
        self.steps = steps
    }
    
    /// Execute all steps sequentially using a provided runner closure
    public func run(
        serverId: String,
        executor: @escaping (AXInstallStep, String) async throws -> String?
    ) async {
        isRunning = true
        isComplete = false
        hasFailed = false
        elapsedSeconds = 0
        
        // Start elapsed timer
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.elapsedSeconds += 1
            }
        }
        
        for i in 0..<steps.count {
            currentStepIndex = i
            steps[i].status = .running
            
            do {
                let output = try await executor(steps[i], serverId)
                steps[i].output = output
                steps[i].status = .completed
            } catch {
                steps[i].status = .failed(error.localizedDescription)
                steps[i].output = error.localizedDescription
                hasFailed = true
                break
            }
        }
        
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        isComplete = !hasFailed
    }
    
    /// Mark a step as skipped
    public func skip(index: Int) {
        guard index < steps.count else { return }
        steps[index].status = .skipped
    }
    
    /// Reset all steps to pending
    public func reset() {
        for i in 0..<steps.count {
            steps[i].status = .pending
            steps[i].output = nil
        }
        currentStepIndex = -1
        isRunning = false
        isComplete = false
        hasFailed = false
        elapsedSeconds = 0
    }
    
    public var elapsedTimeFormatted: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Step Installer View

public struct AXStepInstallerView: View {
    @ObservedObject var viewModel: AXStepInstallerViewModel
    var title: String
    var icon: String
    var accentColor: Color
    var onDismiss: (() -> Void)?
    
    @State private var spinAngle: Double = 0
    
    public init(
        viewModel: AXStepInstallerViewModel,
        title: String,
        icon: String = "arrow.down.circle.fill",
        accentColor: Color = .axAccentBlue,
        onDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            installerHeader
            
            Divider().background(Color.axBorder.opacity(0.3))
            
            // Steps List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                        stepRow(step: step, index: index)
                        
                        if index < viewModel.steps.count - 1 {
                            stepConnector(isCompleted: isStepDone(index))
                        }
                    }
                }
                .padding(AXSpacing.lg)
            }
            
            Divider().background(Color.axBorder.opacity(0.3))
            
            // Footer
            installerFooter
        }
        .background(Color.axBackground)
        .cornerRadius(AXCornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.xl)
                .stroke(Color.axBorder.opacity(0.5), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        }
    }
    
    // MARK: - Header
    
    private var installerHeader: some View {
        VStack(spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    
                    HStack(spacing: AXSpacing.sm) {
                        if viewModel.isRunning {
                            Text(viewModel.currentStepTitle)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextSecondary)
                        } else if viewModel.isComplete {
                            Text("All steps completed successfully")
                                .font(AXTypography.caption)
                                .foregroundColor(.axSuccess)
                        } else if viewModel.hasFailed {
                            Text("Installation failed")
                                .font(AXTypography.caption)
                                .foregroundColor(.axError)
                        }
                        
                        if viewModel.isRunning || viewModel.isComplete {
                            Text("•")
                                .foregroundColor(.axTextMuted)
                            Text(viewModel.elapsedTimeFormatted)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.axTextTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Overall progress circle
                AXCircularProgress(
                    value: viewModel.overallProgress,
                    size: 40,
                    lineWidth: 3.5,
                    color: viewModel.hasFailed ? .axError : accentColor,
                    showValue: true
                )
            }
            
            // Overall progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.axBorder.opacity(0.3))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: viewModel.hasFailed
                                    ? [.axError, .axError.opacity(0.7)]
                                    : [accentColor, .axAccentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.overallProgress, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(AXSpacing.lg)
    }
    
    // MARK: - Step Row
    
    private func stepRow(step: AXInstallStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: AXSpacing.md) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(stepBackgroundColor(step))
                    .frame(width: 32, height: 32)
                
                if case .running = step.status {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(spinAngle))
                } else {
                    Image(systemName: stepIconName(step))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stepIconColor(step))
                }
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(stepTitleColor(step))
                
                Text(step.description)
                    .font(.system(size: 11))
                    .foregroundColor(.axTextTertiary)
                
                // Output / Error
                if let output = step.output, !output.isEmpty {
                    if case .failed(let error) = step.status {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(error)
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundColor(.axError)
                        .padding(AXSpacing.sm)
                        .background(Color.axError.opacity(0.1))
                        .cornerRadius(AXCornerRadius.sm)
                        .padding(.top, 4)
                    } else if case .completed = step.status, output != "ok" {
                        Text(output)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.axSuccess.opacity(0.8))
                            .padding(.top, 2)
                    }
                }
            }
            
            Spacer()
            
            // Step status badge
            if case .running = step.status {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, AXSpacing.sm)
        .padding(.horizontal, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isStepActive(step) ? accentColor.opacity(0.05) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: step.status)
    }
    
    // MARK: - Step Connector
    
    private func stepConnector(isCompleted: Bool) -> some View {
        HStack {
            Rectangle()
                .fill(isCompleted ? accentColor.opacity(0.5) : Color.axBorder.opacity(0.3))
                .frame(width: 2, height: 20)
                .padding(.leading, 15) // Center under the step circle
            Spacer()
        }
    }
    
    // MARK: - Footer
    
    private var installerFooter: some View {
        HStack {
            // Step counter
            HStack(spacing: AXSpacing.xs) {
                Text("Step \(max(viewModel.currentStepIndex + 1, 1))/\(viewModel.steps.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.axTextTertiary)
            }
            
            Spacer()
            
            if viewModel.isComplete || viewModel.hasFailed {
                Button(action: { onDismiss?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isComplete ? "checkmark" : "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .semibold))
                        Text(viewModel.isComplete ? "Done" : "Dismiss")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, AXSpacing.sm)
                    .background(viewModel.isComplete ? Color.axSuccess : Color.axTextMuted)
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AXSpacing.md)
    }
    
    // MARK: - Helpers
    
    private func isStepDone(_ index: Int) -> Bool {
        guard index < viewModel.steps.count else { return false }
        if case .completed = viewModel.steps[index].status { return true }
        if case .skipped = viewModel.steps[index].status { return true }
        return false
    }
    
    private func isStepActive(_ step: AXInstallStep) -> Bool {
        if case .running = step.status { return true }
        return false
    }
    
    private func stepBackgroundColor(_ step: AXInstallStep) -> Color {
        switch step.status {
        case .pending: return .axBorder.opacity(0.3)
        case .running: return accentColor
        case .completed: return .axSuccess
        case .failed: return .axError
        case .skipped: return .axTextMuted.opacity(0.3)
        }
    }
    
    private func stepIconName(_ step: AXInstallStep) -> String {
        switch step.status {
        case .pending: return step.icon
        case .running: return "arrow.trianglehead.2.counterclockwise"
        case .completed: return "checkmark"
        case .failed: return "xmark"
        case .skipped: return "minus"
        }
    }
    
    private func stepIconColor(_ step: AXInstallStep) -> Color {
        switch step.status {
        case .pending: return .axTextMuted
        case .running, .completed, .failed: return .white
        case .skipped: return .axTextTertiary
        }
    }
    
    private func stepTitleColor(_ step: AXInstallStep) -> Color {
        switch step.status {
        case .pending: return .axTextSecondary
        case .running: return .axTextPrimary
        case .completed: return .axSuccess
        case .failed: return .axError
        case .skipped: return .axTextMuted
        }
    }
}
