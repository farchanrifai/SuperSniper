import SwiftUI

struct HistoryListView: View {
    @ObservedObject var history = HistoryManager.shared
    @State private var searchQuery = ""
    @State private var selectedItem: HistoryItem?
    
    var filteredItems: [HistoryItem] {
        if searchQuery.isEmpty {
            return history.items
        } else {
            return history.items.filter { $0.displayText.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Type to filter entries...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                Spacer()
                
                Menu {
                    Button("All Types", action: {})
                    Button("Text", action: {})
                    Button("Images", action: {})
                    Button("Files", action: {})
                } label: {
                    Text("All Types")
                        .font(.system(size: 12))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            Divider()
            
            HStack(spacing: 0) {
                // Left Sidebar (List)
                VStack(spacing: 0) {
                    if filteredItems.isEmpty {
                        Spacer()
                        Text("No clipboard history")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredItems) { item in
                                    HistoryRowView(item: item, isSelected: selectedItem?.id == item.id)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .frame(width: 280)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Right Inspector (Detail)
                VStack(spacing: 0) {
                    if let selected = selectedItem {
                        // Content Preview Area
                        ScrollView {
                            VStack {
                                switch selected.type {
                                case .text:
                                    if let text = selected.text {
                                        Text(text)
                                            .font(.system(size: 13, design: .monospaced))
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                            .padding()
                                    }
                                case .image:
                                    if let fileName = selected.imageFileName, let image = HistoryManager.shared.getImage(for: fileName) {
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .padding()
                                    } else {
                                        Text("Image not found")
                                            .foregroundColor(.red)
                                    }
                                case .file:
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.accentColor)
                                        Text(selected.fileURL?.path ?? "Unknown File")
                                            .font(.system(size: 12))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        
                        Divider()
                        
                        // Metadata Table
                        VStack(spacing: 0) {
                            MetadataRow(title: "Source", value: selected.sourceApp ?? "Unknown")
                            Divider().padding(.leading, 16)
                            MetadataRow(title: "Content type", value: selected.type.rawValue.capitalized)
                            
                            if selected.type == .text {
                                Divider().padding(.leading, 16)
                                MetadataRow(title: "Characters", value: "\(selected.charactersCount ?? 0)")
                                Divider().padding(.leading, 16)
                                MetadataRow(title: "Words", value: "\(selected.wordsCount ?? 0)")
                            }
                            
                            Divider().padding(.leading, 16)
                            MetadataRow(title: "Times copied", value: "\(selected.copyCount)")
                            Divider().padding(.leading, 16)
                            MetadataRow(title: "Last copied", value: relativeTimeString(selected.timestamp))
                        }
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        
                    } else {
                        VStack {
                            Spacer()
                            Image(systemName: "clipboard")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("Select an item to view details")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
            
            Divider()
            
            // Bottom Footer
            HStack {
                Image(systemName: "clipboard.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .cornerRadius(6)
                
                Text("Clipboard History")
                    .font(.system(size: 12, weight: .medium))
                
                Spacer()
                
                Text("Paste to Active App ↩")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Divider().frame(height: 12).padding(.horizontal, 4)
                
                Text("Actions ⌘K")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        }
        .onAppear {
            if selectedItem == nil {
                selectedItem = history.items.first
            }
        }
        // Background click to deselect or just generally clear selection if desired.
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct HistoryRowView: View {
    let item: HistoryItem
    let isSelected: Bool
    
    var iconName: String {
        switch item.type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 16)
            
            Text(item.displayText.replacingOccurrences(of: "\n", with: " "))
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct MetadataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
    }
}
