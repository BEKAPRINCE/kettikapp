import SwiftUI

// MARK: - Edit Profile View
struct EditProfileView: View {
    
    @EnvironmentObject var vm: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var draftName:  String = ""
    @State private var draftEmail: String = ""
    @State private var draftPhone: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field { case name, email, phone }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Form fields
                    VStack(spacing: 16) {
                        ProfileField(
                            icon: "person.fill",
                            label: "Имя и фамилия",
                            placeholder: "Введите имя",
                            text: $draftName,
                            focus: $focusedField,
                            fieldKey: .name,
                            keyboard: .default
                        )
                        ProfileField(
                            icon: "envelope.fill",
                            label: "Email",
                            placeholder: "example@mail.com",
                            text: $draftEmail,
                            focus: $focusedField,
                            fieldKey: .email,
                            keyboard: .emailAddress
                        )
                        ProfileField(
                            icon: "phone.fill",
                            label: "Телефон",
                            placeholder: "+996 700 000 000",
                            text: $draftPhone,
                            focus: $focusedField,
                            fieldKey: .phone,
                            keyboard: .phonePad
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Save button
                    Button {
                        let updated = UserProfile(
                            fullName: draftName,
                            email:    draftEmail,
                            phone:    draftPhone,
                            role:     vm.profile.role
                        )
                        vm.saveProfile(updated)
                        dismiss()
                    } label: {
                        Text("Сохранить изменения")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.accentTeal, Color(hex: "#4C79D8")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .accentTeal.opacity(0.35), radius: 12, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .disabled(draftName.isEmpty || draftEmail.isEmpty)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 32)
            }
        }
        .navigationTitle("Редактировать профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draftName  = vm.profile.fullName
            draftEmail = vm.profile.email
            draftPhone = vm.profile.phone
        }
    }
}

// MARK: - Profile Field
struct ProfileField: View {
    let icon: String
    let label: String
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<EditProfileView.Field?>.Binding
    let fieldKey: EditProfileView.Field
    let keyboard: UIKeyboardType
    
    private var isFocused: Bool { focus.wrappedValue == fieldKey }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                Text(label)
                    .font(.appCaption)
                    .foregroundColor(.textMuted)
            }
            
            TextField(placeholder, text: $text)
                .font(.appBody)
                .foregroundColor(.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .focused(focus, equals: fieldKey)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isFocused ? Color.accentTeal.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(SettingsViewModel())
    }
}
