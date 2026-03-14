//
//  TerminalSnippetsSheet.swift
//  AevonX
//
//  Quick command snippets panel — built-in + user custom snippets
//

import SwiftUI
import Combine
import AevonXCoreBridge

// MARK: - Custom Snippets Manager

@MainActor
class CustomSnippetsManager: ObservableObject {
    static let shared = CustomSnippetsManager()
    
    @Published var customSnippets: [CommandSnippet] = []
    
    private let storageKey = "terminal.customSnippets"
    
    private init() {
        loadSnippets()
    }
    
    func addSnippet(name: String, command: String, category: String, icon: String) {
        let snippet = CommandSnippet(name: name, command: command, category: category, icon: icon)
        customSnippets.append(snippet)
        saveSnippets()
    }
    
    func deleteSnippet(_ snippet: CommandSnippet) {
        customSnippets.removeAll { $0.id == snippet.id }
        saveSnippets()
    }
    
    var allSnippets: [CommandSnippet] {
        customSnippets + CommandSnippet.builtInSnippets
    }
    
    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(customSnippets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadSnippets() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([CommandSnippet].self, from: data) else { return }
        customSnippets = loaded
    }
}

// MARK: - Terminal Snippets Sheet

struct TerminalSnippetsSheet: View {
    @ObservedObject var viewModel: TerminalViewModel
    @StateObject private var snippetsManager = CustomSnippetsManager.shared
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = "All"
    @State private var showAddSheet: Bool = false
    @State private var hoveredSnippetId: String?
    
    private var categories: [String] {
        var cats = ["All"]
        if !snippetsManager.customSnippets.isEmpty {
            cats.append("⭐ My Snippets")
        }
        let unique = Set(snippetsManager.allSnippets.map { $0.category })
        cats.append(contentsOf: unique.sorted())
        return cats
    }
    
