import SwiftUI

struct RegisterView: View {

    @EnvironmentObject var vm: AuthViewModel
    let onOpenLogin: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password, confirmPassword }

    var body: some View {
        GeometryReader { geo in
            let isCompactHeight = geo.size.height < 760
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer(minLength: isCompactHeight ? 28 : 60)

                        Text("Регистрация")
                            .font(.system(size: isCompactHeight ? 26 : 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)

                        VStack(spacing: 12) {
                            inputField(
                                title: "Имя",
                                placeholder: "Ваше имя",
                                icon: "person.fill",
                                text: $name,
                                field: .name
                            )

                            inputField(
                                title: "Email",
                                placeholder: "your@email.com",
                                icon: "envelope.fill",
                                text: $email,
                                field: .email
                            )

                            secureInputField(
                                title: "Пароль",
                                placeholder: "Мин. 6 символов",
                                isSecure: !showPassword,
                                icon: "lock.fill",
                                text: $password,
                                field: .password,
                                toggleAction: { showPassword.toggle() },
                                toggleIcon: showPassword ? "eye.slash" : "eye"
                            )

                            secureInputField(
                                title: "Подтвердите пароль",
                                placeholder: "Повторите пароль",
                                isSecure: !showConfirmPassword,
                                icon: "lock.rotation",
                                text: $confirmPassword,
                                field: .confirmPassword,
                                toggleAction: { showConfirmPassword.toggle() },
                                toggleIcon: showConfirmPassword ? "eye.slash" : "eye"
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
                            vm.register(
                                name: name,
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                        } label: {
                            ZStack {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Создать аккаунт")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(isFormInvalid ? 0.5 : 1)
                        }
                        .disabled(isFormInvalid || vm.isLoading)

                        Button(action: onOpenLogin) {
                            Text("Уже есть аккаунт? Войти")
                                .font(.appCaption)
                                .foregroundColor(.accentTeal)
                        }

                        Spacer(minLength: isCompactHeight ? 24 : 40)
                    }
                    .frame(maxWidth: 420)
                    .padding(.horizontal, 20)
                }
                .frame(minHeight: geo.size.height, alignment: .top)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private var isFormInvalid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        email.isEmpty ||
        password.count < 6 ||
        confirmPassword.count < 6
    }

    @ViewBuilder
    private func inputField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaption)
                .foregroundColor(.textMuted)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(focusedField == field ? .accentTeal : .textMuted)
                TextField(placeholder, text: text)
                    .foregroundColor(.textPrimary)
                    .keyboardType(field == .email ? .emailAddress : .default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(field == .email ? .never : .words)
                    .focused($focusedField, equals: field)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(focusedField == field ? Color.accentTeal.opacity(0.5) : Color.cardBorder, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func secureInputField(
        title: String,
        placeholder: String,
        isSecure: Bool,
        icon: String,
        text: Binding<String>,
        field: Field,
        toggleAction: @escaping () -> Void,
        toggleIcon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaption)
                .foregroundColor(.textMuted)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(focusedField == field ? .accentTeal : .textMuted)
                if isSecure {
                    SecureField(placeholder, text: text)
                        .foregroundColor(.textPrimary)
                        .focused($focusedField, equals: field)
                } else {
                    TextField(placeholder, text: text)
                        .foregroundColor(.textPrimary)
                        .focused($focusedField, equals: field)
                }
                Button(action: toggleAction) {
                    Image(systemName: toggleIcon)
                        .foregroundColor(.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(focusedField == field ? Color.accentTeal.opacity(0.5) : Color.cardBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    RegisterView(onOpenLogin: {})
        .environmentObject(AuthViewModel())
}
