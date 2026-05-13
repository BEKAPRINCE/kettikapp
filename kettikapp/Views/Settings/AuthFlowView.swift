import SwiftUI

struct AuthFlowView: View {
    
    @EnvironmentObject var vm: AuthViewModel
    @State private var showRegister = false
    
    var body: some View {
        ZStack {
            if showRegister {
                RegisterView(onOpenLogin: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegister = false
                    }
                })
                .environmentObject(vm)
                .transition(.move(edge: .trailing))
            } else {
                LoginView(onOpenRegister: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegister = true
                    }
                })
                .environmentObject(vm)
                .transition(.move(edge: .leading))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // ← добавлено
        .animation(.easeInOut(duration: 0.3), value: showRegister)
    }
}
