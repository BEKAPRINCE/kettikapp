import Foundation
import Combine
import SwiftUI

// MARK: - Settings ViewModel
final class SettingsViewModel: ObservableObject {
    private enum Keys {
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let locationEnabled = "settings.locationEnabled"
        static let darkTheme = "settings.darkTheme"
        static let mapAnimations = "settings.mapAnimations"
        static let soundAlerts = "settings.soundAlerts"
        static let autoRefresh = "settings.autoRefresh"
    }
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Profile
    @Published var profile = UserProfile(
        fullName: "Бекжан Атабаев",
        email:    "Бекжан@example.com",
        phone:    "+996 700 123 456"
    )
    
    // MARK: - Bank Cards
    @Published var cards: [BankCard] = [
        BankCard(id: UUID(), last4: "4242", cardType: .visa, holderName: "ALIBEK DUISHENOV", expiry: "12/28", cvv: "")
    ]
    
    // MARK: - App Settings
    @Published var notificationsEnabled = true {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    @Published var locationEnabled = true {
        didSet { defaults.set(locationEnabled, forKey: Keys.locationEnabled) }
    }
    @Published var darkTheme = true {
        didSet { defaults.set(darkTheme, forKey: Keys.darkTheme) }
    }
    @Published var mapAnimations = true {
        didSet { defaults.set(mapAnimations, forKey: Keys.mapAnimations) }
    }
    @Published var soundAlerts = false {
        didSet { defaults.set(soundAlerts, forKey: Keys.soundAlerts) }
    }
    @Published var autoRefresh = true {
        didSet { defaults.set(autoRefresh, forKey: Keys.autoRefresh) }
    }
    
    // MARK: - UI State
    @Published var toastMessage: String?
    @Published var showDeleteConfirm    = false
    
    init() {
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        locationEnabled = defaults.object(forKey: Keys.locationEnabled) as? Bool ?? true
        darkTheme = defaults.object(forKey: Keys.darkTheme) as? Bool ?? true
        mapAnimations = defaults.object(forKey: Keys.mapAnimations) as? Bool ?? true
        soundAlerts = defaults.object(forKey: Keys.soundAlerts) as? Bool ?? false
        autoRefresh = defaults.object(forKey: Keys.autoRefresh) as? Bool ?? true
    }
    
    // MARK: - Profile Actions
    func saveProfile(_ updated: UserProfile) {
        profile = updated
        showToast("Профиль обновлён ✓")
    }
    
    // MARK: - Card Actions
    func addCard(_ card: BankCard) {
        cards.append(card)
        showToast("Карта привязана ✓")
    }
    
    func updateCard(_ card: BankCard) {
        if let i = cards.firstIndex(where: { $0.id == card.id }) {
            cards[i] = card
            showToast("Карта обновлена ✓")
        }
    }
    
    func removeCard(id: UUID) {
        cards.removeAll { $0.id == id }
        showToast("Карта удалена")
    }
    
    // MARK: - Account Actions
    func deleteAccount() {
        showToast("Запрос на удаление отправлен")
        showDeleteConfirm = false
    }
    
    // MARK: - Toast
    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.toastMessage = nil
        }
    }
    
    var appSettingsItems: [(label: String, key: ReferenceWritableKeyPath<SettingsViewModel, Bool>)] {
        [
            ("Уведомления о прибытии",   \.notificationsEnabled),
            ("Геолокация",               \.locationEnabled),
            ("Тёмная тема",              \.darkTheme),
            ("Анимации на карте",        \.mapAnimations),
            ("Звуковые сигналы",         \.soundAlerts),
            ("Автообновление маршрутов", \.autoRefresh),
        ]
    }
}
