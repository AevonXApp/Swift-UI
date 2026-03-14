
import SwiftUI
import AevonXCoreBridge

struct DockerfileBuilder: View {
    let serverId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var baseImage: String = "ubuntu:22.04"
    @State private var instructions: [(type: String, value: String)] = []
    @State private var generatedDockerfile: String = ""
    @State private var imageName: String = ""
    @State private var imageTag: String = "latest"
    @State private var isBuilding = false
    @State private var buildOutput: String = ""
    @State private var errorMessage: String?
    @State private var step: BuilderStep = .edit
    
    enum BuilderStep { case edit, build }
    
    private let instructionTypes = ["RUN", "COPY", "ADD", "ENV", "EXPOSE", "WORKDIR", "CMD", "ENTRYPOINT", "VOLUME", "LABEL", "ARG", "USER", "HEALTHCHECK"]
    
    private let baseImages = [
        "ubuntu:22.04", "alpine:3.19", "debian:bookworm-slim",
        "node:20-alpine", "python:3.12-slim", "golang:1.22-alpine",
        "rust:1.75-slim", "ruby:3.3-slim", "php:8.3-fpm-alpine",
        "nginx:alpine", "httpd:alpine", "openjdk:21-slim"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                    Text("Dockerfile Builder")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").foregroundColor(.axTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
            
            Divider()
            
            if step == .edit {
                HSplitView {
                    // Left: Visual editor
                    ScrollView {
                        VStack(alignment: .leading, spacing: AXSpacing.md) {
                            // Base image
                            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                                Text("FROM (Base Image)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.axTextSecondary)
                                
                                Picker("", selection: $baseImage) {
                                    ForEach(baseImages, id: \.self) { img in
                                        Text(img).tag(img)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: baseImage) { _, _ in regenerate() }
                            }
                            
                            Divider()
                            
                            // Instructions
                            ForEach(instructions.indices, id: \.self) { i in
                                HStack(spacing: AXSpacing.sm) {
                                    Picker("", selection: Binding(
                                        get: { instructions[i].type },
                                        set: { instructions[i].type = $0; regenerate() }
                                    )) {
                                        ForEach(instructionTypes, id: \.self) { t in
                                            Text(t).tag(t)
                                        }
                                    }
                                    .frame(width: 110)
                                    
                                    TextField("value", text: Binding(
                                        get: { instructions[i].value },
                                        set: { instructions[i].value = $0; regenerate() }
                                    ))
                                    .textFieldStyle(AXTextFieldStyle())
                                    .font(.system(size: 11, design: .monospaced))
                                    
                                    Button(action: { instructions.remove(at: i); regenerate() }) {
                                        Image(systemName: "minus.circle.fill").foregroundColor(.axError)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Button(action: {
                                instructions.append((type: "RUN", value: ""))
                                regenerate()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 12))
                                    Text("Add Instruction").font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.axAccentBlue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AXSpacing.lg)
                    }
                    .frame(minWidth: 300)
                    
                    // Right: Preview
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Dockerfile Preview")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.axTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, AXSpacing.sm)
                        .padding(.vertical, AXSpacing.xs)
                        .background(Color.axSurface.opacity(0.5))
                        
                        TextEditor(text: $generatedDockerfile)
                            .font(.system(size: 11, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(AXSpacing.sm)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 280)
                }
            } else {
                // Build output
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Build Output")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.axTextSecondary)
                        Spacer()
                        if isBuilding {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .padding(AXSpacing.sm)
                    .background(Color.axSurface.opacity(0.5))
                    
                    ScrollView {
                        Text(buildOutput)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color(white: 0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AXSpacing.sm)
                    }
                    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
                }
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill"); Text(error) }
                    .font(.system(size: 11)).foregroundColor(.axError)
                    .padding(AXSpacing.sm).frame(maxWidth: .infinity).background(Color.axError.opacity(0.08))
            }
            
            Divider()
            
            // Footer
            HStack {
                if step == .build {
                    Button(action: { step = .edit }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 10))
                            Text("Edit")
                        }
                    }
                    .buttonStyle(AXSecondaryButtonStyle())
                }
                
                Spacer()
                
                if step == .edit {
                    HStack(spacing: AXSpacing.sm) {
                        TextField("image-name", text: $imageName)
                            .textFieldStyle(AXTextFieldStyle())
                            .frame(width: 140)
                        Text(":").foregroundColor(.axTextMuted)
                        TextField("tag", text: $imageTag)
                            .textFieldStyle(AXTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    Button(action: buildImage) {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer.fill").font(.system(size: 10))
                            Text("Build Image")
                        }
                    }
                    .buttonStyle(AXPrimaryButtonStyle())
                    .disabled(imageName.isEmpty || generatedDockerfile.isEmpty)
                }
            }
            .padding(AXSpacing.lg)
            .background(Color.axSurface)
        }
        .frame(width: 750, height: 520)
        .background(Color.axBackground)
        .onAppear { regenerate() }
    }
    
    // MARK: - Actions
    
    private func regenerate() {
        var lines = ["FROM \(baseImage)", ""]
        for inst in instructions where !inst.value.isEmpty {
            lines.append("\(inst.type) \(inst.value)")
        }
        generatedDockerfile = lines.joined(separator: "\n")
    }
    
    private func buildImage() {
        step = .build
        isBuilding = true
        buildOutput = "Starting build...\n"
        errorMessage = nil
        
        Task {
            do {
                let tag = "\(imageName):\(imageTag)"
                let result = try await DockerService.shared.buildImageFromDockerfile(
                    content: generatedDockerfile,
                    tag: tag,
                    serverId: serverId
                )
                await MainActor.run {
                    buildOutput += result
                    isBuilding = false
                }
            } catch {
                await MainActor.run {
                    buildOutput += "\n\nError: \(error.localizedDescription)"
                    isBuilding = false
                }
            }
        }
    }
}
