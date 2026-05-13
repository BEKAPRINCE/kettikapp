import SwiftUI
import MapKit

// MARK: - Map View
struct MapView: View {
    
    @EnvironmentObject var vm: MapViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showFavoritesSheet = false
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // MARK: - Map
            Map(position: mapPosition) {
                if vm.showUserLocation {
                    UserAnnotation()
                }

                ForEach(vm.routes) { route in
                    Annotation("", coordinate: route.coordinate, anchor: .bottom) {
                    RouteMapAnnotation(route: route, isSelected: vm.selectedRoute?.id == route.id)
                        .onTapGesture { vm.selectRoute(route) }
                    }
                }
            }
            .ignoresSafeArea()
            
            // MARK: - Top Header
            VStack(spacing: 0) {
                MapHeaderView(favoriteCount: vm.favoriteRoutes.count) {
                    showFavoritesSheet = true
                }
                Spacer()
            }
            
            // MARK: - Right Controls
            VStack(spacing: 12) {
                MapControlButton(icon: "location.fill") {
                    vm.centerOnUser()
                }
                MapControlButton(icon: "minus.magnifyingglass") {
                    vm.region.span.latitudeDelta *= 1.5
                    vm.region.span.longitudeDelta *= 1.5
                }
                MapControlButton(icon: "plus.magnifyingglass") {
                    vm.region.span.latitudeDelta /= 1.5
                    vm.region.span.longitudeDelta /= 1.5
                }
            }
            .padding(.top, 130)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // MARK: - Bottom selected route card
            if let route = vm.selectedRoute {
                VStack {
                    Spacer()
                    SelectedRouteCard(route: route,
                                      isFavorite: vm.favoriteIDs.contains(route.id)) {
                        vm.toggleFavorite(routeID: route.id)
                    } onDismiss: {
                        vm.selectRoute(nil)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // MARK: - Favorites strip (when no route selected)
            if vm.selectedRoute == nil && !vm.favoriteRoutes.isEmpty {
                VStack {
                    Spacer()
                    FavoritesStrip(routes: vm.favoriteRoutes) { route in
                        vm.selectRoute(route)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .animation(settingsVM.mapAnimations ? .spring(response: 0.35, dampingFraction: 0.8) : nil, value: vm.selectedRoute?.id)
        .onAppear {
            vm.setLocationEnabled(settingsVM.locationEnabled)
            vm.setAutoRefresh(enabled: settingsVM.autoRefresh)
        }
        .onChange(of: settingsVM.locationEnabled) { _, enabled in
            vm.setLocationEnabled(enabled)
        }
        .onChange(of: settingsVM.autoRefresh) { _, enabled in
            vm.setAutoRefresh(enabled: enabled)
        }
        .sheet(isPresented: $showFavoritesSheet) {
            FavoritesSheetView(routes: vm.favoriteRoutes) { route in
                vm.selectRoute(route)
                showFavoritesSheet = false
            }
        }
    }

    private var mapPosition: Binding<MapCameraPosition> {
        Binding {
            .region(vm.region)
        } set: { newPosition in
            if let region = newPosition.region {
                vm.region = region
            }
        }
    }
}

// MARK: - Map Header
struct MapHeaderView: View {
    let favoriteCount: Int
    let onFavoritesTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("KetTik")
                    .font(.appHeadline)
                    .foregroundColor(.textPrimary)
                Text("8 маршрутов онлайн")
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Button(action: onFavoritesTap) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.accentYellow)
                    Text("\(favoriteCount)")
                        .font(.appCaption)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.cardBackground.opacity(0.9))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.accentYellow.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.appBackground, Color.clear],
                startPoint: .top,
                endPoint: .bottom
            ).opacity(0.95)
        )
    }
}

// MARK: - Map Control Button
struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(width: 42, height: 42)
                .background(Color.cardBackground.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        }
    }
}

// MARK: - Route Map Annotation
struct RouteMapAnnotation: View {
    let route: Route
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(route.emoji)
                    .font(.system(size: 12))
                Text(route.number)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(route.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .shadow(color: route.color.opacity(0.5), radius: 6)
            
            // Pin dot
            Circle()
                .fill(route.color)
                .frame(width: 6, height: 6)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Selected Route Card
struct SelectedRouteCard: View {
    let route: Route
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    Text(route.emoji)
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(route.number)
                            .font(.appHeadline)
                            .foregroundColor(.textPrimary)
                        Text(route.type.displayName)
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(route.etaText)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(route.color)
                    Text("до прибытия")
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                }
            }
            
            Divider().background(Color.cardBorder)
            
            // Action buttons
            HStack(spacing: 10) {
                // Stops info
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(route.color)
                    Text("\(route.totalStops) остановок")
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appBackground.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Favorite button
                Button(action: onFavorite) {
                    HStack(spacing: 6) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .accentYellow : .textSecondary)
                        Text(isFavorite ? "В избранном" : "Избранное")
                            .font(.appCaption)
                            .foregroundColor(isFavorite ? .accentYellow : .textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        (isFavorite ? Color.accentYellow : Color.appBackground)
                            .opacity(isFavorite ? 0.16 : 0.75)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Dismiss
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.appBackground.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(route.color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Favorites Strip
struct FavoritesStrip: View {
    let routes: [Route]
    let onTap: (Route) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Избранные")
                .font(.appLabel)
                .foregroundColor(.textMuted)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(routes) { route in
                        Button { onTap(route) } label: {
                            HStack(spacing: 8) {
                                Text(route.emoji).font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(route.number)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                    Text(route.etaText)
                                        .font(.appCaption)
                                        .foregroundColor(route.color)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.cardBackground.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(route.color.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.appBackground.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Favorites Sheet
struct FavoritesSheetView: View {
    let routes: [Route]
    let onSelect: (Route) -> Void
    
    var body: some View {
        NavigationView {
            List(routes) { route in
                Button { onSelect(route) } label: {
                    HStack(spacing: 14) {
                        Text(route.emoji).font(.system(size: 28))
                        VStack(alignment: .leading) {
                            Text(route.number).font(.appBody).foregroundColor(.textPrimary)
                            Text(route.type.displayName).font(.appCaption).foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Text(route.etaText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(route.color)
                    }
                }
                .listRowBackground(Color.cardBackground)
            }
            .navigationTitle("Избранные маршруты")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.appBackground)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(MapViewModel())
        .environmentObject(SettingsViewModel())
}
