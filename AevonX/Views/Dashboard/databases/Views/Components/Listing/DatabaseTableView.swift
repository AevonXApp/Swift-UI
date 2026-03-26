//
//  DatabaseTableView.swift
//  AevonX
//
//  Created by Automation on 2026-02-08.
//

import SwiftUI
import AevonXCoreBridge

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
                    Text(L10n.Field.name).frame(maxWidth: .infinity, alignment: .leading)
                    Text(L10n.Engine.engine).frame(width: 120, alignment: .leading)
                    Text(L10n.Engine.version).frame(width: 100, alignment: .leading)
                    Text(L10n.Database.size).frame(width: 100, alignment: .leading)
                    Text(L10n.Database.tables).frame(width: 80, alignment: .trailing)
                    Text(L10n.Database.status).frame(width: 80, alignment: .center)
                    Text(L10n.Database.actions).frame(width: 100, alignment: .trailing)
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
                }
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.top, AXSpacing.lg)
        }
    }
}
