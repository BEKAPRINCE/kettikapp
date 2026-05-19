import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var vm: SettingsViewModel

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SubscriptionSummaryCard(subscription: vm.subscription)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.text("ТАРИФЫ", "PLANS"))
                            .font(.appLabel)
                            .foregroundColor(.textMuted)
                            .kerning(1)
                            .padding(.leading, 4)

                        ForEach(SubscriptionPlan.allCases) { plan in
                            SubscriptionPlanCard(
                                plan: plan,
                                isCurrent: vm.subscription.isActive && vm.subscription.plan == plan
                            ) {
                                vm.purchaseSubscription(plan)
                            }
                        }
                    }

                    if vm.subscription.isActive {
                        Button {
                            vm.cancelSubscription()
                        } label: {
                            Text(vm.text("Отключить подписку", "Disable subscription"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.dangerRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.dangerRed.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }

            if let msg = vm.toastMessage {
                ToastView(message: msg)
            }
        }
        .navigationTitle(vm.text("Подписка", "Subscription"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SubscriptionSummaryCard: View {
    @EnvironmentObject var vm: SettingsViewModel
    let subscription: UserSubscription

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.isActive ? vm.text("Подписка активна", "Subscription active") : vm.text("Подписка не активна", "Subscription inactive"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text(subscription.isActive ? vm.text("Действует до \(subscription.validUntilText)", "Valid until \(subscription.validUntilText)") : vm.text("Выберите тариф ниже", "Choose a plan below"))
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: subscription.isActive ? "checkmark.seal.fill" : "ticket")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(subscription.isActive ? .accentGreen : .textMuted)
            }

            if let plan = subscription.plan, subscription.isActive {
                HStack(spacing: 10) {
                    SubscriptionChip(text: plan.title)
                    SubscriptionChip(text: plan.tripLimitText(language: vm.language))
                }
            } else {
                Text(vm.text("Средний расход наличными: около 2 025 сом в месяц. Льготные квоты начинаются от 390 сом.", "Average cash spending is about 2,025 KGS per month. Discount quotas start at 390 KGS."))
                    .font(.appCaption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke((subscription.isActive ? Color.accentGreen : Color.cardBorder).opacity(0.25), lineWidth: 1)
        )
    }
}

private struct SubscriptionChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.accentTeal)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentTeal.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct SubscriptionPlanCard: View {
    @EnvironmentObject var vm: SettingsViewModel
    let plan: SubscriptionPlan
    let isCurrent: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("\(plan.audienceText(language: vm.language)) • \(plan.tripLimitText(language: vm.language))")
                        .font(.appCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(plan.priceText)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.textPrimary)

                    Text(plan.usdText)
                        .font(.appCaption)
                        .foregroundColor(.textMuted)
                }
            }

            Text(plan.savingsText(language: vm.language))
                .font(.appCaption)
                .foregroundColor(.accentYellow)

            Button(action: onPurchase) {
                Text(isCurrent ? vm.text("Оформлено", "Active") : vm.text("Оформить", "Activate"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isCurrent ? .accentGreen : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(isCurrent ? Color.accentGreen.opacity(0.14) : Color.accentTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isCurrent)
        }
        .padding(16)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isCurrent ? Color.accentGreen.opacity(0.35) : Color.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
            .environmentObject(SettingsViewModel())
    }
}
