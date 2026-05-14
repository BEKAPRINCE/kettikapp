import SwiftUI
import StoreKit

// MARK: - Settings View
struct SettingsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.requestReview) private var requestReview
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        
                        // Profile header card
                        NavigationLink(destination: EditProfileView().environmentObject(vm)) {
                            ProfileHeaderCard(profile: vm.profile)
                        }
                        .padding(.horizontal, 20)
                        
                        // Settings groups
                        SettingsGroupView(title: "Аккаунт") {
                            NavigationLink(destination: EditProfileView().environmentObject(vm)) {
                                SettingsRow(icon: "pencil.circle.fill", label: "Редактировать профиль", color: .accentTeal)
                            }
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            NavigationLink(destination: BankCardsView().environmentObject(vm)) {
                                SettingsRow(icon: "creditcard.fill", label: "Банковские карты",
                                            subtitle: "\(vm.cards.count) карт", color: .accentYellow)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        SettingsGroupView(title: "Приложение") {
                            NavigationLink(destination: AppSettingsView().environmentObject(vm)) {
                                SettingsRow(icon: "gear", label: "Настройки приложения", color: .accentGreen)
                            }
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            SettingsRow(icon: "bell.fill", label: "Уведомления",
                                        subtitle: vm.notificationsEnabled ? "Включены" : "Выключены",
                                        color: .accentOrange)
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            SettingsRow(icon: "globe", label: "Язык", subtitle: "Русский", color: .accentTeal)
                        }
                        .padding(.horizontal, 20)
                        
                        SettingsGroupView(title: "Поддержка") {
                            NavigationLink(destination: HelpView()) {
                                SettingsRow(icon: "questionmark.circle.fill", label: "Помощь", color: .accentTeal)
                            }
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            Button {
                                requestReview()
                                vm.showToast("Спасибо за оценку!")
                            } label: {
                                SettingsRow(icon: "star.fill", label: "Оценить приложение", color: .accentYellow)
                            }
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            NavigationLink(destination: AboutAppView()) {
                                SettingsRow(icon: "info.circle.fill", label: "О приложении", subtitle: "v2.1.0", color: .accentGreen)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Danger zone
                        DangerZoneView(showConfirm: $vm.showDeleteConfirm) {
                            vm.deleteAccount()
                            authVM.deleteAccount()
                        }
                        .padding(.horizontal, 20)
                        
                        // Logout
                        Button {
                            authVM.logout()
                        } label: {
                            Text("Выйти из аккаунта")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.dangerRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dangerRed.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dangerRed.opacity(0.2), lineWidth: 1))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 150)
                }
                
                // Toast overlay
                if let msg = vm.toastMessage {
                    ToastView(message: msg)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Help View
struct HelpView: View {
    private let helpItems = [
        ("location.fill", "Карта и геолокация", "Разрешите доступ к геолокации, чтобы карта центрировалась на вашем местоположении."),
        ("bus.fill", "Маршрут 43", "Автобус движется по добавленным остановкам. Нажмите на остановку, чтобы увидеть направление."),
        ("creditcard.fill", "Оплата", "Банковские карты можно добавить в разделе профиля."),
        ("person.fill.questionmark", "Аккаунт", "Вход и регистрация работают через email и пароль.")
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(helpItems, id: \.1) { item in
                        HelpInfoCard(icon: item.0, title: item.1, text: item.2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Помощь")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpInfoCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentTeal.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(.accentTeal)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(text)
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - About App View
struct AboutAppView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.accentTeal.opacity(0.16))
                        .frame(width: 86, height: 86)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.accentTeal)
                }

                VStack(spacing: 8) {
                    Text("KetTik")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("Версия 2.1.0")
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }

                VStack(spacing: 0) {
                    AboutRow(label: "Маршрут", value: "43")
                    Divider().background(Color.cardBorder).padding(.leading, 16)
                    AboutRow(label: "Город", value: "Ош")
                    Divider().background(Color.cardBorder).padding(.leading, 16)
                    AboutRow(label: "Сервис", value: "Общественный транспорт")
                }
                .cardStyle()
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 34)
        }
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.appBody)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(.appCaption)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 58, height: 58)
                    .shadow(color: .accentTeal.opacity(0.4), radius: 10)
                Text(profile.avatarInitial)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(profile.fullName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("PREMIUM")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.accentTeal)
                        .kerning(0.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentTeal.opacity(0.14))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.accentTeal.opacity(0.28), lineWidth: 1))
                }

                Text(profile.email)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .minimumScaleFactor(0.8)

                if !profile.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(profile.phone)
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .padding(18)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.accentTeal.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Settings Group
struct SettingsGroupView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.appLabel)
                .foregroundColor(.textMuted)
                .kerning(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .cardStyle()
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    let color: Color
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(color.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.appBody)
                    .foregroundColor(.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Danger Zone
struct DangerZoneView: View {
    @Binding var showConfirm: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("УДАЛЕНИЕ АККАУНТА")
                .font(.appLabel)
                .foregroundColor(.dangerRed.opacity(0.7))
                .kerning(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                if showConfirm {
                    VStack(spacing: 12) {
                        Text("Вы уверены? Все данные будут удалены безвозвратно.")
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 10) {
                            Button { showConfirm = false } label: {
                                Text("Отмена")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appBackground.opacity(0.9))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            Button(action: onDelete) {
                                Text("Удалить")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.dangerRed.opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(16)
                    .cardStyle()
                } else {
                    Button { showConfirm = true } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Удалить аккаунт")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.dangerRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dangerRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dangerRed.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.accentTeal)
                .clipShape(Capsule())
                .shadow(color: .accentTeal.opacity(0.4), radius: 12)
                .padding(.bottom, 110)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.4), value: message)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(AuthViewModel())
}
