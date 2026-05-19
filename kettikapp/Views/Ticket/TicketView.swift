import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Ticket View
struct TicketView: View {
    
    @EnvironmentObject var vm: TicketViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var appeared = false
    @State private var showSubscriptionSheet = false

    private var subscription: UserSubscription {
        settingsViewModel.subscription
    }

    private var displayedTicket: MonthlyTicket {
        var ticket = vm.ticket
        ticket.ownerName = settingsViewModel.profile.fullName
        if subscription.isActive {
            ticket.validUntil = subscription.expiresAt
        }
        return ticket
    }

    private var qrString: String {
        let email = settingsViewModel.profile.email
        let ticketNumber = vm.ticket.ticketNumber
        return "KETTIK:\(ticketNumber):\(email):\(subscription.planId)"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settingsViewModel.text("Мой билет", "My ticket"))
                            .font(.appTitle)
                            .foregroundColor(.textPrimary)
                        Text(subscription.isActive ? subscription.plan?.title ?? settingsViewModel.text("Проездной", "Pass") : settingsViewModel.text("Нет активной подписки", "No active subscription"))
                            .font(.appCaption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    StatusBadge(isActive: subscription.isActive)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if subscription.isActive {
                    TicketCardView(
                        ticket: displayedTicket,
                        qrString: qrString,
                        planName: subscription.plan?.title ?? "Проездной",
                        tripsText: subscription.plan?.tripsText ?? "0"
                    )
                    .padding(.horizontal, 20)
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    StatsGridView(items: vm.statsItems)
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                } else {
                    EmptyTicketState {
                        showSubscriptionSheet = true
                    }
                        .padding(.horizontal, 20)
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            NavigationStack {
                SubscriptionView()
                    .environmentObject(settingsViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(settingsViewModel.text("Готово", "Done")) {
                                showSubscriptionSheet = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? settingsVM.text("АКТИВЕН", "ACTIVE") : settingsVM.text("ИСТЁК", "EXPIRED"))
            .font(.appLabel)
            .foregroundColor(isActive ? .accentTeal : .dangerRed)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background((isActive ? Color.accentTeal : Color.dangerRed).opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke((isActive ? Color.accentTeal : Color.dangerRed).opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Ticket Card
struct TicketCardView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let ticket: MonthlyTicket
    let qrString: String
    let planName: String
    let tripsText: String
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Color strip
            LinearGradient(
                colors: [.accentTeal, .accentYellow, .accentOrange],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 5)
            .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight], radius: 24))
            
            VStack(spacing: 20) {
                // Card header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(settingsVM.text("ЕДИНЫЙ ПРОЕЗДНОЙ", "TRANSIT PASS"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.textMuted)
                            .kerning(1.5)
                        Text("Kettik")
                            .font(.appHeadline)
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "bus.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.accentTeal)
                }
                
                // QR Code
                QRCodeView(string: qrString)
                    .frame(width: 180, height: 180)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 12)
                
                // Owner
                VStack(spacing: 3) {
                    Text(settingsVM.text("Владелец", "Owner"))
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                    Text(ticket.ownerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
                
                // Dashed divider
                DashedDivider()
                
                // Details row
                HStack {
                    TicketDetailItem(label: settingsVM.text("Тип", "Type"), value: planName)
                    Divider().frame(height: 40)
                    TicketDetailItem(label: settingsVM.text("До", "Until"), value: ticket.validUntilText)
                    Divider().frame(height: 40)
                    TicketDetailItem(label: settingsVM.text("Поездок", "Rides"), value: tripsText)
                }
                
                // Ticket number
                Text("№ \(ticket.ticketNumber.suffix(16))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textMuted)
                    .padding(.top, -8)
            }
            .padding(20)
            .background(Color.cardBackground)
            .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 24))
        }
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Empty Ticket State
struct EmptyTicketState: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentTeal.opacity(0.14))
                    .frame(width: 72, height: 72)
                Image(systemName: "ticket")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.accentTeal)
            }

            VStack(spacing: 6) {
                Text(settingsVM.text("Проездной не активен", "Pass is inactive"))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(settingsVM.text("Оформите подписку в профиле, чтобы здесь появился QR-билет для поездок.", "Activate a subscription in Profile to show your QR ticket here."))
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 6) {
                Text(settingsVM.text("От 390 сом в месяц", "From 390 KGS/month"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.accentYellow)
                Text(settingsVM.text("Средний расход наличными — около 2 025 сом в месяц", "Average cash spending is about 2,025 KGS/month"))
                    .font(.appCaption)
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
            }

            Button(action: onPurchase) {
                HStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                    Text(settingsVM.text("Купить проездной", "Buy pass"))
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.accentTeal, Color(hex: "#4C79D8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .accentTeal.opacity(0.28), radius: 12, y: 6)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 30)
        .cardStyle()
    }
}

// MARK: - Ticket Detail Item
struct TicketDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.appCaption)
                .foregroundColor(.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Grid
struct StatsGridView: View {
    let items: [(label: String, value: String, icon: String, color: String)]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("СТАТИСТИКА ЗА МЕСЯЦ")
                .font(.appLabel)
                .foregroundColor(.textMuted)
                .kerning(1)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items, id: \.label) { item in
                    StatCard(label: item.label, value: item.value,
                             icon: item.icon, colorHex: item.color)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let colorHex: String
    
    var accentColor: Color { Color(hex: colorHex) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - QR Code View (native CoreImage)
struct QRCodeView: View {
    let string: String
    
    private var qrImage: UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    var body: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBorder.opacity(0.5))
                .overlay(Text("QR").foregroundColor(.textMuted))
        }
    }
}

// MARK: - Dashed Divider
struct DashedDivider: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundColor(Color.cardBorder)
        }
        .frame(height: 1)
    }
}

// MARK: - Rounded Corner Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    TicketView()
        .environmentObject(TicketViewModel())
        .environmentObject(SettingsViewModel())
}
