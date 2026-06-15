import SwiftUI

struct LauncherView: View {
    @StateObject private var searchManager = AppSearchManager.shared
    @State private var searchQuery = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var filteredItems: [LauncherItem] = []
    @State private var selectedItem: LauncherItem?
    @State private var activeToolContext: LauncherItem?
    
    @State private var mathResult: MathManager.MathResult?
    @State private var isVisible = false
    
    // Built-in tools
    let nativeTools = [
        LauncherItem(name: "Merge PDFs", subtitle: "Combine multiple PDF files", url: nil, icon: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Split PDF", subtitle: "Extract pages from a PDF", url: nil, icon: NSImage(systemSymbolName: "scissors", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Protect PDF", subtitle: "Add password encryption", url: nil, icon: NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Unlock PDF", subtitle: "Remove password encryption", url: nil, icon: NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: nil), type: .tool),
        LauncherItem(name: "Calculator History", subtitle: "View past calculations and conversions", url: nil, icon: NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil), type: .tool)
    ]
    
    var isCompact: Bool {
        if let tool = activeToolContext, tool.name == "Calculator History" {
            return false // We want to show the list for history
        }
        if activeToolContext != nil { return true }
        return searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Top Search Bar
                HStack(spacing: 12) {
                    if let tool = activeToolContext {
                        if let icon = tool.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .foregroundColor(.primary.opacity(0.8))
                        }
                        
                        Text(tool.name)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    
                    TextField(placeholderText(), text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 26, weight: .light))
                        .focused($isSearchFocused)
                        .onChange(of: searchQuery) { _ in
                            updateSearch()
                        }
                        .onSubmit { executeSelected() }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.launcherWindowDidOpen"))) { _ in
                            var transaction = Transaction(animation: nil)
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                isVisible = false
                                searchQuery = ""
                                activeToolContext = nil
                                updateSearch()
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                    isVisible = true
                                }
                                isSearchFocused = true
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("com.farchan.sniper.launcherWindowWillClose"))) { _ in
                            withAnimation(.easeOut(duration: 0.1)) {
                                isVisible = false
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
                
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.5)
                    
                    ScrollViewReader { proxy in
                        List {
                            ForEach(filteredItems, id: \.self) { item in
                                if item.name == "CalculatorResultSentinel", let res = mathResult {
                                    CalculatorResultView(result: res)
                                        .id(item)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .padding(.bottom, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedItem == item ? Color.accentColor : Color.clear, lineWidth: 3)
                                                .padding(.horizontal, 16)
                                                .padding(.top, 16)
                                                .padding(.bottom, 8)
                                        )
                                } else {
                                    LauncherRowView(item: item, isSelected: selectedItem == item)
                                        .id(item)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        .listStyle(.plain)
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
                .frame(height: isCompact ? 0 : 400)
                .opacity(isCompact ? 0 : 1)
                .clipped()
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isCompact)
            
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
    
    private func placeholderText() -> String {
        if let tool = activeToolContext {
            if tool.name == "Merge PDFs" { return "Enter new file name (optional)..." }
            if tool.name == "Split PDF" { return "Enter page count (e.g. 5) or size (e.g. 10MB)..." }
            if tool.name == "Calculator History" { return "Search history..." }
            return "Enter argument..."
        }
        return "Spotlight Search"
    }
    
    private func updateSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        
        if let tool = activeToolContext, tool.name == "Calculator History" {
            mathResult = nil
            let historyItems = CalculatorHistoryManager.shared.history.map { entry in
                LauncherItem(name: entry.expression, subtitle: entry.formattedResult, url: nil, icon: NSImage(systemSymbolName: "number.square", accessibilityDescription: nil), type: .calculatorHistory)
            }
            if trimmed.isEmpty {
                filteredItems = historyItems
            } else {
                filteredItems = historyItems.filter { $0.name.lowercased().contains(trimmed) || ($0.subtitle?.lowercased().contains(trimmed) ?? false) }
            }
            selectedItem = filteredItems.first
            return
        }
        
        var results: [LauncherItem] = []
        mathResult = MathManager.shared.evaluate(query: trimmed)
        
        if trimmed.isEmpty {
            // When compact, we don't show the list, but we still calculate results
            // in case we need them immediately when expanding
            results.append(contentsOf: nativeTools)
            results.append(contentsOf: searchManager.installedApps.prefix(20))
        } else {
            if mathResult != nil {
                let calcItem = LauncherItem(name: "CalculatorResultSentinel", subtitle: nil, url: nil, icon: nil, type: .tool)
                results.append(calcItem)
            }
            
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
            if activeToolContext != nil {
                activeToolContext = nil
                searchQuery = ""
                return
            }
            LauncherWindowController.shared.hideWindow()
            return
        }
        
        if keyCode == 48 { // Tab
            if let selected = selectedItem, selected.type == .tool, activeToolContext == nil {
                activeToolContext = selected
                searchQuery = ""
            }
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
        if let tool = activeToolContext {
            LauncherWindowController.shared.hideWindow()
            let payload: [String: String] = ["tool": tool.name, "arg": searchQuery]
            NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.executeTool"), object: payload)
            return
        }
        
        // If they press enter while compact, execute the top hit
        let itemToExecute = isCompact ? filteredItems.first : selectedItem
        
        guard let item = itemToExecute else { return }
        
        LauncherWindowController.shared.hideWindow()
        
        if item.name == "CalculatorResultSentinel", let res = mathResult {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(res.formattedResult, forType: .string)
            CalculatorHistoryManager.shared.addEntry(expression: res.expression, result: res.result, formattedResult: res.formattedResult)
            HUDManager.shared.showHUD(with: "Copied \(res.formattedResult)")
            return
        }
        
        if item.type == .calculatorHistory {
            if let resultText = item.subtitle {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(resultText, forType: .string)
                HUDManager.shared.showHUD(with: "Copied \(resultText)")
            }
            return
        }
        
        if item.type == .application, let url = item.url {
            NSWorkspace.shared.open(url)
        } else if item.type == .tool {
            let payload: [String: String] = ["tool": item.name, "arg": ""]
            NotificationCenter.default.post(name: Notification.Name("com.farchan.sniper.executeTool"), object: payload)
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
                Text(item.type == .application ? "Open ↵" : (item.type == .calculatorHistory ? "Copy ↵" : "Run ↵"))
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
