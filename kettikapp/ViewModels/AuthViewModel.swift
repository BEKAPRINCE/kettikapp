import Foundation
import Combine

// MARK: - Firebase REST Service
final class FirebaseAuthRESTService {
    static let shared = FirebaseAuthRESTService()

    private enum SessionKeys {
        static let idToken = "firebase.session.idToken"
        static let refreshToken = "firebase.session.refreshToken"
        static let localId = "firebase.session.localId"
        static let email = "firebase.session.email"
        static let fullName = "firebase.session.fullName"
        static let phone = "firebase.session.phone"
    }

    private let defaults = UserDefaults.standard
    private let session = URLSession.shared

    private var config: FirebaseRESTConfig? {
        FirebaseRESTConfig.load()
    }

    var currentLocalId: String? {
        defaults.string(forKey: SessionKeys.localId)
    }

    var currentEmail: String? {
        defaults.string(forKey: SessionKeys.email)
    }

    var hasSession: Bool {
        defaults.string(forKey: SessionKeys.idToken) != nil &&
        defaults.string(forKey: SessionKeys.localId) != nil
    }

    private var currentIdToken: String? {
        defaults.string(forKey: SessionKeys.idToken)
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        let response: AuthResponse = try await authRequest(
            endpoint: "accounts:signInWithPassword",
            body: [
                "email": email,
                "password": password,
                "returnSecureToken": true
            ]
        )
        saveSession(response)
        return await fetchProfileOrFallback(
            localId: response.localId,
            idToken: response.idToken,
            fallbackEmail: response.email
        )
    }

    func register(name: String, email: String, password: String) async throws -> UserProfile {
        let response: AuthResponse = try await authRequest(
            endpoint: "accounts:signUp",
            body: [
                "email": email,
                "password": password,
                "returnSecureToken": true
            ]
        )
        saveSession(response)

        let profile = UserProfile(fullName: name, email: response.email, phone: "")
        cacheProfile(profile)
        try? await saveProfile(profile, localId: response.localId, idToken: response.idToken)
        return profile
    }

    func sendPasswordReset(email: String) async throws {
        let _: EmptyAuthResponse = try await authRequest(
            endpoint: "accounts:sendOobCode",
            body: [
                "requestType": "PASSWORD_RESET",
                "email": email
            ]
        )
    }

    func restoreProfile() async throws -> UserProfile? {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = try await validIdToken()
        else {
            return nil
        }

        return await fetchProfileOrFallback(localId: localId, idToken: idToken, fallbackEmail: currentEmail ?? "")
    }

    func saveProfile(_ profile: UserProfile) {
        cacheProfile(profile)

        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = currentIdToken
        else {
            return
        }

        Task {
            let freshToken = (try? await validIdToken()) ?? idToken
            try? await saveProfile(profile, localId: localId, idToken: freshToken)
        }
    }

    func fetchBankCards() async throws -> [BankCard] {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = try await validIdToken()
        else {
            return []
        }

        return try await fetchUserDocument(localId: localId, idToken: idToken).bankCards()
    }

    func fetchSubscription() async throws -> UserSubscription {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = try await validIdToken()
        else {
            return .none
        }

        return try await fetchUserDocument(localId: localId, idToken: idToken).subscription()
    }

    func saveBankCards(_ cards: [BankCard]) {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = currentIdToken
        else {
            return
        }

        Task {
            let freshToken = (try? await validIdToken()) ?? idToken
            try? await saveBankCards(cards, localId: localId, idToken: freshToken)
        }
    }

    func saveSubscription(_ subscription: UserSubscription) {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = currentIdToken
        else {
            return
        }

        Task {
            do {
                let freshToken = (try? await validIdToken()) ?? idToken
                try await saveSubscription(subscription, localId: localId, idToken: freshToken)
            } catch {
                print("Firestore subscription sync failed: \(error.localizedDescription)")
            }
        }
    }

    func saveSubscriptionToDatabase(_ subscription: UserSubscription) async throws {
        guard
            let localId = defaults.string(forKey: SessionKeys.localId),
            let idToken = try await validIdToken()
        else {
            throw FirebaseRESTError.missingSession
        }

        try await saveSubscription(subscription, localId: localId, idToken: idToken)
    }

    func logout() {
        defaults.removeObject(forKey: SessionKeys.idToken)
        defaults.removeObject(forKey: SessionKeys.refreshToken)
        defaults.removeObject(forKey: SessionKeys.localId)
        defaults.removeObject(forKey: SessionKeys.email)
        defaults.removeObject(forKey: SessionKeys.fullName)
        defaults.removeObject(forKey: SessionKeys.phone)
        defaults.removeObject(forKey: "settings.subscription")
        defaults.removeObject(forKey: "settings.bankCards")
    }

