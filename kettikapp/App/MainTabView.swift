import SwiftUI

struct MainTabView: View {
    
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var ticketViewModel = TicketViewModel()
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedTab: Tab = .map
    
    enum Tab {
        case map, search, ticket, settings
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // MARK: - Content
            ZStack {
                switch selectedTab {
                case .map:
                    MapView()
                        .environmentObject(mapViewModel)
                        .environmentObject(settingsViewModel)
                case .search:
                    SearchView()
                        .environmentObject(searchViewModel)
                        .environmentObject(mapViewModel)
                        .environmentObject(settingsViewModel)
                case .ticket:
                    TicketView()
                        .environmentObject(ticketViewModel)
                        .environmentObject(settingsViewModel)
                case .settings:
                    SettingsView()
                        .environmentObject(settingsViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.appBackground)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "map.fill",        label: "Карта",    tab: .map,      selectedTab: $selectedTab)
            TabBarButton(icon: "magnifyingglass", label: "Поиск",    tab: .search,   selectedTab: $selectedTab)
            TabBarButton(icon: "qrcode",          label: "Билет",    tab: .ticket,   selectedTab: $selectedTab)
            TabBarButton(icon: "person.fill",     label: "Профиль",  tab: .settings, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.cardBackground.opacity(0.52))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.cardBorder.opacity(0.7),
                                    Color.accentTeal.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    
    let icon: String
    let label: String
    let tab: MainTabView.Tab
    @Binding var selectedTab: MainTabView.Tab
    
    private var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .accentTeal : .textMuted)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .accentTeal : .textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.accentTeal.opacity(0.18) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
        .environmentObject(SettingsViewModel())
}
