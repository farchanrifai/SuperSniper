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
        HStack(spacing: 0) {
            // Custom un-collapsible Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("SuperSniper")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ForEach(SidebarTab.allCases) { tab in
                    Button(action: {
                        navState.selectedTab = tab
                    }) {
                        HStack(spacing: 10) {
                            SidebarIcon(name: tab.icon, color: tab.color)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(navState.selectedTab == tab ? .white : .primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(navState.selectedTab == tab ? Color.accentColor : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(width: 180)
            .glassEffect(in: Rectangle())
            
            Divider()
            
            // Detail Content
            ZStack {
                switch navState.selectedTab {
                case .dashboard:
                    DashboardView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .settings:
                    PreferencesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(in: Rectangle())
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
