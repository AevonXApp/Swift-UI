//
//  DBCreateTableView.swift
//  AevonX
//
//  Premium Create Table dialog with column editor,
//  constraint badges, SQL preview, and glassmorphism.
//

import SwiftUI
import AevonXCoreBridge

struct DBCreateTableView: View {
    @ObservedObject var viewModel: DatabaseDetailViewModel
    @State var tableName = ""
    @State var columns: [CreateTableColumnDefinition] = [
        CreateTableColumnDefinition(name: "id", type: "INT", length: nil, isNullable: false, isPrimaryKey: true, isAutoIncrement: true)
    ]
    @State var isSubmitting = false
    @State var showSQLPreview = false

    var body: some View {
        VStack(spacing: 0) {
            dialogHeader
            Divider().background(Color.axBorder)
            dialogContent
            Divider().background(Color.axBorder)
            dialogFooter
        }
        .frame(width: 750, height: 580)
        .background(Color.axBackground)
    }

    // MARK: - Header

    var dialogHeader: some View {
        HStack(spacing: AXSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                    .fill(Color.axAccentBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(AXTypography.headline)
                    .foregroundColor(.axAccentBlue)
            }

            VStack(alignment: .leading, spacing: AXSpacing.xxxs) {
                Text(L10n.Database.createTable)
                    .font(AXTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextPrimary)
                Text("in \(viewModel.database.name)")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextMuted)
            }

            Spacer()

            // SQL Preview toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSQLPreview.toggle()
                }
            } label: {
                HStack(spacing: AXSpacing.xxs) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(AXTypography.caption2)
                    Text("SQL")
                        .font(AXTypography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(showSQLPreview ? .axAccentBlue : .axTextSecondary)
                .padding(.horizontal, AXSpacing.sm)
                .padding(.vertical, AXSpacing.xs)
                .background(showSQLPreview ? Color.axAccentBlue.opacity(0.1) : Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(showSQLPreview ? Color.axAccentBlue.opacity(0.3) : Color.axBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button { viewModel.showCreateTable = false } label: {
                Image(systemName: "xmark")
                    .font(AXTypography.caption)
                    .foregroundColor(.axTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.axSurface)
                    .cornerRadius(AXCornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(AXSpacing.lg)
    }

    // MARK: - Content

    var dialogContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AXSpacing.lg) {
                tableNameField

                if showSQLPreview {
                    sqlPreviewCard
                }

                columnsSection
            }
            .padding(AXSpacing.lg)
        }
    }

    var tableNameField: some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            Text("TABLE NAME")
                .font(AXTypography.caption2)
                .fontWeight(.bold)
                .foregroundColor(.axTextMuted)
                .tracking(0.5)
            TextField("e.g. users, posts, orders", text: $tableName)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.axTextPrimary)
                .padding(AXSpacing.md)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(tableName.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.3), lineWidth: 1)
                )
        }
    }

    var sqlPreviewCard: some View {
        VStack(alignment: .leading, spacing: AXSpacing.sm) {
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(AXTypography.caption2)
                    .foregroundColor(.axAccentBlue)
                Text("SQL PREVIEW")
                    .font(AXTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(generateSQL(), forType: .string)
                    GlobalToastManager.shared.showSuccess("SQL copied")
                } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "doc.on.doc")
                            .font(AXTypography.caption2)
                        Text(L10n.Button.copy)
                            .font(AXTypography.caption2)
                    }
                    .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(.plain)
            }

            Text(generateSQL())
                .font(AXTypography.monoSm)
                .foregroundColor(.axAccentGreen)
                .padding(AXSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.axBackground)
                .cornerRadius(AXCornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
        }
        .padding(AXSpacing.md)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.md)
    }

    // MARK: - Columns Section

    var columnsSection: some View {
        VStack(alignment: .leading, spacing: AXSpacing.md) {
            HStack {
                Text("COLUMNS")
                    .font(AXTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.axTextMuted)
                    .tracking(0.5)

                Text("\(columns.count)")
                    .font(AXTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.full)

                Spacer()

                Button { addColumn() } label: {
                    HStack(spacing: AXSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(AXTypography.caption2)
                        Text("Add Column")
                            .font(AXTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.axAccentBlue)
                    .padding(.horizontal, AXSpacing.sm)
                    .padding(.vertical, AXSpacing.xs)
                    .background(Color.axAccentBlue.opacity(0.1))
                    .cornerRadius(AXCornerRadius.sm)
                }
                .buttonStyle(.plain)
            }

            // Column headers
            columnHeaderRow

            // Column rows
            ForEach(columns.indices, id: \.self) { index in
                columnRow(index: index)
            }
        }
    }

    var columnHeaderRow: some View {
        HStack(spacing: AXSpacing.sm) {
            Text(L10n.Field.name)
                .frame(width: 140, alignment: .leading)
            Text("Type")
                .frame(width: 100, alignment: .leading)
            Text("Length")
                .frame(width: 55, alignment: .leading)
            // Constraint badges
            Text("🔑")
                .frame(width: 24, alignment: .center)
                .help("Primary Key")
            Text("⬛")
                .frame(width: 24, alignment: .center)
                .help("NOT NULL")
            Text("↗️")
                .frame(width: 24, alignment: .center)
                .help("Auto Increment")
            Text("✨")
                .frame(width: 24, alignment: .center)
                .help("Unique")
            Spacer()
        }
        .font(AXTypography.caption2)
        .fontWeight(.bold)
        .foregroundColor(.axTextMuted)
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xs)
        .background(Color.axSurface.opacity(0.5))
        .cornerRadius(AXCornerRadius.sm)
    }

    func columnRow(index: Int) -> some View {
        HStack(spacing: AXSpacing.sm) {
            TextField("column_name", text: $columns[index].name)
                .font(AXTypography.monoMd)
                .foregroundColor(.axTextPrimary)
                .textFieldStyle(.plain)
                .padding(AXSpacing.xs)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                        .stroke(Color.axBorder, lineWidth: 1)
                )
                .frame(width: 140)

            Picker("", selection: $columns[index].type) {
                ForEach(mysqlColumnTypes, id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .labelsHidden()
            .frame(width: 100)

            TextField("", text: Binding(
                get: { columns[index].length ?? "" },
                set: { columns[index].length = $0.isEmpty ? nil : $0 }
            ))
            .font(AXTypography.monoSm)
            .foregroundColor(.axTextPrimary)
            .textFieldStyle(.plain)
            .padding(AXSpacing.xs)
            .background(Color.axSurface)
            .cornerRadius(AXCornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                    .stroke(Color.axBorder, lineWidth: 1)
            )
            .frame(width: 55)

            // Constraint toggles
            constraintToggle($columns[index].isPrimaryKey, color: .axWarning)
            constraintToggle(
                Binding(get: { !columns[index].isNullable }, set: { columns[index].isNullable = !$0 }),
                color: .axTextSecondary
            )
            constraintToggle($columns[index].isAutoIncrement, color: .axAccentBlue)
            constraintToggle($columns[index].isUnique, color: .axAccentGreen)

            Spacer()

            if columns.count > 1 {
                Button {
                    let _ = withAnimation(.spring(response: 0.2)) { () -> Void in columns.remove(at: index) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(AXTypography.caption)
                        .foregroundColor(.axError.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AXSpacing.sm)
        .padding(.vertical, AXSpacing.xxs)
    }

    func constraintToggle(_ isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(isOn.wrappedValue ? color.opacity(0.2) : Color.axSurface)
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isOn.wrappedValue ? color.opacity(0.5) : Color.axBorder, lineWidth: 1)
                )
                .overlay(
                    isOn.wrappedValue ? Image(systemName: "checkmark")
                        .font(AXTypography.caption2).fontWeight(.bold)
                        .foregroundColor(color) : nil
                )
        }
        .buttonStyle(.plain)
    }


    // Footer and helpers → DBCreateTableView+Footer.swift
}
