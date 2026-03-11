//
//  DBEMLogsSection.swift
//  AevonX
//
//  Database Engine Management — Logs section placeholder.
//  Note: Currently not referenced in the app navigation.
//  Engine logs are accessed via DBEDLogsTab (DatabaseEngineDetailView).
//

import SwiftUI
import AevonXCoreBridge

struct DBEMLogsSection: View {
    @ObservedObject var viewModel: DatabaseManagementViewModel

    private let logColumns: [AXLogColumn] = [
        AXLogColumn(id: "time", title: "Time", width: 140),
        AXLogColumn(id: "message", title: "Message", width: nil),
    ]

    var body: some View {
        AXLogTable(
            title: "Database Logs",
            icon: "doc.text.fill",
            columns: logColumns,
            rows: [],
            isLoading: viewModel.isLoading
        )
    }
}
