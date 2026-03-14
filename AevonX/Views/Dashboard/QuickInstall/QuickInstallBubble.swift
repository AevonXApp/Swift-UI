//
//  QuickInstallBubble.swift
//  AevonX
//
//  Floating draggable circular progress bubble shown when Quick Install is minimized.
//  Tap to restore the full overlay. Persists across tab navigation.
//

import SwiftUI
import AevonXCoreBridge

struct QuickInstallBubble: View {

    @ObservedObject var viewModel: QuickInstallViewModel
    var onTap: () -> Void

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isPulsing = false

    private var progress: Double {
        viewModel.installerViewModel?.overallProgress ?? 0
    }

    private var bubbleColor: Color {
        if viewModel.isComplete { return .axSuccess }
        if viewModel.isFailed { return .axError }
        return .axAccentBlue
    }

    private var bubbleIcon: String {
        if viewModel.isComplete { return "checkmark" }
        if viewModel.isFailed { return "exclamationmark" }
        return "bolt.fill"
    }

    var body: some View {
        ZStack {
            // Outer progress ring
            Circle()
                .stroke(bubbleColor.opacity(0.2), lineWidth: 4)
                .frame(width: 56, height: 56)

            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(
                    bubbleColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)

            // Pulse ring (only while running)
            if viewModel.isInstalling && !viewModel.isComplete {
                Circle()
                    .stroke(bubbleColor.opacity(isPulsing ? 0 : 0.35), lineWidth: 2)
                    .frame(width: 56 + (isPulsing ? 20 : 0), height: 56 + (isPulsing ? 20 : 0))
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: isPulsing)
            }

            // Inner circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [bubbleColor.opacity(0.9), bubbleColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .shadow(color: bubbleColor.opacity(0.4), radius: 8, x: 0, y: 4)

            // Content: icon or percentage
            if viewModel.isComplete || viewModel.isFailed {
                Image(systemName: bubbleIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
        .onTapGesture(perform: onTap)
        .onAppear {
            if viewModel.isInstalling {
                isPulsing = true
            }
        }
        .onChange(of: viewModel.isInstalling) { _, installing in
            isPulsing = installing
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: offset)
    }
}
