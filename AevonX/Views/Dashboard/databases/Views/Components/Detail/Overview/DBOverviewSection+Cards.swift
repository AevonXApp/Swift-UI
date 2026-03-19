//
//  DBOverviewSection+Cards.swift
//  AevonX
//
//  Server info, connection details, table size breakdown,
//  and tables card for the database overview section.
//

import SwiftUI
import AevonXCoreBridge

extension DBOverviewSection {
    // MARK: - Server Info Card (NEW)

    var serverInfoCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "server.rack")
                    .font(AXTypography.caption)
                    .foregroundColor(.teal)
                Text("SERVER INFO")
                    .font(AXTypography.caption2).fontWeight(.heavy)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    var info = "Database: \(viewModel.database.name)\n"
                    info += "Engine: \(viewModel.database.type.displayName) \(viewModel.database.version ?? "")\n"
                    info += "Charset: \(viewModel.database.characterSet ?? "UTF-8")\n"
                    info += "Collation: \(viewModel.database.collation ?? "N/A")\n"
                    info += "Size: \(AXFormatter.formatSizeMB(viewModel.database.size))\n"
                    info += "Tables: \(viewModel.tables.count)\n"
                    info += "Connections: \(viewModel.database.connections)"
                    NSPasteboard.general.setString(info, forType: .string)
                    GlobalToastManager.shared.showSuccess("Server info copied")
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(AXTypography.caption2)
                        Text("Copy")
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axTextMuted)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AXSpacing.sm) {
                serverInfoRow(label: "Engine", value: viewModel.database.type.displayName, icon: "gearshape")
                serverInfoRow(label: "Version", value: viewModel.database.version ?? "N/A", icon: "tag")
                serverInfoRow(label: "Charset", value: viewModel.database.characterSet ?? "UTF-8", icon: "character")
                serverInfoRow(label: "Collation", value: viewModel.database.collation ?? "N/A", icon: "text.justify")
                serverInfoRow(label: "Data Size", value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.dataSize }), icon: "doc")
                serverInfoRow(label: "Index Size", value: AXFormatter.formatBytes(viewModel.tables.reduce(0) { $0 + $1.indexSize }), icon: "list.number")
                serverInfoRow(label: "Total Rows", value: "\(viewModel.tables.reduce(0) { $0 + Int($1.rowCount) })", icon: "number")
                serverInfoRow(label: "Tables", value: "\(viewModel.tables.count)", icon: "tablecells")
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.12), value: appear)
    }

    private func serverInfoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AXSpacing.sm) {
            Image(systemName: icon)
                .font(AXTypography.caption2)
                .foregroundColor(.axTextMuted)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                Text(value)
                    .font(AXTypography.monoSm).fontWeight(.semibold)
                    .foregroundColor(.axTextPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.sm)
    }

    // MARK: - Connection Details Card (NEW)

    var connectionDetailsCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "network")
                    .font(AXTypography.caption)
                    .foregroundColor(.indigo)
                Text("CONNECTION")
                    .font(AXTypography.caption2).fontWeight(.heavy)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                // Connection status indicator
                HStack(spacing: AXSpacing.xxs) {
                    Circle()
                        .fill(Color.axSuccess)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axSuccess)
                }
            }

            HStack(spacing: AXSpacing.md) {
                connectionField(label: "Host", value: "localhost", icon: "desktopcomputer")
                connectionField(label: "Port", value: portForEngine(), icon: "number")
                connectionField(label: "User", value: "root", icon: "person")
                connectionField(label: "Database", value: viewModel.database.name, icon: "cylinder")
            }

            // Connection string
            VStack(alignment: .leading, spacing: AXSpacing.xs) {
                Text("Connection String")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                HStack {
                    Text(connectionString())
                        .font(AXTypography.monoXs)
                        .foregroundColor(.axTextSecondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(connectionString(), forType: .string)
                        GlobalToastManager.shared.showSuccess("Connection string copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(Color.axSurface.opacity(0.6))
                .cornerRadius(AXCornerRadius.sm)
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.14), value: appear)
    }

    private func connectionField(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xxs) {
            HStack(spacing: AXSpacing.xxs) {
                Image(systemName: icon)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
                Text(label)
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }
            Text(value)
                .font(AXTypography.monoSm).fontWeight(.semibold)
                .foregroundColor(.axTextPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AXSpacing.sm)
        .background(Color.axSurface.opacity(0.4))
        .cornerRadius(AXCornerRadius.sm)
    }

    private func portForEngine() -> String {
        switch viewModel.database.type {
        case .mysql, .mariadb: return "3306"
        case .postgresql: return "5432"
        case .redis: return "6379"
        case .mongodb: return "27017"
        case .cassandra: return "9042"
        case .cockroachdb: return "26257"
        case .elasticsearch: return "9200"
        default: return "3306"
        }
    }

    private func connectionString() -> String {
        let port = portForEngine()
        switch viewModel.database.type {
        case .mysql, .mariadb:
            return "mysql://root@localhost:\(port)/\(viewModel.database.name)"
        case .postgresql:
            return "postgresql://root@localhost:\(port)/\(viewModel.database.name)"
        case .redis:
            return "redis://localhost:\(port)"
        case .mongodb:
            return "mongodb://localhost:\(port)/\(viewModel.database.name)"
        default:
            return "\(viewModel.database.type.rawValue)://localhost:\(port)/\(viewModel.database.name)"
        }
    }

    // MARK: - Table Size Breakdown Card (NEW)

    var tableSizeBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "chart.bar.fill")
                    .font(AXTypography.caption)
                    .foregroundColor(.orange)
                Text("TABLE SIZE BREAKDOWN")
                    .font(AXTypography.caption2).fontWeight(.heavy)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Text("\(viewModel.tables.count) tables")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axTextMuted)
            }

            if viewModel.tables.isEmpty {
                Text("No tables to analyze")
                    .font(AXTypography.footnote)
                    .foregroundColor(.axTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AXSpacing.lg)
            } else {
                let sortedTables = viewModel.tables.sorted { ($0.dataSize + $0.indexSize) > ($1.dataSize + $1.indexSize) }
                let totalSize = max(sortedTables.reduce(0) { $0 + $1.dataSize + $1.indexSize }, 1)
                let colors: [Color] = [.axAccentBlue, .axAccentGreen, .axWarning, .purple, .mint, .indigo, .teal, .orange, .pink, .cyan]

                // Bar chart
                VStack(spacing: AXSpacing.xs) {
                    ForEach(Array(sortedTables.prefix(8).enumerated()), id: \.element.name) { index, table in
                        let size = table.dataSize + table.indexSize
                        let pct = Double(size) / Double(totalSize)
                        let color = colors[index % colors.count]

                        HStack(spacing: AXSpacing.sm) {
                            Text(table.name)
                                .font(AXTypography.caption)
                                .foregroundColor(.axTextPrimary)
                                .frame(width: 120, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.axSurface.opacity(0.3))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * pct, 4))
                                }
                            }
                            .frame(height: 14)

                            Text(AXFormatter.formatBytes(size))
                                .font(AXTypography.monoXxs).fontWeight(.medium)
                                .foregroundColor(.axTextMuted)
                                .frame(width: 60, alignment: .trailing)

                            Text(String(format: "%.1f%%", pct * 100))
                                .font(AXTypography.caption2).fontWeight(.bold)
                                .foregroundColor(color)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }

                    if sortedTables.count > 8 {
                        Text("+ \(sortedTables.count - 8) more tables")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axTextMuted)
                            .padding(.top, AXSpacing.xxs)
                    }
                }
            }
        }
        .padding(AXSpacing.lg)
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.16), value: appear)
    }

    // MARK: - Tables Card

    var tablesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "tablecells")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                    Text("Tables")
                        .font(AXTypography.headline)
                        .foregroundColor(.axTextPrimary)

                    if !viewModel.tables.isEmpty {
                        Text("\(viewModel.tables.count)")
                            .font(AXTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, AXSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.full)
                    }
                }

                Spacer()

                Button {
                    viewModel.currentSection = .tables
                    viewModel.showCreateTable = true
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(AXTypography.caption2)
                        Text("New Table")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(AXSpacing.lg)

            Divider().background(Color.axBorder)

            // Table rows
            if viewModel.tables.isEmpty {
                emptyTablesState
            } else {
                // Column headers
                tableColumnHeaders
                Divider().background(Color.axBorder.opacity(0.5))

                ForEach(Array(viewModel.tables.enumerated()), id: \.element.id) { index, table in
                    tableRow(table, index: index)
                    if index < viewModel.tables.count - 1 {
                        Divider().background(Color.axBorder.opacity(0.3))
                    }
                }
            }
        }
        .background(Color.axSurface)
        .cornerRadius(AXCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.lg)
                .stroke(Color.axBorder, lineWidth: 1)
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.18), value: appear)
    }

    var tableColumnHeaders: some View {
        HStack(spacing: 0) {
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Engine")
                .frame(width: 70, alignment: .center)
            Text("Rows")
                .frame(width: 70, alignment: .trailing)
            Text("Data")
                .frame(width: 70, alignment: .trailing)
            Text("Index")
                .frame(width: 70, alignment: .trailing)
        }
        .font(AXTypography.caption2)
        .fontWeight(.semibold)
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.lg)
        .padding(.vertical, AXSpacing.sm)
        .background(Color.axSurface.opacity(0.6))
    }

    private func tableRow(_ table: TableInfo, index: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                viewModel.selectedTable = table
                viewModel.currentSection = .tables
            } label: {
                HStack(spacing: 0) {
                    HStack(spacing: AXSpacing.sm) {
                        Image(systemName: "tablecells")
                            .font(AXTypography.caption2)
                            .foregroundColor(.axAccentBlue)
                            .frame(width: 18)
                        Text(table.name)
                            .font(AXTypography.subheadline)
                            .foregroundColor(.axTextPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(table.engine ?? "—")
                        .font(AXTypography.caption2)
                        .foregroundColor(.axTextMuted)
                        .frame(width: 70, alignment: .center)

                    Text("\(table.rowCount)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextSecondary)
                        .frame(width: 70, alignment: .trailing)

                    Text(AXFormatter.formatBytes(table.dataSize))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextMuted)
                        .frame(width: 70, alignment: .trailing)

                    Text(AXFormatter.formatBytes(table.indexSize))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.axTextMuted.opacity(0.7))
                        .frame(width: 70, alignment: .trailing)

                    // Table row actions — AXActionMenu
                    AXActionMenu(sections: [
                        AXMenuSection("Info", items: [
                            AXMenuItem("Copy Table Name", icon: "doc.on.doc", color: .axAccentBlue) {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(table.name, forType: .string)
                                GlobalToastManager.shared.showSuccess("Table name copied")
                            },
                            AXMenuItem("Copy SELECT Query", icon: "chevron.left.forwardslash.chevron.right", color: .cyan) {
                                let selectSQL = "SELECT * FROM `\(table.name)` LIMIT 100"
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(selectSQL, forType: .string)
                                GlobalToastManager.shared.showSuccess("SELECT query copied")
                            },
                        ]),
                        AXMenuSection("Navigate", items: [
                            AXMenuItem("Browse Data", icon: "tablecells", color: .mint) {
                                viewModel.selectedTable = table
                                viewModel.currentSection = .tables
                            },
                            AXMenuItem("Count Rows", icon: "number", color: .indigo) {
                                viewModel.queryText = "SELECT COUNT(*) as total FROM `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                            AXMenuItem("Describe Table", icon: "info.circle", color: .axAccentGreen) {
                                viewModel.queryText = "DESCRIBE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                        ]),
                        AXMenuSection("Maintenance", items: [
                            AXMenuItem("Optimize Table", icon: "wand.and.stars", color: .orange) {
                                viewModel.queryText = "OPTIMIZE TABLE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                            AXMenuItem("Check Table", icon: "checkmark.shield", color: .axSuccess) {
                                viewModel.queryText = "CHECK TABLE `\(table.name)`"
                                viewModel.currentSection = .queryConsole
                                Task { await viewModel.executeQuery() }
                            },
                        ]),
                        AXMenuSection(items: [
                            AXMenuItem("Drop Table", icon: "trash", isDestructive: true) {
                                viewModel.selectedTable = table
                                viewModel.activeAlert = .confirmDropTable(table.name)
                            },
                        ]),
                    ], triggerIcon: "ellipsis", triggerSize: 22)
                }
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm + 2)
                .background(index % 2 == 0 ? Color.clear : Color.axSurface.opacity(0.3))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    var emptyTablesState: some View {
        VStack(spacing: AXSpacing.md) {
            Image(systemName: "tray")
                .font(AXTypography.largeTitle)
                .foregroundColor(.axTextMuted)
            Text("No tables yet")
                .font(AXTypography.subheadline)
                .foregroundColor(.axTextMuted)
            Button {
                viewModel.currentSection = .tables
                viewModel.showCreateTable = true
            } label: {
                HStack(spacing: AXSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(AXTypography.caption)
                    Text("Create First Table")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AXSpacing.lg)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axAccentBlue)
                .cornerRadius(AXCornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(AXSpacing.xxl)
    }
}
