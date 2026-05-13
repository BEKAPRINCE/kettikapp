import SwiftUI

@main
struct KetTikApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showSplash = true

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
