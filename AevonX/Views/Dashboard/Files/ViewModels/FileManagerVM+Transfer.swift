//
//  FileManagerVM+Transfer.swift
//  AevonX
//
//  Extension: Upload, download, search, and transfer progress helpers
//

import SwiftUI
import AevonXCoreBridge

// MARK: - File Transfer (Upload / Download)

extension FileManagerViewModel {
    
    func uploadFiles(urls: [URL]) {
        for url in urls {
            let fileName = url.lastPathComponent
            let remotePath = currentPath.hasSuffix("/") ? "\(currentPath)\(fileName)" : "\(currentPath)/\(fileName)"
            
            let fileSize: Int64
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                fileSize = size
            } else {
                fileSize = 0
            }
            
            let transfer = FileTransferProgress(
                fileName: fileName,
                totalBytes: fileSize,
                state: .pending
            )
            
            let transferId = transfer.id
            activeTransfers.append(transfer)
            
            // Store the task for real cancellation
            let task = Task {
                do {
                    // Check cancellation before starting
                    try Task.checkCancellation()
                    updateTransferState(id: transferId, state: .transferring)
                    
                    try await SFTPService.shared.uploadFile(
                        localURL: url,
                        remotePath: remotePath,
                        serverId: serverId,
                        onProgress: { transferred, total in
                            Task { @MainActor [weak self] in
                                self?.updateTransferProgress(id: transferId, bytesTransferred: transferred)
                            }
                        }
                    )
                    
                    // Check cancellation after upload completes
                    guard !Task.isCancelled else {
                        updateTransferState(id: transferId, state: .cancelled)
                        return
                    }
                    
                    updateTransferState(id: transferId, state: .completed)
                    await loadFiles()
                    
                    // Auto-remove completed transfers after 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    removeTransfer(id: transferId)
                } catch is CancellationError {
                    updateTransferState(id: transferId, state: .cancelled)
                } catch {
                    updateTransferState(id: transferId, state: .failed, error: error.localizedDescription)
                }
                transferTasks.removeValue(forKey: transferId)
            }
            transferTasks[transferId] = task
        }
    }
    
    // MARK: - File Download
    
    func downloadFile(_ file: RemoteFileItem) {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = file.name
        panel.canCreateDirectories = true
        
        panel.begin { [weak self] response in
            guard response == .OK, let localURL = panel.url, let self = self else { return }
            
            let transfer = FileTransferProgress(
                fileName: file.name,
                totalBytes: file.size,
                state: .pending
            )
            
            let transferId = transfer.id
            
            Task { @MainActor in
                self.activeTransfers.append(transfer)
                self.updateTransferState(id: transferId, state: .transferring)
                
                do {
                    try await SFTPService.shared.downloadFile(
                        remotePath: file.path,
                        localURL: localURL,
                        serverId: self.serverId,
                        onProgress: { transferred, total in
                            Task { @MainActor [weak self] in
                                self?.updateTransferProgress(id: transferId, bytesTransferred: transferred)
                            }
                        }
                    )
                    
                    self.updateTransferState(id: transferId, state: .completed)
                    
                    // Auto-remove after 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.removeTransfer(id: transferId)
                } catch {
                    self.updateTransferState(id: transferId, state: .failed, error: error.localizedDescription)
                }
            }
        }
        #endif
    }
    
    // MARK: - Download from URL
    
    func downloadFromURL(urlString: String, fileName: String? = nil) {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        let name = fileName?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? fileName!
            : url.lastPathComponent.isEmpty ? "downloaded_file" : url.lastPathComponent
        
        let destPath = currentPath.hasSuffix("/") ? "\(currentPath)\(name)" : "\(currentPath)/\(name)"
        
        isDownloadingFromURL = true
        
        Task {
            do {
                try await SFTPService.shared.downloadFromURL(
                    url: urlString,
                    destPath: destPath,
                    serverId: serverId
                )
                await loadFiles()
            } catch {
                errorMessage = "Failed to download: \(error.localizedDescription)"
            }
            isDownloadingFromURL = false
            showDownloadURLSheet = false
        }
    }
    
    // MARK: - Search
    
    func performSearch(_ query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        searchTask = Task {
            // Debounce: 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            isSearching = true
            
            do {
                searchResults = try await SFTPService.shared.searchFiles(
                    query: query,
                    path: currentPath,
                    serverId: serverId
                )
            } catch {
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    // MARK: - Transfer Helpers
    
    func updateTransferProgress(id: String, bytesTransferred: Int64) {
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            activeTransfers[index].bytesTransferred = bytesTransferred
        }
    }
    
    func updateTransferState(id: String, state: FileTransferProgress.TransferState, error: String? = nil) {
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            activeTransfers[index].state = state
            activeTransfers[index].error = error
        }
    }
    
    func removeTransfer(id: String) {
        activeTransfers.removeAll { $0.id == id }
    }
    
    func cancelTransfer(_ transfer: FileTransferProgress) {
        // Actually cancel the running task
        transferTasks[transfer.id]?.cancel()
        transferTasks.removeValue(forKey: transfer.id)
        updateTransferState(id: transfer.id, state: .cancelled)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.removeTransfer(id: transfer.id)
        }
    }
}
