//
//  FileUploadPanelHelper.swift
//  AevonX
//
//  macOS NSOpenPanel wrapper for file upload selection
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Upload Panel Helper

/// Show the macOS file picker and return selected URLs
func showUploadPanel(viewModel: FileManagerViewModel) {
    #if os(macOS)
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    panel.begin { response in
        if response == .OK {
            viewModel.uploadFiles(urls: panel.urls)
        }
    }
    #endif
}

/// Handle dropped file providers from drag-and-drop (supports files AND folders)
func handleFileDrop(_ providers: [NSItemProvider], viewModel: FileManagerViewModel) {
    for provider in providers {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            Task { @MainActor in
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    // Folder dropped — collect all files recursively
                    var allFiles: [URL] = []
                    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                        for case let fileURL as URL in enumerator {
                            if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                               values.isRegularFile == true {
                                allFiles.append(fileURL)
                            }
                        }
                    }
                    if !allFiles.isEmpty {
                        viewModel.uploadFiles(urls: allFiles)
                    }
                } else {
                    viewModel.uploadFiles(urls: [url])
                }
            }
        }
    }
}
