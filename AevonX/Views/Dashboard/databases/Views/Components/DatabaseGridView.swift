//
//  DatabaseGridView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

struct DatabaseGridView: View {
    let databases: [DatabaseInfo]
    let serverId: String?
    let onOpen: (DatabaseInfo) -> Void
    let onBackup: (DatabaseInfo) -> Void
    let onDelete: (DatabaseInfo) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg),
                GridItem(.flexible(), spacing: AXSpacing.lg)
            ], spacing: AXSpacing.lg) {
                ForEach(databases) { database in
                    databaseCardWithActions(database)
                        .contextMenu {
                            databaseContextMenu(database)
                        }
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)
        }
    }
    
    private func databaseCardWithActions(_ database: DatabaseInfo) -> some View {
        ModernDatabaseCard(
            database: database,
            onOpen: { onOpen(database) },
            onBackup: { onBackup(database) },
            onDelete: { onDelete(database) }
        )
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
