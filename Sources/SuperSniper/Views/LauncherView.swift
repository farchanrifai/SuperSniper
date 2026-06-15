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
    
    var isCompact: Bool {
        searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Top Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    TextField("Spotlight Search", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 26, weight: .light))
                        .focused($isSearchFocused)
                        .onChange(of: searchQuery) { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                updateSearch()
                            }
                        }
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
                .padding(.horizontal, 20)
                .frame(height: 64)
                
                if !isCompact {
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.5)
                    
                    ScrollViewReader { proxy in
                        List(selection: $selectedItem) {
                            ForEach(filteredItems, id: \.self) { item in
                                LauncherRowView(item: item, isSelected: selectedItem == item)
                                    .tag(item)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .frame(maxHeight: 400)
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
            }
            // Use .popover material to match Light/Dark mode gracefully like Spotlight
            .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 32 : 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 32 : 16, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            
            // This spacer pushes the search bar to the top of the 600pt invisible window bounding box
            Spacer(minLength: 0)
        }
        .frame(width: 700, height: 600, alignment: .top)
        
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
            // When compact, we don't show the list, but we still calculate results
            // in case we need them immediately when expanding
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
        guard !filteredItems.isEmpty && !isCompact else { return }
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
        // If they press enter while compact, execute the top hit
        let itemToExecute = isCompact ? filteredItems.first : selectedItem
        
        guard let item = itemToExecute else { return }
        
        LauncherWindowController.shared.hideWindow()
        
        if item.type == .application, let url = item.url {
            NSWorkspace.shared.open(url)
        } else if item.type == .tool {
            NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.executeTool"), object: item.name)
        }
    }
}

struct LauncherRowView: View {
    let item: LauncherItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Text(item.type == .application ? "Open ↵" : "Run ↵")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(10)
        .contentShape(Rectangle())
    }
}
