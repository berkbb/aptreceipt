import AppKit
import SwiftUI

// MARK: - Default 2D Building Logo

struct Default2DBuildingLogo: View {
    var size: CGFloat = 48
    var foregroundColor: Color = Color(red: 0.12, green: 0.18, blue: 0.28)
    var backgroundColor: Color = Color(red: 0.94, green: 0.96, blue: 0.98)
    var borderColor: Color = Color(red: 0.82, green: 0.86, blue: 0.90)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(backgroundColor)
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)

            VStack(spacing: 0) {
                Image(systemName: "building.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
                    .foregroundColor(foregroundColor)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Live Preview Widget

struct LiveReceiptPreview: View {
    let kind: ReceiptKind
    let apartmentName: String
    let apartmentNumber: Int
    let showApartmentNumber: Bool
    let period: String
    let issuer: String
    let receiver: String
    let amountString: String
    let sequenceNumber: String
    let notes: String
    let signatureImage: NSImage?
    let currency: AppCurrency
    let l10n: L10n
    var logoImage: NSImage? = nil
    var isLateFeeApplied: Bool = false
    var baseAmount: Double = 0.0
    var lateFeeAmount: Double = 0.0
    var lateFeeRate: Double = 0.0
    var lateMonths: Int = 0

    private var formattedAmount: String {
        let normalized = amountString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = l10n.locale
            formatter.currencySymbol = currency.symbol
            formatter.currencyCode = currency.code
            return formatter.string(from: NSNumber(value: val)) ?? "\(currency.symbol) \(amountString)"
        }
        return "\(currency.symbol) 0,00"
    }

    private var badgeText: String {
        switch kind {
        case .income: return l10n.incomeBadge
        case .outcome: return l10n.outcomeBadge
        case .managementExpense: return l10n.managementExpenseBadge
        }
    }

    private var badgeColor: Color {
        switch kind {
        case .income: return .green
        case .outcome: return .orange
        case .managementExpense: return Color(red: 0.22, green: 0.42, blue: 0.88)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                if let logo = logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
                        )
                } else {
                    Default2DBuildingLogo(size: 36)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(apartmentName.isEmpty ? l10n.defaultBuildingName : apartmentName.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(badgeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(badgeColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(l10n.sequenceNo): #\(sequenceNumber)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text(period)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Info rows
            VStack(spacing: 8) {
                if kind == .managementExpense {
                    previewRow(label: l10n.invoiceVendorLabel, value: receiver)
                    previewRow(label: l10n.managerPayerLabel, value: issuer)
                } else {
                    previewRow(label: l10n.receiverLabel, value: receiver)
                    if showApartmentNumber {
                        previewRow(label: l10n.flatNumber, value: "\(l10n.flatPrefix) \(apartmentNumber)")
                    }
                    previewRow(label: l10n.issuerLabel, value: issuer)
                }
                previewRow(label: l10n.dateLabel, value: Date().dayMonthYearString(locale: l10n.locale))
            }

            // Late Fee Breakdown Preview
            if isLateFeeApplied && lateFeeAmount > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.baseDuesAmount)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f %@", baseAmount, currency.symbol))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }

                    Spacer()

                    Text("+")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(l10n.lateFeeCalculated) (%\(String(format: "%.1f", lateFeeRate)) × \(lateMonths))")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.orange)
                        Text(String(format: "+%.2f %@", lateFeeAmount, currency.symbol))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Amount Highlight Box
            HStack {
                Text(l10n.totalPaid)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedAmount)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(badgeColor)
            }
            .padding(12)
            .background(badgeColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(badgeColor.opacity(0.25), lineWidth: 1)
            )

            // Verifiable QR Indicator
            HStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.system(size: 11, weight: .bold))
                Text(l10n.qrCodeActive)
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Text(l10n.qrVerificationNotice)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .foregroundColor(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badgeColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Notes
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.descriptionHeader)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Signature area
            if let signature = signatureImage {
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: 4) {
                        Image(nsImage: signature)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        Text(l10n.authorizedSignature)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