    func deleteAccount() async throws {
        guard let idToken = try await validIdToken() else {
            logout()
            return
        }

        if let localId = defaults.string(forKey: SessionKeys.localId) {
            try? await deleteProfile(localId: localId, idToken: idToken)
        }

        let _: EmptyAuthResponse = try await authRequest(
            endpoint: "accounts:delete",
            body: ["idToken": idToken]
        )
        logout()
    }

    private func validIdToken() async throws -> String? {
        guard hasSession else { return nil }

        if let refreshed = try? await refreshIdToken() {
            return refreshed
        }

        return currentIdToken
    }

    private func refreshIdToken() async throws -> String {
        guard let config else { throw FirebaseRESTError.missingConfiguration }
        guard let refreshToken = defaults.string(forKey: SessionKeys.refreshToken) else {
            throw FirebaseRESTError.missingSession
        }

        var components = URLComponents(string: "https://securetoken.googleapis.com/v1/token")!
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        request.httpBody = bodyComponents.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)

        let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        defaults.set(tokenResponse.idToken, forKey: SessionKeys.idToken)
        defaults.set(tokenResponse.refreshToken, forKey: SessionKeys.refreshToken)
        defaults.set(tokenResponse.localId, forKey: SessionKeys.localId)
        return tokenResponse.idToken
    }

    private func authRequest<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var components = URLComponents(string: "https://identitytoolkit.googleapis.com/v1/\(endpoint)")!
        components.queryItems = [URLQueryItem(name: "key", value: config.apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func fetchProfile(localId: String, idToken: String, fallbackEmail: String) async throws -> UserProfile {
        let document = try await fetchUserDocument(localId: localId, idToken: idToken)
        let profile = document.profile(fallbackEmail: fallbackEmail)
        cacheProfile(profile)
        return profile
    }

    private func fetchUserDocument(localId: String, idToken: String) async throws -> FirestoreDocument {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var request = URLRequest(url: firestoreDocumentURL(projectId: config.projectId, localId: localId))
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            return FirestoreDocument(fields: nil)
        }

        try validate(data: data, response: response)
        return try JSONDecoder().decode(FirestoreDocument.self, from: data)
    }

    private func fetchProfileOrFallback(localId: String, idToken: String, fallbackEmail: String) async -> UserProfile {
        if let profile = try? await fetchProfile(localId: localId, idToken: idToken, fallbackEmail: fallbackEmail) {
            return profile
        }

        return cachedProfile(fallbackEmail: fallbackEmail)
    }

    private func saveProfile(_ profile: UserProfile, localId: String, idToken: String) async throws {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var components = URLComponents(url: firestoreDocumentURL(projectId: config.projectId, localId: localId), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "updateMask.fieldPaths", value: "fullName"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "email"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "phone")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FirestoreProfileDocument(profile: profile))

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
    }

    private func saveBankCards(_ cards: [BankCard], localId: String, idToken: String) async throws {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var components = URLComponents(url: firestoreDocumentURL(projectId: config.projectId, localId: localId), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "updateMask.fieldPaths", value: "bankCards")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FirestoreBankCardsDocument(cards: cards))

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
    }

    private func saveSubscription(_ subscription: UserSubscription, localId: String, idToken: String) async throws {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var components = URLComponents(url: firestoreDocumentURL(projectId: config.projectId, localId: localId), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscription"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionPlanId"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionTitle"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionStartedAt"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionExpiresAt"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionIsPurchased"),
            URLQueryItem(name: "updateMask.fieldPaths", value: "subscriptionPriceSom")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(FirestoreSubscriptionDocument(subscription: subscription))

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
    }

    private func deleteProfile(localId: String, idToken: String) async throws {
        guard let config else { throw FirebaseRESTError.missingConfiguration }

        var request = URLRequest(url: firestoreDocumentURL(projectId: config.projectId, localId: localId))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
    }

    private func firestoreDocumentURL(projectId: String, localId: String) -> URL {
        URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users/\(localId)")!
    }

    private func saveSession(_ response: AuthResponse) {
        defaults.set(response.idToken, forKey: SessionKeys.idToken)
        defaults.set(response.refreshToken, forKey: SessionKeys.refreshToken)
        defaults.set(response.localId, forKey: SessionKeys.localId)
        defaults.set(response.email, forKey: SessionKeys.email)
    }

    private func cacheProfile(_ profile: UserProfile) {
        defaults.set(profile.fullName, forKey: SessionKeys.fullName)
        defaults.set(profile.email, forKey: SessionKeys.email)
        defaults.set(profile.phone, forKey: SessionKeys.phone)
    }

    private func cachedProfile(fallbackEmail: String) -> UserProfile {
        let email = defaults.string(forKey: SessionKeys.email) ?? fallbackEmail
        let fallbackName = email.components(separatedBy: "@").first ?? "Пользователь"

        return UserProfile(
            fullName: defaults.string(forKey: SessionKeys.fullName) ?? fallbackName,
            email: email,
            phone: defaults.string(forKey: SessionKeys.phone) ?? ""
        )
    }

    private func validate(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let error = try? JSONDecoder().decode(FirebaseErrorResponse.self, from: data) {
                throw FirebaseRESTError.firebase(error.error.message)
            }
            throw FirebaseRESTError.httpStatus(httpResponse.statusCode)
        }
    }
}

