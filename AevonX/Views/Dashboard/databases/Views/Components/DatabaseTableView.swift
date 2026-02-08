//
//  DatabaseTableView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCore

struct DatabaseTableView: View {
    let databases: [DatabaseInfo]
    let serverId: String?
    let onOpen: (DatabaseInfo) -> Void
    let onBackup: (DatabaseInfo) -> Void
    let onDelete: (DatabaseInfo) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                // Table Header
                HStack(spacing: AXSpacing.md) {
                    Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Engine").frame(width: 120, alignment: .leading)
                    Text("Version").frame(width: 100, alignment: .leading)
                    Text("Size").frame(width: 100, alignment: .leading)
                    Text("Tables").frame(width: 80, alignment: .trailing)
                    Text("Status").frame(width: 80, alignment: .center)
                    Text("Actions").frame(width: 100, alignment: .trailing)
                }
                .font(AXTypography.caption)
                .foregroundColor(.axTextMuted)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)

                // Table Rows
                ForEach(databases) { database in
                    DatabaseTableRow(
                        database: database,
                        onOpen: { onOpen(database) },
                        onBackup: { onBackup(database) },
                        onDelete: { onDelete(database) }
                    )
                    .contextMenu {
                        databaseContextMenu(database)
                    }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)
        }
    }
    
    private func databaseContextMenu(_ database: DatabaseInfo) -> some View {
        Group {
            Button {
                onOpen(database)
            } label: {
                Label("Open Detail", systemImage: "arrow.right.circle")
            }

            Button {
                onBackup(database)
            } label: {
                Label("Create Backup", systemImage: "arrow.down.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete(database)
            } label: {
                Label("Delete Database", systemImage: "trash")
            }
        }
    }
}
