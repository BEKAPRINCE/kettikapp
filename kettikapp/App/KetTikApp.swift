import SwiftUI
import Combine

@main
struct KetTikApp: App {

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showSplash = true

    init() {
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                    .transition(.opacity)
                } else {
                    if authViewModel.isAuthenticated {
                        MainTabView()
                            .environmentObject(authViewModel)
                            .environmentObject(settingsViewModel)
                            .onReceive(authViewModel.$currentUserProfile.compactMap { $0 }) { profile in
                                settingsViewModel.profile = profile
                            }
                            .onReceive(authViewModel.$currentUserProfile.filter { $0 == nil }) { _ in
                                settingsViewModel.profile = UserProfile(fullName: "Пользователь", email: "", phone: "")
                            }
                    } else {
                        AuthFlowView()
                            .environmentObject(authViewModel)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .preferredColorScheme(settingsViewModel.darkTheme ? .dark : .light)
        }
    }
}
