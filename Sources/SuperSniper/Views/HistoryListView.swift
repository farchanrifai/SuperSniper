import SwiftUI
import CoreGraphics

struct ActionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    var color: Color = .primary
    let shortcutText: String
    let perform: () -> Void
}

struct HistoryListView: View {
    @ObservedObject var history = HistoryManager.shared
    @State private var searchQuery = ""
    @State private var selectedItem: HistoryItem?
    
    @FocusState private var isSearchFocused: Bool
    @State private var showingActionsMenu = false
    @State private var selectedActionIndex = 0
    
    var filteredItems: [HistoryItem] {
        if searchQuery.isEmpty {
            return history.items
        } else {
            return history.items.filter { $0.displayText.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var currentActions: [ActionItem] {
        var actions: [ActionItem] = []
        
        actions.append(ActionItem(title: "Paste to Active App", icon: "arrow.uturn.down", shortcutText: "↵") {
            pasteSelected()
        })
        
        actions.append(ActionItem(title: "Copy to Clipboard", icon: "doc.on.doc", shortcutText: "⌘ C") {
            copyToClipboard()
        })
        
        if selectedItem?.type == .file {
            actions.append(ActionItem(title: "Open in Finder", icon: "folder", shortcutText: "⌘ O") {
                openInFinder()
            })
        }
        
        actions.append(ActionItem(title: "Delete from History", icon: "trash", color: .red, shortcutText: "⌫") {
            deleteSelected()
        })
        
        return actions
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
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(filteredItems) { item in
                                            HistoryRowView(item: item, isSelected: selectedItem?.id == item.id)
                                                .id(item.id)
                                                .onTapGesture {
                                                    selectedItem = item
                                                }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                .scrollContentBackground(.hidden)
                                .onChange(of: selectedItem) { newValue in
                                    if let newId = newValue?.id {
                                        // Omitting anchor allows SwiftUI to scroll just enough to make the item visible at the bottom or top
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            proxy.scrollTo(newId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 280)
                    
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
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            
            // Actions Menu Overlay
            if showingActionsMenu {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ActionsMenuView(
                            actions: currentActions,
                            selectedIndex: selectedActionIndex
                        )
                        .padding([.trailing, .bottom], 16)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.clipboardWindowDidOpen"))) { _ in
            // Reset state
            showingActionsMenu = false
            selectedActionIndex = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
            if selectedItem == nil {
                selectedItem = filteredItems.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.rawKeyPressed"))) { notification in
            guard let keyCode = notification.object as? UInt16 else { return }
            handleRawKey(keyCode)
        }
        .onAppear {
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
            Button("Actions") { 
                selectedActionIndex = 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingActionsMenu.toggle() 
                }
            }
            .keyboardShortcut("k", modifiers: .command)
            .hidden()
        )
    }
    
    // MARK: - Key Handling
    
    private func handleRawKey(_ keyCode: UInt16) {
        if showingActionsMenu {
            // Context: Actions Menu
            switch keyCode {
            case 126: // Up
                selectedActionIndex = max(0, selectedActionIndex - 1)
            case 125: // Down
                selectedActionIndex = min(currentActions.count - 1, selectedActionIndex + 1)
            case 36: // Return
                currentActions[selectedActionIndex].perform()
            case 53: // Esc
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingActionsMenu = false
                }
            default: break
            }
        } else {
            // Context: Main List
            switch keyCode {
            case 126: // Up
                moveSelection(direction: -1)
            case 125: // Down
                moveSelection(direction: 1)
            case 36: // Return
                pasteSelected()
            case 53: // Esc
                ClipboardWindowController.shared.hideWindow()
            default: break
            }
        }
    }
    
    private func moveSelection(direction: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItem?.id }) ?? -1
        let newIndex = max(0, min(filteredItems.count - 1, currentIndex + direction))
        if newIndex != currentIndex {
            selectedItem = filteredItems[newIndex]
        }
    }
    
    // MARK: - Actions
    
    private func pasteSelected() {
        guard let item = selectedItem else { return }
        copyItemToPasteboard(item)
        
        ClipboardWindowController.shared.hideWindow()
        NSApp.hide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            simulatePaste()
        }
    }
    
    private func copyToClipboard() {
        guard let item = selectedItem else { return }
        copyItemToPasteboard(item)
        showingActionsMenu = false
        ClipboardWindowController.shared.hideWindow()
    }
    
    private func openInFinder() {
        guard let url = selectedItem?.fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        showingActionsMenu = false
        ClipboardWindowController.shared.hideWindow()
    }
    
    private func copyItemToPasteboard(_ item: HistoryItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        ClipboardObserver.shared.ignoreNextChange()
        
        switch item.type {
        case .text:
            if let text = item.text { pb.setString(text, forType: .string) }
        case .image:
            if let fileName = item.imageFileName, let image = HistoryManager.shared.getImage(for: fileName) {
                pb.writeObjects([image])
            }
        case .file:
            if let url = item.fileURL { pb.writeObjects([url as NSURL]) }
        }
    }
    
    private func deleteSelected() {
        guard let item = selectedItem else { return }
        let id = item.id
        
        let nextItem: HistoryItem?
        if let idx = filteredItems.firstIndex(where: { $0.id == id }) {
            if idx + 1 < filteredItems.count { nextItem = filteredItems[idx + 1] }
            else if idx > 0 { nextItem = filteredItems[idx - 1] }
            else { nextItem = nil }
        } else { nextItem = nil }
        
        HistoryManager.shared.deleteEntry(id: id)
        selectedItem = nextItem
        showingActionsMenu = false
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
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
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
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
    let actions: [ActionItem]
    let selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 4) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    ActionMenuRow(action: action, isSelected: index == selectedIndex)
                }
            }
            .padding(8)
            
            Divider()
            
            HStack {
                Text("Search actions...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
        .glassEffect(in: RoundedRectangle(cornerRadius: 12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
    }
}

struct ActionMenuRow: View {
    let action: ActionItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : action.color)
                .frame(width: 16)
            
            Text(action.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : action.color)
            
            Spacer()
            
            Text(action.shortcutText)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
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
