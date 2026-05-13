import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var vm: AuthViewModel
    let onOpenRegister: () -> Void
    
    @State private var email    = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    enum Field { case email, password }
    
    var isCompact: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            Circle()
                .fill(RadialGradient(
                    colors: [Color.accentTeal.opacity(0.25), Color.clear],
                    center: .center, startRadius: 0, endRadius: 300
                ))
                .frame(width: 600)
                .offset(x: 100, y: -300)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: isCompact ? 28 : 72)
                    
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.accentTeal.opacity(0.15))
                                .frame(width: isCompact ? 74 : 90, height: isCompact ? 74 : 90)
                                .overlay(Circle().stroke(Color.accentTeal.opacity(0.3), lineWidth: 1))
                            Image(systemName: "bus.fill")
                                .font(.system(size: isCompact ? 30 : 36))
                                .foregroundColor(.accentTeal)
                        }
                        Text("Kettik")
                            .font(.system(size: isCompact ? 26 : 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Общественный транспорт")
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, isCompact ? 28 : 48)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.appCaption)
                                .foregroundColor(.textMuted)
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(focusedField == .email ? .accentTeal : .textMuted)
                                    .font(.system(size: 15))
                                TextField("your@email.com", text: $email)
                                    .foregroundColor(.textPrimary)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .email)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(focusedField == .email ? Color.accentTeal.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(.appCaption)
                                .foregroundColor(.textMuted)
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(focusedField == .password ? .accentTeal : .textMuted)
                                    .font(.system(size: 15))
                                if showPassword {
                                    TextField("Мин. 6 символов", text: $password)
                                        .foregroundColor(.textPrimary)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("Мин. 6 символов", text: $password)
                                        .foregroundColor(.textPrimary)
                                        .focused($focusedField, equals: .password)
                                }
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.textMuted)
                                        .font(.system(size: 15))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(focusedField == .password ? Color.accentTeal.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        if let error = vm.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.dangerRed)
                                Text(error)
                                    .font(.appCaption)
                                    .foregroundColor(.dangerRed)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button {
                            focusedField = nil
                            vm.login(email: email, password: password)
                        } label: {
                            ZStack {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Войти")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .accentTeal.opacity(0.35), radius: 12, y: 5)
                            .opacity(email.isEmpty || password.count < 6 ? 0.5 : 1)
                        }
                        .disabled(email.isEmpty || password.count < 6 || vm.isLoading)
                        
                        Button { vm.isAuthenticated = true } label: {
                            Text("Войти без регистрации (демо)")
                                .font(.appCaption)
                                .foregroundColor(.textMuted)
                                .underline()
                        }
                        
                        Button(action: onOpenRegister) {
                            Text("Нет аккаунта? Зарегистрироваться")
                                .font(.appCaption)
                                .foregroundColor(.accentTeal)
                        }
                        
                        Spacer(minLength: isCompact ? 24 : 52)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
}

#Preview {
    LoginView(onOpenRegister: {})
        .environmentObject(AuthViewModel())
}
