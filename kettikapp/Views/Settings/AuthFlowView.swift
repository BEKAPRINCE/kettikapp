import SwiftUI

struct AuthFlowView: View {
    
    @EnvironmentObject var vm: AuthViewModel
    @State private var mode: AuthMode = .login

    private enum AuthMode {
        case login
        case register
        case driver
    }
    
    var body: some View {
        ZStack {
            switch mode {
            case .login:
                LoginView(
                    onOpenRegister: {
                        withAnimation(.easeInOut(duration: 0.3)) { mode = .register }
                    },
                    onOpenDriverAccess: {
                        withAnimation(.easeInOut(duration: 0.3)) { mode = .driver }
                    }
                )
                .environmentObject(vm)
                .transition(.move(edge: .leading))
            case .register:
                RegisterView(onOpenLogin: {
                    withAnimation(.easeInOut(duration: 0.3)) { mode = .login }
                })
                .environmentObject(vm)
                .transition(.move(edge: .trailing))
            case .driver:
                DriverAccessView(onOpenPassengerLogin: {
                    withAnimation(.easeInOut(duration: 0.3)) { mode = .login }
                })
                .environmentObject(vm)
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: mode)
    }
}
