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
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(Color.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.cardBorder.opacity(0.8)),
                    alignment: .top
                )
        )
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
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .accentTeal : .textMuted)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .accentTeal : .textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentTeal.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
        .environmentObject(SettingsViewModel())
}
