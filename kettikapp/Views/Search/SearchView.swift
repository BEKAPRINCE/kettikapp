import SwiftUI

// MARK: - Search View
struct SearchView: View {
    
    @EnvironmentObject var vm: SearchViewModel
    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            VStack(spacing: 16) {
                HStack {
                    Text(settingsVM.text("Поиск", "Search"))
                        .font(.appTitle)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if vm.hasActiveFilters {
                        Button(settingsVM.text("Сбросить", "Reset")) { vm.clearSearch() }
                            .font(.appCaption)
                            .foregroundColor(.accentTeal)
                    }
                }
                
                // Search bar
                SearchBar(
                    query: $vm.searchQuery,
                    placeholder: settingsVM.text("Маршрут, номер, тип...", "Route, number, type..."),
                    isFocused: $searchFocused
                )
                
                // Type filters
                TypeFilterRow(selectedFilter: vm.selectedFilter) { type in
                    vm.setFilter(type)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.appBackground)
            
            // MARK: - Results
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    
                    // Favorites section (when no search)
                    if !vm.hasActiveFilters {
                        let favRoutes = mapVM.favoriteRoutes
                        if !favRoutes.isEmpty {
                            SectionHeader(title: settingsVM.text("★  Избранные", "★  Favorites"), count: favRoutes.count)
                            ForEach(favRoutes) { route in
                                RouteRowView(
                                    route: route,
                                    isFavorite: true,
                                    onFavorite: { mapVM.toggleFavorite(routeID: route.id) }
                                )
                                Divider().background(Color.cardBorder).padding(.leading, 74)
                            }
                        }
                        
                        SectionHeader(title: settingsVM.text("Все маршруты", "All routes"), count: vm.filteredRoutes.count)
                    } else {
                        SectionHeader(
                            title: vm.filteredRoutes.isEmpty ? settingsVM.text("Ничего не найдено", "Nothing found") : settingsVM.text("Результаты", "Results"),
                            count: vm.filteredRoutes.count
                        )
                    }
                    
                    if vm.filteredRoutes.isEmpty && vm.hasActiveFilters {
                        EmptySearchView(query: vm.searchQuery)
                            .environmentObject(settingsVM)
                    } else {
                        ForEach(vm.filteredRoutes) { route in
                            RouteRowView(
                                route: route,
                                isFavorite: mapVM.favoriteIDs.contains(route.id),
                                onFavorite: { mapVM.toggleFavorite(routeID: route.id) }
                            )
                            if route.id != vm.filteredRoutes.last?.id {
                                Divider().background(Color.cardBorder).padding(.leading, 74)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.appBackground)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var query: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(query.isEmpty ? .textMuted : .accentTeal)
                .font(.system(size: 17, weight: .semibold))
            
            TextField(placeholder, text: $query)
                .foregroundColor(.textPrimary)
                .font(.appBody)
                .focused(isFocused)
                .submitLabel(.search)
            
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                        .font(.system(size: 17))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused.wrappedValue ? Color.accentTeal.opacity(0.4) : Color.cardBorder, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
    }
}

// MARK: - Type Filter Row
struct TypeFilterRow: View {
    let selectedFilter: TransportType?
    let onSelect: (TransportType?) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                FilterChip(label: "Все", isSelected: selectedFilter == nil) {
                    onSelect(nil)
                }
                ForEach(TransportType.allCases) { type in
                    FilterChip(
                        icon: type.emoji,
                        label: type.displayName,
                        isSelected: selectedFilter == type,
                        color: type.color
                    ) {
                        onSelect(type)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    var icon: String? = nil
    let label: String
    let isSelected: Bool
    var color: Color = .accentTeal
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Text(icon).font(.system(size: 13)) }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? color : Color.cardBorder, lineWidth: 1))
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appLabel)
                .foregroundColor(.textMuted)
                .kerning(0.8)
            Spacer()
            Text("\(count)")
                .font(.appLabel)
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - Route Row View
struct RouteRowView: View {
    let route: Route
    let isFavorite: Bool
    let onFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(route.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(route.color.opacity(0.3), lineWidth: 1)
                    )
                Text(route.emoji)
                    .font(.system(size: 24))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(route.number)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("\(route.type.displayName) · \(route.totalStops) остановок")
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // ETA
            VStack(alignment: .trailing, spacing: 2) {
                Text(route.etaText)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(route.color)
                Text("до прибытия")
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }
            
            // Favorite button
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundColor(isFavorite ? .accentYellow : Color.textMuted)
                    .scaleEffect(isFavorite ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isFavorite)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appBackground)
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let query: String
    
    var body: some View {
        VStack(spacing: 14) {
            Text("🔍")
                .font(.system(size: 48))
            Text(settingsVM.text("«\(query)» не найден", "\"\(query)\" not found"))
                .font(.appHeadline)
                .foregroundColor(.textSecondary)
            Text(settingsVM.text("Попробуйте другой номер или тип", "Try another number or type"))
                .font(.appCaption)
                .foregroundColor(.textMuted)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SearchView()
        .environmentObject(SearchViewModel())
        .environmentObject(MapViewModel())
        .environmentObject(SettingsViewModel())
}
