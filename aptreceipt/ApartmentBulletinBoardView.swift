import SwiftUI

// MARK: - Printable Apartment Bulletin Board Notice View (A4)

struct ApartmentBulletinBoardView: View {
    let settings: ReceiptSettingsStore
    let periodTitle: String
    let totalIncome: Double
    let totalExpenses: Double
    let netBalance: Double
    let expenseCategories: [(category: String, amount: Double, percent: Double)]
    let paidFlatsCount: Int
    let totalFlatsCount: Int
    let records: [ReceiptRecord]
    let l10n: L10n

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(alignment: .top) {
                if let logo = settings.logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                } else {
                    Default2DBuildingLogo(size: 48)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.apartmentName.isEmpty ? l10n.defaultBuildingName : l10n.uppercased(settings.apartmentName))
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.bulletinBoardNoticeTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(periodTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date().dayMonthYearString(locale: settings.currentLocale))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 6)

            Divider()

            // Financial Balance Cards (3 Columns)
            HStack(spacing: 12) {
                balanceBox(title: l10n.totalIncome, amount: totalIncome, color: .green, icon: "arrow.down.left.circle.fill")
                balanceBox(title: l10n.totalExpenses, amount: totalExpenses, color: .red, icon: "arrow.up.right.circle.fill")
                balanceBox(title: l10n.netCashBalance, amount: netBalance, color: netBalance >= 0 ? Color(red: 0.22, green: 0.42, blue: 0.88) : .red, icon: "banknote.fill")
            }

            // Dues Collection Status Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(l10n.duesTrackingTab)
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                    Text("\(paidFlatsCount) / \(totalFlatsCount) \(l10n.duesPaidCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }

                GeometryReader { geo in
                    let ratio = totalFlatsCount > 0 ? CGFloat(paidFlatsCount) / CGFloat(totalFlatsCount) : 0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: geo.size.width * ratio, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Expense Categories Breakdown
            if !expenseCategories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.presetUtilities)
                        .font(.system(size: 11, weight: .bold))

                    VStack(spacing: 6) {
                        ForEach(expenseCategories.prefix(6), id: \.category) { item in
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(AppFormat.currency(item.amount, settings.currency, l10n: l10n))
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                Text(String(format: "(%%%0.1f)", item.percent))
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
                            Divider()
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            // Footer & Manager Signature
            Divider()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.bulletinBoardNoticeFooter)
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                    Text(l10n.bulletinFooterTagline)
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text(l10n.managerSignatureTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    if let sig = settings.signatureImage {
                        Image(nsImage: sig)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 35)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 90, height: 35)
                    }

                    Text(settings.issuer.isEmpty ? l10n.managerSignatureTitle : settings.issuer)
                        .font(.system(size: 10.5, weight: .bold))
                }
            }
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
    }

    private func balanceBox(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Text(AppFormat.currency(amount, settings.currency, l10n: l10n))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