private struct FirebaseRESTConfig {
    let apiKey: String
    let projectId: String

    static func load() -> FirebaseRESTConfig? {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path),
            let apiKey = values["API_KEY"] as? String,
            let projectId = values["PROJECT_ID"] as? String
        else {
            return nil
        }

        return FirebaseRESTConfig(apiKey: apiKey, projectId: projectId)
    }
}

private struct AuthResponse: Decodable {
    let idToken: String
    let email: String
    let refreshToken: String
    let localId: String
}

private struct TokenRefreshResponse: Decodable {
    let idToken: String
    let refreshToken: String
    let localId: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case localId = "user_id"
    }
}

private struct EmptyAuthResponse: Decodable {}

private struct FirebaseErrorResponse: Decodable {
    let error: FirebaseError
}

private struct FirebaseError: Decodable {
    let message: String
}

private struct FirestoreDocument: Decodable {
    let fields: [String: FirestoreValue]?

    func profile(fallbackEmail: String) -> UserProfile {
        let fullName = fields?["fullName"]?.stringValue
        let email = fields?["email"]?.stringValue ?? fallbackEmail
        let fallbackName = email.components(separatedBy: "@").first ?? "Пользователь"

        return UserProfile(
            fullName: fullName?.isEmpty == false ? fullName! : fallbackName,
            email: email,
            phone: fields?["phone"]?.stringValue ?? ""
        )
    }

    func bankCards() -> [BankCard] {
        fields?["bankCards"]?.arrayValue?.values?.compactMap { value in
            guard let fields = value.mapValue?.fields,
                  let idString = fields["id"]?.stringValue,
                  let id = UUID(uuidString: idString),
                  let typeString = fields["cardType"]?.stringValue,
                  let cardType = BankCard.CardType(rawValue: typeString),
                  let last4 = fields["last4"]?.stringValue,
                  let holderName = fields["holderName"]?.stringValue,
                  let expiry = fields["expiry"]?.stringValue else {
                return nil
            }

            return BankCard(
                id: id,
                last4: last4,
                cardType: cardType,
                holderName: holderName,
                expiry: expiry,
                cvv: ""
            )
        } ?? []
    }

    func subscription() -> UserSubscription {
        guard let documentFields = fields else { return .none }

        let formatter = ISO8601DateFormatter()
        let subscriptionFields = documentFields["subscription"]?.mapValue?.fields
        let planId = subscriptionFields?["planId"]?.stringValue ?? documentFields["subscriptionPlanId"]?.stringValue ?? ""
        let startedAtText = subscriptionFields?["startedAt"]?.stringValue ?? documentFields["subscriptionStartedAt"]?.stringValue ?? ""
        let expiresAtText = subscriptionFields?["expiresAt"]?.stringValue ?? documentFields["subscriptionExpiresAt"]?.stringValue ?? ""
        let isPurchasedText = subscriptionFields?["isPurchased"]?.stringValue ?? documentFields["subscriptionIsPurchased"]?.stringValue ?? "false"

        return UserSubscription(
            planId: planId,
            startedAt: formatter.date(from: startedAtText) ?? Date.distantPast,
            expiresAt: formatter.date(from: expiresAtText) ?? Date.distantPast,
            isPurchased: isPurchasedText == "true"
        )
    }
}

private struct FirestoreProfileDocument: Encodable {
    let fields: [String: FirestoreValue]

    init(profile: UserProfile) {
        fields = [
            "fullName": FirestoreValue(stringValue: profile.fullName),
            "email": FirestoreValue(stringValue: profile.email),
            "phone": FirestoreValue(stringValue: profile.phone)
        ]
    }
}

private struct FirestoreBankCardsDocument: Encodable {
    let fields: [String: FirestoreValue]

