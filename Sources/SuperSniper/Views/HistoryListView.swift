import SwiftUI

struct HistoryListView: View {
    @ObservedObject var history = HistoryManager.shared
    @State private var searchQuery = ""
    @State private var selectedItem: HistoryItem?
    @State private var isCopied = false
    
    var filteredItems: [HistoryItem] {
        if searchQuery.isEmpty {
            return history.items
        } else {
            return history.items.filter { $0.text.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Column: List & Search
            VStack(alignment: .leading, spacing: 0) {
                // Search bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    
                    TextField("Search text...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                // List content
                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(searchQuery.isEmpty ? "No clippings yet." : "No matches found.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List(selection: $selectedItem) {
                        ForEach(filteredItems) { item in
                            HistoryRow(item: item, isSelected: selectedItem?.id == item.id)
                                .tag(item)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(width: 260)
            
            Divider()
            
            // Right Column: Editor Workspace
            VStack(spacing: 0) {
                if let selected = selectedItem,
                   let index = history.items.firstIndex(where: { $0.id == selected.id }) {
                    
                    let binding = Binding<String>(
                        get: { history.items[index].text },
                        set: { newText in
                            history.items[index] = HistoryItem(
                                id: selected.id,
                                text: newText,
                                timestamp: selected.timestamp
                            )
                            history.items = history.items // Force didSet refresh
                        }
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title bar
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clipping Workspace")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(formatDate(selected.timestamp))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { deleteItem(selected.id) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.8))
                                    .font(.system(size: 12))
                                    .frame(width: 24, height: 24)
                                    .background(Color.red.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Delete clipping")
                        }
                        
                        // Workspace utilities row
                        HStack(spacing: 8) {
                            FormatButton(title: "UPPERCASE", icon: "arrow.up.circle") {
                                binding.wrappedValue = binding.wrappedValue.uppercased()
                            }
                            
                            FormatButton(title: "lowercase", icon: "arrow.down.circle") {
                                binding.wrappedValue = binding.wrappedValue.lowercased()
                            }
                            
                            FormatButton(title: "Trim Spaces", icon: "wand.and.stars") {
                                let trimmed = binding.wrappedValue
                                    .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
                                    .replacingOccurrences(of: "(\n)+", with: "\n", options: .regularExpression)
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                binding.wrappedValue = trimmed
                            }
                            
                            Spacer()
                        }
                        
                        // Text Editor (Glassmorphic Window Overlay)
                        TextEditor(text: binding)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        // Bottom row buttons
                        HStack {
                            Text("\(binding.wrappedValue.count) characters")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: { copyToClipboard(binding.wrappedValue) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                    Text(isCopied ? "Copied!" : "Copy Clipboard")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isCopied ? Color.green.opacity(0.2) : Color.accentColor)
                                .foregroundColor(isCopied ? .green : .white)
                                .cornerRadius(6)
                                .shadow(color: isCopied ? Color.clear : Color.accentColor.opacity(0.2), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    // Empty state editor panel
                    VStack(spacing: 12) {
                        Image(systemName: "text.justify.leading")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.4))
                        
                        Text("Select a clip to preview or edit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            if selectedItem == nil, let first = filteredItems.first {
                selectedItem = first
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }
    
    private func deleteItem(_ id: UUID) {
        history.deleteEntry(id: id)
        if selectedItem?.id == id {
            selectedItem = history.items.first
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Row Subview Redesign
struct HistoryRow: View {
    let item: HistoryItem
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text.replacingOccurrences(of: "\n", with: " "))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            HStack {
                Text(relativeTimeString(item.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                
                Spacer()
                
                Text("\(item.text.count) ch")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.06))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.04), lineWidth: 0.5)
        )
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Formatting Action Button
struct FormatButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
            .foregroundColor(.primary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hover
            }
        }
    }
}
