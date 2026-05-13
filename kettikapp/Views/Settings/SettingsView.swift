import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
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
                            SettingsRow(icon: "questionmark.circle.fill", label: "Помощь", color: .accentTeal)
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            Button { vm.showToast("Спасибо за оценку! ❤️") } label: {
                                SettingsRow(icon: "star.fill", label: "Оценить приложение", color: .accentYellow)
                            }
                            Divider().background(Color.cardBorder).padding(.leading, 56)
                            SettingsRow(icon: "info.circle.fill", label: "О приложении", subtitle: "v2.1.0", color: .accentGreen)
                        }
                        .padding(.horizontal, 20)
                        
                        // Danger zone
                        DangerZoneView(showConfirm: $vm.showDeleteConfirm) {
                            vm.deleteAccount()
                            authVM.logout()
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
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
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

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                    .shadow(color: .accentTeal.opacity(0.4), radius: 10)
                Text(profile.avatarInitial)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.fullName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(profile.email)
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
                Text(profile.phone)
                    .font(.appCaption)
                    .foregroundColor(.textMuted)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("PREMIUM")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.accentTeal)
                    .kerning(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentTeal.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.accentTeal.opacity(0.3), lineWidth: 1))
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .padding(.top, 6)
            }
        }
        .padding(20)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
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
        .padding(.vertical, 14)
    }
}

// MARK: - Danger Zone
struct DangerZoneView: View {
    @Binding var showConfirm: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ОПАСНАЯ ЗОНА")
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
