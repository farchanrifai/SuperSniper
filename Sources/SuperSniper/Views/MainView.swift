import SwiftUI

// MARK: - Global Navigation State Coordinator
@MainActor
class NavigationState: ObservableObject {
    static let shared = NavigationState()
    @Published var selectedTab: MainView.SidebarTab = .dashboard
    private init() {}
}

struct MainView: View {
    enum SidebarTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case settings = "Settings"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .dashboard: return .blue
            case .settings: return .gray
            }
        }
    }
    
    @StateObject private var navState = NavigationState.shared
    
    var body: some View {
        NavigationSplitView {
            List(SidebarTab.allCases, selection: $navState.selectedTab) { tab in
                HStack(spacing: 10) {
                    SidebarIcon(name: tab.icon, color: tab.color)
                    
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 3)
                .tag(tab) // Critical fix: tag elements to enable list selection bindings
            }
            .listStyle(.sidebar)
            .navigationTitle("SuperSniper")
            .frame(minWidth: 180)
        } detail: {
            switch navState.selectedTab {
            case .dashboard:
                DashboardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
            case .settings:
                PreferencesView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

// MARK: - System Settings Icon Style Badge
struct SidebarIcon: View {
    let name: String
    let color: Color
    
    var body: some View {
        Image(systemName: name)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: color.opacity(0.15), radius: 1, x: 0, y: 0.5)
    }
}
