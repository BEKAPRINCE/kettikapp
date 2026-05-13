import SwiftUI

// MARK: - Bank Cards View
struct BankCardsView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    @State private var showAddCard = false
    @State private var editingCard: BankCard?
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Cards list
                    if vm.cards.isEmpty {
                        EmptyCardsView()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.cards) { card in
                                BankCardItem(card: card, onEdit: { editingCard = card }, onDelete: {
                                    vm.removeCard(id: card.id)
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Add card button
                    Button { showAddCard = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentTeal)
                            Text("Привязать карту")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.accentTeal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentTeal.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.accentTeal.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            
            // Toast
            if let msg = vm.toastMessage {
                ToastView(message: msg)
            }
        }
        .navigationTitle("Банковские карты")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddCard) {
            AddCardSheet(editingCard: nil) { vm.addCard($0) }
        }
        .sheet(item: $editingCard) { card in
            AddCardSheet(editingCard: card) { vm.updateCard($0) }
        }
    }
}

// MARK: - Bank Card Item
struct BankCardItem: View {
    let card: BankCard
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Card visual
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(hex: "#2C4F85"), Color(hex: "#3E6BAA")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 38)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                Image(systemName: card.cardType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(card.cardType.rawValue) \(card.last4)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Text("Изменить")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentTeal)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.accentTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button {
                showDeleteAlert = true
            } label: {
                Text("Удалить")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.dangerRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.dangerRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .cardStyle()
        .alert("Удалить карту?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) { onDelete() }
        } message: {
            Text("Карта •••• \(card.last4) будет отвязана.")
        }
    }
}

// MARK: - Empty Cards View
struct EmptyCardsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 50))
                .foregroundColor(.textMuted)
            Text("Нет привязанных карт")
                .font(.appHeadline)
                .foregroundColor(.textSecondary)
            Text("Добавьте карту для быстрой оплаты проезда")
                .font(.appCaption)
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
    }
}

// MARK: - Add Card Sheet
struct AddCardSheet: View {
    let editingCard: BankCard?
    let onSave: (BankCard) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var cardNumber = ""
    @State private var holderName = ""
    @State private var expiry     = ""
    @State private var cvv        = ""
    @State private var selectedType: BankCard.CardType = .visa
    
    private var isEditMode: Bool { editingCard != nil }
    var last4: String {
        if let card = editingCard { return card.last4 }
        let digits = cardNumber.filter { $0.isNumber }
        return String(digits.suffix(4))
    }
    var isValid: Bool { (isEditMode ? true : cardNumber.filter { $0.isNumber }.count >= 4) && !holderName.isEmpty && cvv.count >= 3 }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Card preview
                        CardPreview(number: cardNumber, holder: holderName, expiry: expiry, type: selectedType, isMasked: isEditMode, maskedLast4: editingCard?.last4)
                            .padding(.horizontal, 20)
                            .onAppear {
                                if let card = editingCard {
                                    cardNumber = "•••• •••• •••• \(card.last4)"
                                    holderName = card.holderName
                                    expiry = card.expiry
                                    cvv = card.cvv
                                    selectedType = card.cardType
                                }
                            }
                        
                        // Card type selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ТИП КАРТЫ")
                                .font(.appLabel)
                                .foregroundColor(.textMuted)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 10) {
                                ForEach([BankCard.CardType.visa, .mastercard,.elcard], id: \.self) { type in
                                    Button { selectedType = type } label: {
                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(selectedType == type ? .white : .textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedType == type ? Color.accentTeal : Color.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Form
                        VStack(spacing: 14) {
                            AddCardField(label: "Номер карты", placeholder: "0000 0000 0000 0000",
                                         text: $cardNumber, keyboard: .numberPad, disabled: isEditMode)
                            AddCardField(label: "Имя владельца", placeholder: "IVAN IVANOV",
                                         text: $holderName, keyboard: .default)
                            HStack(spacing: 14) {
                                AddCardField(label: "Срок действия", placeholder: "MM/YY",
                                             text: $expiry, keyboard: .numberPad)
                                    .onChange(of: expiry) { _, newValue in
                                        let digits = newValue.filter { $0.isNumber }
                                        let limited = String(digits.prefix(4))
                                        let formatted = limited.count <= 2
                                            ? limited
                                            : String(limited.prefix(2)) + "/" + String(limited.dropFirst(2))
                                        if formatted != newValue { expiry = formatted }
                                    }
                                AddCardField(label: "CVV", placeholder: "123",
                                             text: $cvv, keyboard: .numberPad, isSecure: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Button {
                            let id = editingCard?.id ?? UUID()
                            let card = BankCard(id: id, last4: last4, cardType: selectedType, holderName: holderName.uppercased(), expiry: expiry, cvv: cvv)
                            onSave(card)
                            dismiss()
                        } label: {
                            Text(isEditMode ? "Сохранить изменения" : "Привязать карту")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: .accentTeal.opacity(0.35), radius: 12, y: 5)
                                .opacity(isValid ? 1 : 0.4)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle(isEditMode ? "Редактировать карту" : "Добавить карту")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Отмена") { dismiss() }.foregroundColor(.accentTeal))
        }
    }
}

// MARK: - Card Preview
struct CardPreview: View {
    let number: String
    let holder: String
    let expiry: String
    let type: BankCard.CardType
    var isMasked: Bool = false
    var maskedLast4: String? = nil
    
    var formattedNumber: String {
        if isMasked, let last4 = maskedLast4 {
            return "•••• •••• •••• \(last4)"
        }
        let raw = number.filter { $0.isNumber }
        let padded = raw.padding(toLength: 16, withPad: "0", startingAt: 0)
        let groups = stride(from: 0, to: 16, by: 4).map { i -> String in
            let start = padded.index(padded.startIndex, offsetBy: i)
            let end   = padded.index(start, offsetBy: 4)
            return String(padded[start..<end])
        }
        return groups.joined(separator: " ")
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(hex: "#2C4F85"), Color(hex: "#1F3C73")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            
            // Decorative circles
            Circle().fill(Color.white.opacity(0.05)).frame(width: 180).offset(x: 80, y: -60)
            Circle().fill(Color.white.opacity(0.05)).frame(width: 140).offset(x: -60, y: 60)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "wave.3.right")
                        .foregroundColor(.accentTeal)
                        .font(.system(size: 24))
                    Spacer()
                    Text(type.rawValue)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(formattedNumber)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(2)
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Владелец").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                        Text(holder.isEmpty ? "YOUR NAME" : holder.uppercased())
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Действует до").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                        Text(expiry.isEmpty ? "MM/YY" : expiry)
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 190)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Add Card Field
struct AddCardField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    var isSecure: Bool = false
    var disabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.textMuted)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.appBody)
            .foregroundColor(.textPrimary)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .disabled(disabled)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
        }
    }
}

#Preview {
    BankCardsView()
        .environmentObject(SettingsViewModel())
}