    init(cards: [BankCard]) {
        fields = [
            "bankCards": FirestoreValue(
                arrayValue: FirestoreArrayValue(
                    values: cards.map { card in
                        FirestoreValue(
                            mapValue: FirestoreMapValue(fields: [
                                "id": FirestoreValue(stringValue: card.id.uuidString),
                                "last4": FirestoreValue(stringValue: card.last4),
                                "cardType": FirestoreValue(stringValue: card.cardType.rawValue),
                                "holderName": FirestoreValue(stringValue: card.holderName),
                                "expiry": FirestoreValue(stringValue: card.expiry)
                            ])
                        )
                    }
                )
            )
        ]
    }
}

private struct FirestoreSubscriptionDocument: Encodable {
    let fields: [String: FirestoreValue]

    init(subscription: UserSubscription) {
        let formatter = ISO8601DateFormatter()
        let startedAt = formatter.string(from: subscription.startedAt)
        let expiresAt = formatter.string(from: subscription.expiresAt)
        let isPurchased = subscription.isPurchased ? "true" : "false"

        fields = [
            "subscription": FirestoreValue(
                mapValue: FirestoreMapValue(fields: [
                    "planId": FirestoreValue(stringValue: subscription.planId),
                    "startedAt": FirestoreValue(stringValue: startedAt),
                    "expiresAt": FirestoreValue(stringValue: expiresAt),
                    "isPurchased": FirestoreValue(stringValue: isPurchased)
                ])
            ),
            "subscriptionPlanId": FirestoreValue(stringValue: subscription.planId),
            "subscriptionTitle": FirestoreValue(stringValue: subscription.plan?.title ?? ""),
            "subscriptionStartedAt": FirestoreValue(stringValue: startedAt),
            "subscriptionExpiresAt": FirestoreValue(stringValue: expiresAt),
            "subscriptionIsPurchased": FirestoreValue(stringValue: isPurchased),
            "subscriptionPriceSom": FirestoreValue(stringValue: subscription.plan.map { "\($0.priceSom)" } ?? "0")
        ]
    }
}

private struct FirestoreValue: Codable {
    var stringValue: String?
    var arrayValue: FirestoreArrayValue?
    var mapValue: FirestoreMapValue?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.arrayValue = nil
        self.mapValue = nil
    }

    init(arrayValue: FirestoreArrayValue) {
        self.stringValue = nil
        self.arrayValue = arrayValue
        self.mapValue = nil
    }

    init(mapValue: FirestoreMapValue) {
        self.stringValue = nil
        self.arrayValue = nil
        self.mapValue = mapValue
    }
}

private struct FirestoreArrayValue: Codable {
    var values: [FirestoreValue]?
}

private struct FirestoreMapValue: Codable {
    var fields: [String: FirestoreValue]
}

private enum FirebaseRESTError: LocalizedError {
    case missingConfiguration
    case missingSession
    case firebase(String)
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Firebase не настроен. Добавьте GoogleService-Info.plist"
        case .missingSession:
            return "Войдите в аккаунт, чтобы сохранить данные в базе"
        case .firebase(let code):
            switch code {
            case "EMAIL_EXISTS":
                return "Этот email уже зарегистрирован"
            case "EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
                return "Неверный email или пароль"
            case "INVALID_EMAIL":
                return "Введите корректный email"
            case "WEAK_PASSWORD : Password should be at least 6 characters":
                return "Пароль должен быть не короче 6 символов"
            default:
                return code
            }
        case .httpStatus(let status):
            return "Ошибка сервера: \(status)"
        }
    }
}

// MARK: - Auth ViewModel
@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isAuthenticated = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentUserProfile: UserProfile?

    init() {
        guard FirebaseAuthRESTService.shared.hasSession else { return }

        isAuthenticated = true
        Task {
            currentUserProfile = try? await FirebaseAuthRESTService.shared.restoreProfile()
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let profile = try await FirebaseAuthRESTService.shared.signIn(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )
                currentUserProfile = profile
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Register
    func register(name: String, email: String, password: String, confirmPassword: String) {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            isLoading = false
            errorMessage = "Введите имя"
            return
        }

        guard trimmedEmail.contains("@") else {
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

        Task {
            do {
                let profile = try await FirebaseAuthRESTService.shared.register(
                    name: trimmedName,
                    email: trimmedEmail,
                    password: password
                )
                currentUserProfile = profile
                isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        successMessage = nil

        guard trimmedEmail.contains("@") else {
            errorMessage = "Введите email от аккаунта"
            return
        }

        isLoading = true

        Task {
            do {
                try await FirebaseAuthRESTService.shared.sendPasswordReset(email: trimmedEmail)
                successMessage = "Письмо для восстановления отправлено на \(trimmedEmail)"
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    // MARK: - Logout
    func logout() {
        FirebaseAuthRESTService.shared.logout()
        isAuthenticated = false
        currentUserProfile = nil
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Delete Account
    func deleteAccount() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                try await FirebaseAuthRESTService.shared.deleteAccount()
                logout()
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}
