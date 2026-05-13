import Foundation
import Combine

// MARK: - Auth ViewModel
final class AuthViewModel: ObservableObject {

    private enum Keys {
        static let isAuthenticated = "auth.isAuthenticated"
    }

    @Published var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: Keys.isAuthenticated)
        }
    }
    @Published var isLoading: Bool  = false
    @Published var errorMessage: String?

    init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: Keys.isAuthenticated)
    }

    // MARK: - Login
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isLoading = false
            if email.contains("@") && password.count >= 6 {
                self?.isAuthenticated = true
            } else {
                self?.errorMessage = "Неверный email или пароль"
            }
        }
    }

    // MARK: - Register
    func register(name: String, email: String, password: String, confirmPassword: String) {
        isLoading = true
        errorMessage = nil

        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isLoading = false
            errorMessage = "Введите имя"
            return
        }

        guard email.contains("@") else {
            isLoading = false
            errorMessage = "Введите корректный email"
            return
        }

        guard password.count >= 6 else {
            isLoading = false
            errorMessage = "Пароль должен быть не короче 6 символов"
            return
        }

        guard password == confirmPassword else {
            isLoading = false
            errorMessage = "Пароли не совпадают"
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isLoading = false
            self?.isAuthenticated = true
        }
    }

    // MARK: - Logout
    func logout() {
        isAuthenticated = false
        errorMessage = nil
    }

    // MARK: - Delete Account
    func deleteAccount() {
        isAuthenticated = false
        errorMessage = nil
    }
}