    private var filteredSnippets: [CommandSnippet] {
        let source: [CommandSnippet]
        if selectedCategory == "⭐ My Snippets" {
            source = snippetsManager.customSnippets
        } else {
            source = snippetsManager.allSnippets
        }
        
        return source.filter { snippet in
            let matchesCategory = selectedCategory == "All" || selectedCategory == "⭐ My Snippets" || snippet.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                snippet.name.localizedCaseInsensitiveContains(searchText) ||
                snippet.command.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    private func isCustom(_ snippet: CommandSnippet) -> Bool {
        snippetsManager.customSnippets.contains(where: { $0.id == snippet.id })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar
            
            Divider().background(Color.axBorder)
            
            // Category tabs + search
            filterBar
            
            Divider().background(Color.axBorder)
            
            // Snippets list
            snippetsList
        }
        .frame(width: 580, height: 500)
        .background(Color.axBackground)
        .sheet(isPresented: $showAddSheet) {
            AddSnippetSheet(manager: snippetsManager)
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            HStack(spacing: AXSpacing.sm) {
                Image(systemName: "command.square.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.axAccentBlue, .axAccentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Command Snippets")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                    Text("\(snippetsManager.allSnippets.count) commands • \(snippetsManager.customSnippets.count) custom")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted)
                }
            }
            
            Spacer()
            
            // Add button
            Button(action: { showAddSheet = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("New Snippet")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(AXCornerRadius.md)
                .shadow(color: .axAccentBlue.opacity(0.2), radius: 4, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.axTextMuted)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 8)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.lg)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: AXSpacing.md) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AXSpacing.xs) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .font(.system(size: 11, weight: selectedCategory == category ? .semibold : .medium))
                                .foregroundColor(selectedCategory == category ? .white : .axTextSecondary)
                                .padding(.horizontal, AXSpacing.md)
                                .padding(.vertical, 5)
                                .background(
                                    selectedCategory == category
                                        ? AnyShapeStyle(LinearGradient(colors: [.axAccentBlue, .axAccentBlue.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                        : AnyShapeStyle(Color.axBackgroundTertiary)
                                )
                                .cornerRadius(AXCornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            HStack(spacing: AXSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.axTextMuted)
                TextField("Search...", text: $searchText)
                    .font(.system(size: 11))
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, AXSpacing.sm)
            .padding(.vertical, 5)
            .background(Color.axBackgroundTertiary)
            .overlay(RoundedRectangle(cornerRadius: AXCornerRadius.sm).stroke(Color.axBorder, lineWidth: 1))
            .cornerRadius(AXCornerRadius.sm)
            .frame(width: 150)
        }
        .padding(.horizontal, AXSpacing.xl)
        .padding(.vertical, AXSpacing.md)
    }
    
    // MARK: - Snippets List
    
    private var snippetsList: some View {
        ScrollView {
            LazyVStack(spacing: AXSpacing.xs) {
                // Custom snippets section header
                if selectedCategory == "All" && !snippetsManager.customSnippets.isEmpty {
                    sectionHeader("⭐ My Snippets", count: snippetsManager.customSnippets.count)
                }
                
                ForEach(filteredSnippets) { snippet in
                    snippetRow(snippet)
                }
                
                if filteredSnippets.isEmpty {
                    VStack(spacing: AXSpacing.lg) {
                        Image(systemName: "text.page.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.axTextMuted)
                        
                        VStack(spacing: AXSpacing.xs) {
                            Text("No snippets found")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.axTextSecondary)
                            Text("Try a different search or add a new snippet")
                                .font(.system(size: 12))
                                .foregroundColor(.axTextMuted)
                        }
                        
                        Button(action: { showAddSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Add Snippet")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.axAccentBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.axAccentBlue.opacity(0.1))
                            .cornerRadius(AXCornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                }
            }
            .padding(AXSpacing.lg)
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.axTextTertiary)
                .textCase(.uppercase)
                .tracking(0.6)
            
            Text("\(count)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.axAccentGreen)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.axAccentGreen.opacity(0.1))
                .cornerRadius(4)
            
            Rectangle()
                .fill(Color.axBorder.opacity(0.5))
                .frame(height: 1)
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Snippet Row
    
    private func snippetRow(_ snippet: CommandSnippet) -> some View {
        let isHovered = hoveredSnippetId == snippet.id
        let custom = isCustom(snippet)
        
        return HStack(spacing: AXSpacing.md) {
            // Click to insert
            Button(action: { viewModel.insertSnippet(snippet); dismiss() }) {
                HStack(spacing: AXSpacing.md) {
                    // Icon
                    Image(systemName: snippet.icon)
                        .font(.system(size: 14))
                        .foregroundColor(custom ? .axAccentGreen : .axAccentBlue)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                .fill((custom ? Color.axAccentGreen : Color.axAccentBlue).opacity(0.1))
                        )
                    
                    // Name & command
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(snippet.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.axTextPrimary)
                            if custom {
                                Text("Custom")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.axAccentGreen)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.axAccentGreen.opacity(0.12))
                                    .cornerRadius(3)
                            }
                        }
                        Text(snippet.command)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.axTextTertiary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Category badge
                    Text(snippet.category)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.axTextTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.axBorder.opacity(0.4))
                        .cornerRadius(AXCornerRadius.md)
                    
                    // Run icon
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isHovered ? .axAccentBlue : .axTextMuted)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete for custom only
            if custom {
                Button(action: { withAnimation(.easeOut(duration: 0.2)) { snippetsManager.deleteSnippet(snippet) } }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.axError.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .background(Color.axError.opacity(0.06))
                        .cornerRadius(AXCornerRadius.xs)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete snippet")
            }
        }
        .padding(.horizontal, AXSpacing.md)
        .padding(.vertical, AXSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .fill(isHovered ? Color.axSurfaceHover : Color.axSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                .stroke(isHovered ? Color.axBorder : Color.clear, lineWidth: 0.5)
        )
        .onHover { hovering in
            hoveredSnippetId = hovering ? snippet.id : nil
        }
    }
}

// MARK: - Add Snippet Sheet

struct AddSnippetSheet: View {
    @ObservedObject var manager: CustomSnippetsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var command: String = ""
    @State private var category: String = "My Snippets"
    @State private var selectedIcon: String = "terminal"
    
    private let iconOptions = [
        "terminal", "terminal.fill", "command", "chevron.left.forwardslash.chevron.right",
        "gear", "server.rack", "network", "globe", "doc.text", "folder",
        "arrow.clockwise", "bolt", "cpu", "memorychip", "internaldrive",
        "shield", "lock", "key", "clock", "chart.bar",
        "arrow.triangle.branch", "shippingbox", "scroll", "wrench", "hammer"
    ]
    
    private let categoryOptions = [
        "My Snippets", "System", "Docker", "Git", "Nginx", "Network", "Database", "Security"
    ]
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.axAccentGreen, .axAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("New Custom Snippet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.axTextPrimary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.axTextMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AXSpacing.xl)
            .padding(.vertical, AXSpacing.lg)
            
            Divider().background(Color.axBorder)
            
            ScrollView {
                VStack(spacing: AXSpacing.xl) {
                    // Name
                    formField("Name", hint: "Short descriptive name") {
                        TextField("e.g. Check Logs", text: $name)
                            .font(.system(size: 13))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.axBackgroundTertiary)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(name.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    // Command
                    formField("Command", hint: "The exact command to run") {
                        TextField("e.g. tail -f /var/log/syslog", text: $command)
                            .font(.system(size: 13, design: .monospaced))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color.axBackgroundTertiary)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(command.isEmpty ? Color.axBorder : Color.axAccentBlue.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    // Category + Icon side by side
                    HStack(alignment: .top, spacing: AXSpacing.xl) {
                        // Category
                        formField("Category") {
                            Picker("", selection: $category) {
                                ForEach(categoryOptions, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.axBackgroundTertiary)
                            .cornerRadius(AXCornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.sm)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Icon
                        formField("Icon") {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 4), count: 5), spacing: 4) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button(action: { selectedIcon = icon }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 12))
                                            .foregroundColor(selectedIcon == icon ? .white : .axTextSecondary)
                                            .frame(width: 28, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(selectedIcon == icon ? Color.axAccentBlue : Color.axBackgroundTertiary)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(selectedIcon == icon ? Color.axAccentBlue : Color.axBorder.opacity(0.5), lineWidth: 0.5)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .frame(width: 180)
                    }
                    
                    // Live Preview
                    if isValid {
                        VStack(alignment: .leading, spacing: AXSpacing.xs) {
                            Text("PREVIEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.axTextMuted)
                                .tracking(1)
                            
                            HStack(spacing: AXSpacing.md) {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.axAccentGreen)
                                    .frame(width: 30, height: 30)
                                    .background(Color.axAccentGreen.opacity(0.1))
                                    .cornerRadius(AXCornerRadius.sm)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.axTextPrimary)
                                        Text("Custom")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.axAccentGreen)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.axAccentGreen.opacity(0.12))
                                            .cornerRadius(3)
                                    }
                                    Text(command)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.axTextTertiary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(category)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.axTextTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.axBorder.opacity(0.4))
                                    .cornerRadius(AXCornerRadius.md)
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.axAccentBlue)
                            }
                            .padding(AXSpacing.md)
                            .background(Color.axSurface)
                            .cornerRadius(AXCornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axAccentGreen.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(AXSpacing.xl)
            }
            
            Divider().background(Color.axBorder)
            
            // Action buttons
            HStack {
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.axTextSecondary)
                    .padding(.horizontal, AXSpacing.lg)
                    .padding(.vertical, 8)
                
                Button(action: {
                    manager.addSnippet(
                        name: name.trimmingCharacters(in: .whitespaces),
                        command: command.trimmingCharacters(in: .whitespaces),
                        category: category,
                        icon: selectedIcon
                    )
                    dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add Snippet")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AXSpacing.xl)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: isValid
                                ? [.axAccentBlue, .axAccentBlue.opacity(0.8)]
                                : [Color.axTextMuted.opacity(0.5), Color.axTextMuted.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(AXCornerRadius.md)
                    .shadow(color: isValid ? .axAccentBlue.opacity(0.2) : .clear, radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isValid)
            }
            .padding(AXSpacing.lg)
        }
        .frame(width: 500, height: 530)
        .background(Color.axBackground)
    }
    
    // MARK: - Form Field
    
    private func formField<Content: View>(_ title: String, hint: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AXSpacing.xs) {
            HStack(spacing: AXSpacing.xs) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.axTextMuted)
                    .tracking(0.8)
                
                if let hint = hint {
                    Text("• \(hint)")
                        .font(.system(size: 10))
                        .foregroundColor(.axTextMuted.opacity(0.6))
                }
            }
            
            content()
        }
    }
}
