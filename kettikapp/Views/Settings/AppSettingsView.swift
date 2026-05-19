import SwiftUI

// MARK: - App Settings View
struct AppSettingsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            List {
                Section {
                    ToggleRow(icon: "bell.badge.fill",    label: vm.text("Уведомления о прибытии", "Arrival notifications"), color: .accentOrange,  value: $vm.notificationsEnabled)
                    ToggleRow(icon: "location.fill",      label: vm.text("Геолокация", "Location"),                           color: .accentTeal,    value: $vm.locationEnabled)
                    ToggleRow(icon: "moon.fill",          label: vm.text("Тёмная тема", "Dark theme"),                         color: Color.purple,   value: $vm.darkTheme)
                    ToggleRow(icon: "sparkles",           label: vm.text("Анимации на карте", "Map animations"),               color: .accentYellow,  value: $vm.mapAnimations)
                    ToggleRow(icon: "speaker.wave.3.fill",label: vm.text("Звуковые сигналы", "Sound alerts"),                  color: .accentGreen,   value: $vm.soundAlerts)
                    ToggleRow(icon: "arrow.clockwise",    label: vm.text("Автообновление маршрутов", "Route auto refresh"),    color: .accentTeal,    value: $vm.autoRefresh)
                } header: {
                    Text(vm.text("Общие настройки", "General settings"))
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
                
                Section {
                    InfoRow(icon: "clock.fill", label: vm.text("Интервал обновления", "Refresh interval"), value: vm.autoRefresh ? vm.text("3 сек", "3 sec") : vm.text("Отключено", "Off"), color: .accentTeal)
                    InfoRow(icon: "map.fill", label: vm.text("Тип карты", "Map type"), value: vm.text("Стандарт", "Standard"), color: .accentGreen)
                    LanguageRow(label: vm.text("Язык приложения", "App language"), language: $vm.language)
                    InfoRow(icon: "circle.lefthalf.filled", label: vm.text("Текущая тема", "Current theme"), value: vm.darkTheme ? vm.text("Тёмная", "Dark") : vm.text("Светлая", "Light"), color: .purple)
                } header: {
                    Text(vm.text("Дополнительно", "Additional"))
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
                
                Section {
                    HStack {
                        Text(vm.text("Версия приложения", "App version"))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("2.1.0 (48)")
                            .foregroundColor(.textMuted)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text(vm.text("О приложении", "About"))
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(vm.text("Настройки", "Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var value: Bool
    
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
            Text(label)
                .font(.appBody)
                .foregroundColor(.textPrimary)
            Spacer()
            Toggle("", isOn: $value)
                .tint(.accentTeal)
                .labelsHidden()
        }
        .listRowBackground(Color.cardBackground)
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let label: String
    @Binding var language: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.accentOrange.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentOrange)
            }

            Text(label)
                .font(.appBody)
                .foregroundColor(.textPrimary)

            Spacer()

            Menu {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        language = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if option == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(language.title)
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.cardBackground)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
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
            Text(label)
                .font(.appBody)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .font(.appCaption)
                .foregroundColor(.textMuted)
        }
        .listRowBackground(Color.cardBackground)
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
            .environmentObject(SettingsViewModel())
    }
}
