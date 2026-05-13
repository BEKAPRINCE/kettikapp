import SwiftUI

// MARK: - App Settings View
struct AppSettingsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            List {
                Section {
                    ToggleRow(icon: "bell.badge.fill",    label: "Уведомления о прибытии", color: .accentOrange,  value: $vm.notificationsEnabled)
                    ToggleRow(icon: "location.fill",      label: "Геолокация",              color: .accentTeal,    value: $vm.locationEnabled)
                    ToggleRow(icon: "moon.fill",          label: "Тёмная тема",             color: Color.purple,   value: $vm.darkTheme)
                    ToggleRow(icon: "sparkles",           label: "Анимации на карте",        color: .accentYellow,  value: $vm.mapAnimations)
                    ToggleRow(icon: "speaker.wave.3.fill",label: "Звуковые сигналы",         color: .accentGreen,   value: $vm.soundAlerts)
                    ToggleRow(icon: "arrow.clockwise",    label: "Автообновление маршрутов", color: .accentTeal,    value: $vm.autoRefresh)
                } header: {
                    Text("Общие настройки")
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
                
                Section {
                    InfoRow(icon: "clock.fill",   label: "Интервал обновления", value: vm.autoRefresh ? "3 сек" : "Отключено", color: .accentTeal)
                    InfoRow(icon: "map.fill",     label: "Тип карты",           value: "Стандарт", color: .accentGreen)
                    InfoRow(icon: "globe",        label: "Язык приложения",     value: "Русский", color: .accentOrange)
                    InfoRow(icon: "circle.lefthalf.filled", label: "Текущая тема", value: vm.darkTheme ? "Тёмная" : "Светлая", color: .purple)
                } header: {
                    Text("Дополнительно")
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
                
                Section {
                    HStack {
                        Text("Версия приложения")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("2.1.0 (48)")
                            .foregroundColor(.textMuted)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("О приложении")
                        .font(.appLabel)
                        .foregroundColor(.textMuted)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Настройки")
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
