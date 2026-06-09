import SwiftUI

struct DriverAccessView: View {
    @EnvironmentObject var vm: AuthViewModel
    let onOpenPassengerLogin: () -> Void

    @State private var isCreatingDriver = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var inviteCode = ""
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 42)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentYellow.opacity(0.16))
                                .frame(width: 88, height: 88)
                                .overlay(Circle().stroke(Color.accentYellow.opacity(0.35), lineWidth: 1))
                            Image(systemName: "steeringwheel")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.accentYellow)
                        }

                        Text("Кабинет водителя")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)

                        Text("Доступ только для подтверждённых водителей KetTik")
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Picker("", selection: $isCreatingDriver) {
                        Text("Войти").tag(false)
                        Text("Создать").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        if isCreatingDriver {
                            authField(title: "Имя водителя", placeholder: "Бекжан", icon: "person.fill", text: $name)
                        }

                        authField(title: "Email", placeholder: "driver@email.com", icon: "envelope.fill", text: $email, keyboard: .emailAddress)

                        authField(
                            title: "Пароль",
                            placeholder: "Мин. 6 символов",
                            icon: "lock.fill",
                            text: $password,
                            isSecure: !showPassword,
                            trailingIcon: showPassword ? "eye.slash" : "eye",
                            trailingAction: { showPassword.toggle() }
                        )

                        if isCreatingDriver {
                            authField(title: "Подтвердите пароль", placeholder: "Повторите пароль", icon: "lock.rotation", text: $confirmPassword, isSecure: true)
                            authField(title: "Код допуска", placeholder: "Выдаётся администратором", icon: "key.fill", text: $inviteCode, capitalization: .characters)
                        }
                    }
                    .padding(.horizontal, 20)

                    if let error = vm.errorMessage {
                        messageRow(error, icon: "exclamationmark.circle.fill", color: .dangerRed)
                            .padding(.horizontal, 20)
                    }

                    if let message = vm.successMessage {
                        messageRow(message, icon: "checkmark.circle.fill", color: .accentGreen)
                            .padding(.horizontal, 20)
                    }

                    Button {
                        if isCreatingDriver {
                            vm.registerDriver(
                                name: name,
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword,
                                inviteCode: inviteCode
                            )
                        } else {
                            vm.loginDriver(email: email, password: password)
                        }
                    } label: {
                        ZStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isCreatingDriver ? "Создать аккаунт водителя" : "Войти как водитель")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(isActionDisabled ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isActionDisabled || vm.isLoading)

                    Button(action: onOpenPassengerLogin) {
                        Text("Вернуться к входу пассажира")
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                    }

                    Text("Временный код допуска для теста: KETTIK-43-DRIVER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 430)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var isActionDisabled: Bool {
        if isCreatingDriver {
            return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            password.count < 6 ||
            confirmPassword.count < 6 ||
            inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.count < 6
    }

    private func messageRow(_ text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.appCaption)
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func authField(
        title: String,
        placeholder: String,
        icon: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .never,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaption)
                .foregroundColor(.textMuted)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.textMuted)
                    .frame(width: 20)
                if isSecure {
                    SecureField(placeholder, text: text)
                        .foregroundColor(.textPrimary)
                        .textFieldStyle(.plain)
                } else {
                    TextField(placeholder, text: text)
                        .foregroundColor(.textPrimary)
                        .textFieldStyle(.plain)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(capitalization)
                        .autocorrectionDisabled()
                }
                if let trailingIcon, let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

#Preview {
    DriverAccessView(onOpenPassengerLogin: {})
        .environmentObject(AuthViewModel())
}
