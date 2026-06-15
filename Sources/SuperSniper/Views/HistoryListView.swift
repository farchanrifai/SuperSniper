import SwiftUI
import CoreGraphics

struct HistoryListView: View {
    @ObservedObject var history = HistoryManager.shared
    @State private var searchQuery = ""
    @State private var selectedItem: HistoryItem?
    
    @FocusState private var isSearchFocused: Bool
    @State private var showingActionsMenu = false
    
    var filteredItems: [HistoryItem] {
        if searchQuery.isEmpty {
            return history.items
        } else {
            return history.items.filter { $0.displayText.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Type to filter entries...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($isSearchFocused)
                        .onSubmit {
                            pasteSelected()
                        }
                    
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
                            List(selection: $selectedItem) {
                                ForEach(filteredItems) { item in
                                    HistoryRowView(item: item, isSelected: selectedItem?.id == item.id)
                                        .tag(item)
                                        .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .padding(.vertical, 8)
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
                                        if let url = selected.fileURL,
                                           ["png", "jpg", "jpeg", "heic", "tiff", "gif", "bmp", "webp"].contains(url.pathExtension.lowercased()),
                                           let image = NSImage(contentsOf: url) {
                                            Image(nsImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .padding()
                                        } else {
                                            VStack(spacing: 12) {
                                                Image(systemName: "doc.fill")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.accentColor)
                                                Text(selected.fileURL?.path ?? "Unknown File")
                                                    .font(.system(size: 12))
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(3)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
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
            
            if showingActionsMenu {
                ActionsMenuView(
                    item: selectedItem,
                    onDismiss: { showingActionsMenu = false },
                    onPaste: pasteSelected,
                    onDelete: deleteSelected
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.clipboardWindowDidOpen"))) { _ in
            // Slight delay ensures the window has become key before requesting focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
            if selectedItem == nil {
                selectedItem = filteredItems.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.arrowKeyPressed"))) { notification in
            if let keyCode = notification.object as? UInt16 {
                // 126 = Up, 125 = Down
                if keyCode == 126 {
                    moveSelection(direction: .up)
                } else if keyCode == 125 {
                    moveSelection(direction: .down)
                }
            }
        }
        .onAppear {
            // Initial load
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
            if selectedItem == nil {
                selectedItem = filteredItems.first
            }
        }
        .onChange(of: searchQuery) { _ in
            if !filteredItems.isEmpty {
                selectedItem = filteredItems.first
            }
        }
        .background(
            Group {
                Button("Paste") { pasteSelected() }
                    .keyboardShortcut(.defaultAction)
                    .hidden()
                
                Button("Actions") { showingActionsMenu.toggle() }
                    .keyboardShortcut("k", modifiers: .command)
                    .hidden()
            }
        )
    }
    
    private func pasteSelected() {
        guard let item = selectedItem else { return }
        
        let pb = NSPasteboard.general
        pb.clearContents()
        
        ClipboardObserver.shared.ignoreNextChange()
        
        switch item.type {
        case .text:
            if let text = item.text {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let fileName = item.imageFileName, let image = HistoryManager.shared.getImage(for: fileName) {
                pb.writeObjects([image])
            }
        case .file:
            if let url = item.fileURL {
                pb.writeObjects([url as NSURL])
            }
        }
        
        ClipboardWindowController.shared.hideWindow()
        NSApp.hide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulatePaste()
        }
    }
    
    private func deleteSelected() {
        guard let item = selectedItem else { return }
        let id = item.id
        
        // Find next item to select before deleting
        let nextItem: HistoryItem?
        if let idx = filteredItems.firstIndex(where: { $0.id == id }) {
            if idx + 1 < filteredItems.count {
                nextItem = filteredItems[idx + 1]
            } else if idx > 0 {
                nextItem = filteredItems[idx - 1]
            } else {
                nextItem = nil
            }
        } else {
            nextItem = nil
        }
        
        HistoryManager.shared.deleteEntry(id: id)
        selectedItem = nextItem
        showingActionsMenu = false
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func moveSelection(direction: MoveCommandDirection) {
        guard !filteredItems.isEmpty else { return }
        
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItem?.id }) ?? -1
        
        var newIndex = currentIndex
        switch direction {
        case .up:
            newIndex = max(0, currentIndex - 1)
        case .down:
            newIndex = min(filteredItems.count - 1, currentIndex + 1)
        default:
            return
        }
        
        if newIndex != currentIndex {
            selectedItem = filteredItems[newIndex]
        }
    }
}

// MARK: - Subviews

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

// MARK: - Actions Menu Overlay

struct ActionsMenuView: View {
    let item: HistoryItem?
    let onDismiss: () -> Void
    let onPaste: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            // Darkened background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Menu Panel
            VStack(alignment: .leading, spacing: 0) {
                Text("Actions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                
                Divider()
                
                VStack(spacing: 4) {
                    ActionRow(title: "Paste to Active App", icon: "arrow.uturn.down", action: onPaste)
                    ActionRow(title: "Delete from History", icon: "trash", color: .red, action: onDelete)
                }
                .padding(8)
            }
            .frame(width: 300)
            .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

struct ActionRow: View {
    let title: String
    let icon: String
    var color: Color = .primary
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isHovered ? .white : color)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isHovered ? .white : color)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isHovered ? Color.accentColor : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovered = hover
        }
    }
}

// MARK: - CGEvent Paste Simulation

func simulatePaste() {
    let source = CGEventSource(stateID: .hidSystemState)
    let vKeyCode: CGKeyCode = 0x09 // 'v'
    
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
       let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
        
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
