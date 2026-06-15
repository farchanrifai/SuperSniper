import SwiftUI

struct LauncherView: View {
    @StateObject private var searchManager = AppSearchManager.shared
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var filteredItems: [LauncherItem] = []
    @State private var selectedItem: LauncherItem?
    
    // Built-in tools
    let nativeTools = [
        LauncherItem(name: "Merge PDFs", subtitle: "Combine multiple PDF files", url: nil, icon: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Split PDF", subtitle: "Extract pages from a PDF", url: nil, icon: NSImage(systemSymbolName: "scissors", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Protect PDF", subtitle: "Add password encryption", url: nil, icon: NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Unlock PDF", subtitle: "Remove password encryption", url: nil, icon: NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: nil), type: .tool)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.secondary)
                
                TextField("Search Apps & Commands...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .regular))
                    .focused($isSearchFocused)
                    .onChange(of: searchQuery) { _ in updateSearch() }
                    .onSubmit { executeSelected() }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.launcherWindowDidOpen"))) { _ in
                        searchQuery = ""
                        updateSearch()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFocused = true
                        }
                    }
                    .onAppear {
                        updateSearch()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFocused = true
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
            
            ScrollViewReader { proxy in
                List(selection: $selectedItem) {
                    ForEach(filteredItems, id: \.self) { item in
                        LauncherRowView(item: item, isSelected: selectedItem == item)
                            .tag(item)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                }
                .scrollContentBackground(.hidden)
                .onChange(of: selectedItem) { newValue in
                    if let newId = newValue {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(newId)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 750, height: 450)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        // Key Routing
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.launcherKeyPressed"))) { notification in
            if let keyCode = notification.object as? UInt16 {
                handleRawKey(keyCode)
            }
        }
    }
    
    private func updateSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        
        var results: [LauncherItem] = []
        
        if trimmed.isEmpty {
            results.append(contentsOf: nativeTools)
            results.append(contentsOf: searchManager.installedApps.prefix(20))
        } else {
            let toolsMatch = nativeTools.filter { $0.name.lowercased().contains(trimmed) }
            let appsMatch = searchManager.search(query: trimmed)
            results.append(contentsOf: toolsMatch)
            results.append(contentsOf: appsMatch)
        }
        
        filteredItems = results
        
        if !results.isEmpty {
            if selectedItem == nil || !results.contains(selectedItem!) {
                selectedItem = results.first
            }
        } else {
            selectedItem = nil
        }
    }
    
    private func handleRawKey(_ keyCode: UInt16) {
        if keyCode == 53 { // Esc
            LauncherWindowController.shared.hideWindow()
            return
        }
        
        if keyCode == 36 { // Return
            executeSelected()
            return
        }
        
        // Navigation
        guard !filteredItems.isEmpty else { return }
        let currentIndex = filteredItems.firstIndex(where: { $0 == selectedItem }) ?? -1
        
        if keyCode == 125 { // Down
            let nextIndex = currentIndex + 1
            if nextIndex < filteredItems.count {
                selectedItem = filteredItems[nextIndex]
            }
        } else if keyCode == 126 { // Up
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                selectedItem = filteredItems[prevIndex]
            }
        }
    }
    
    private func executeSelected() {
        guard let item = selectedItem else { return }
        
        LauncherWindowController.shared.hideWindow()
        
        if item.type == .application, let url = item.url {
            NSWorkspace.shared.open(url)
        } else if item.type == .tool {
            // Trigger PDF tool execution
            NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.executeTool"), object: item.name)
        }
    }
}

struct LauncherRowView: View {
    let item: LauncherItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Text(item.type == .application ? "Open ↵" : "Run ↵")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}
