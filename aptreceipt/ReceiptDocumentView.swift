import AppKit
import SwiftUI

// MARK: - A4 Invoice Document View (595 x 842 pt)

struct ReceiptDocumentView: View {
    let draft: ReceiptDraft
    let apartmentName: String
    let signatureImage: NSImage?
    var logoImage: NSImage? = nil
    let l10n: L10n
    /// Keys for the QR verification code; `nil` uses the app's keys (tests pass in-memory ones).
    var verificationKeys: ReceiptVerificationKeyStore? = nil

    /// Half a millimetre per QR module on paper, so phone cameras read the code.
    private static let qrPointsPerModule: CGFloat = 72 / 25.4 * 0.5
    /// Longest building, payer or manager name carried by the QR code, so it stays scannable.
    static let qrNameLimit = ReceiptPrintedText.nameLimit

    /// Title, number and amounts as printed; the Verify Receipt window rebuilds the same values.
    private var printed: ReceiptPrintedText { ReceiptPrintedText(draft: draft, apartmentName: apartmentName, l10n: l10n) }
    private var formattedAmount: String { printed.totalAmount }
    private var baseAmountFormatted: String { printed.baseAmount }
    private var lateFeeAmountFormatted: String { printed.lateFeeAmount }
    private var mainTitle: String { printed.mainTitle }
    private var documentSerialFormatted: String { printed.serial }
    private var documentType: String { printed.documentType }

    /// The receipt as labeled lines in its language, as the Verify Receipt window shows it.
    var qrLines: [String] { printed.lines }

    /// What the QR code holds: only the receipt sealed with this installation's key (`ReceiptQRBlock`).
    /// A phone camera shows the code and offers to copy it; nothing personal is readable, so even a web
    /// search reveals nothing. The resident sends the copied code to the management to verify.
    var qrContent: String {
        ReceiptQRBlock(draft: draft, building: apartmentName, language: l10n.resolvedLanguage)
            .sealed(with: (verificationKeys ?? .shared).currentKey) ?? ""
    }

    // Strict Print Colors (Dark Mode Proof)
    private let textDark = Color(red: 0.08, green: 0.11, blue: 0.15)
    private let textSecondary = Color(red: 0.28, green: 0.33, blue: 0.40)
    private let textMuted = Color(red: 0.45, green: 0.50, blue: 0.58)
    private let borderDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let borderSubtle = Color(red: 0.84, green: 0.88, blue: 0.92)
    private let cardBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    private let tableHeaderBg = Color(red: 0.12, green: 0.18, blue: 0.26)





    private var receiptBadgeText: String {
        switch draft.kind {
        case .income: return l10n.incomeBadge
        case .outcome: return l10n.outcomeBadge
        case .managementExpense: return l10n.managementExpenseBadge
        }
    }


    private var amountInWords: String {
        NumberToWords.convert(draft.amount, language: l10n.resolvedLanguage, currency: draft.currency)
    }

    private var itemDescriptionText: String {
        if !draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.notes != "-" {
            return draft.notes
        }
        switch draft.kind {
        case .income: return l10n.defaultItemNameIncome
        case .outcome: return l10n.defaultItemNameExpense
        case .managementExpense: return l10n.defaultItemNameManagementExpense
        }
    }

    private var badgeColor: Color {
        switch draft.kind {
        case .income: return Color(red: 0.10, green: 0.50, blue: 0.25)
        case .outcome: return Color(red: 0.78, green: 0.30, blue: 0.12)
        case .managementExpense: return Color(red: 0.18, green: 0.35, blue: 0.78)
        }
    }

    private var badgeBackground: Color {
        switch draft.kind {
        case .income: return Color(red: 0.92, green: 0.97, blue: 0.93)
        case .outcome: return Color(red: 0.99, green: 0.94, blue: 0.92)
        case .managementExpense: return Color(red: 0.92, green: 0.94, blue: 0.99)
        }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 1. Official Header
            HStack(alignment: .top, spacing: 14) {
                if let logo = logoImage {
                    Image(nsImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(borderSubtle, lineWidth: 1)
                        )
                } else {
                    Default2DBuildingLogo(size: 52)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(mainTitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(textDark)
                        .tracking(0.5)

                    Text(l10n.invoiceSubHeader)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textMuted)

                    HStack(spacing: 6) {
                        Text(receiptBadgeText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(badgeBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                            )

                        Text("•")
                            .foregroundColor(textMuted)

                        Text(draft.monthYear)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textDark)
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Official Serial and Date Box
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(l10n.serialLabel + ":")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textMuted)
                        Text(documentSerialFormatted)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                    }

                    HStack(spacing: 4) {
                        Text(l10n.issueDate)
                            .font(.system(size: 10))
                            .foregroundColor(textMuted)
                        Text(draft.createdDate)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                    }

                    HStack(spacing: 4) {
                        Text(l10n.invoiceTypeLabel + ":")
                            .font(.system(size: 10))
                            .foregroundColor(textMuted)
                        Text(documentType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }
            }
            .padding(.bottom, 12)

            // Double Rule
            Rectangle()
                .fill(borderDark)
                .frame(height: 2)
            Rectangle()
                .fill(borderDark.opacity(0.25))
                .frame(height: 0.8)
                .padding(.top, 2)
                .padding(.bottom, 16)

            // MARK: 2. Dual Party Cards (Management & Resident)
            HStack(spacing: 12) {
                // Left: Issuer Card
                VStack(alignment: .leading, spacing: 5) {
                    Text(l10n.managerSectionTitle)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(0.5)

                    Divider()

                    infoRow(label: l10n.invoiceBuildingLabel, value: mainTitle)
                    infoRow(label: l10n.invoiceManagerLabel, value: draft.issuer)
                    infoRow(label: l10n.invoiceTypeLabel + ":", value: documentType)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )

                // Right: Payer / Resident Card
                VStack(alignment: .leading, spacing: 5) {
                    Text(draft.kind == .managementExpense ? l10n.vendorSectionTitle : l10n.payerSectionTitle)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(0.5)

                    Divider()

                    let receiverTitle = draft.kind == .income ? l10n.invoicePayerResidentLabel : l10n.invoiceVendorLabel
                    infoRow(label: receiverTitle, value: draft.receiver)
                    if draft.kind != .managementExpense {
                        let flatText = (draft.showApartmentNumber && draft.apartmentNumber > 0) ? "\(l10n.flatPrefix) \(draft.apartmentNumber)" : l10n.commonAreaLabel
                        infoRow(label: l10n.invoiceUnitLabel, value: flatText)
                    }
                    infoRow(label: l10n.period, value: draft.monthYear)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
            .padding(.bottom, 16)

            // MARK: 3. Itemized Invoice Table
            VStack(spacing: 0) {
                // Table Header
                HStack(spacing: 0) {
                    Text(l10n.itemNo)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 36, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemDescription)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    Divider().frame(height: 14)
                    Text(l10n.itemPeriod)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 80, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemUnit)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 60, alignment: .center)
                    Divider().frame(height: 14)
                    Text(l10n.itemAmount)
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 95, alignment: .trailing)
                        .padding(.trailing, 8)
                }
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .background(tableHeaderBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Table Rows
                if draft.lateFeeAmount > 0 {
                    // Row 01: Base Dues
                    HStack(spacing: 0) {
                        Text("01")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(itemDescriptionText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text(l10n.unitMonth)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text(baseAmountFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )

                    // Row 02: KMK Md. 20 Late Fee
                    HStack(spacing: 0) {
                        Text("02")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(l10n.lateFeeItemName(rate: draft.lateFeeRate, months: draft.lateMonths))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text("\(draft.lateMonths) \(draft.lateMonths > 1 ? l10n.monthsUnit : l10n.monthUnit)")
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text("+" + lateFeeAmountFormatted)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .background(Color(red: 0.99, green: 0.97, blue: 0.94))
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                } else {
                    HStack(spacing: 0) {
                        Text("01")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 36, alignment: .center)

                        Text(itemDescriptionText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        Text(draft.monthYear)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 80, alignment: .center)

                        Text(l10n.unitMonth)
                            .font(.system(size: 9.5))
                            .foregroundColor(textSecondary)
                            .frame(width: 60, alignment: .center)

                        Text(formattedAmount)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                            .frame(width: 95, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .fill(borderSubtle)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                }
            }
            .padding(.bottom, 16)

            // MARK: 4. Calculation & Totals Section
            HStack(alignment: .top, spacing: 14) {
                // Left: In Words and Legal Notices
                VStack(alignment: .leading, spacing: 8) {
                    // Yalnız (In Words) Box
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.inWordsPrefix)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(textMuted)

                        Text("# \(amountInWords) #")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(textDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderSubtle, lineWidth: 1)
                    )

                    // Statutory Exemption Text
                    Text(l10n.statutoryTaxNotice)
                        .font(.system(size: 8.5))
                        .foregroundColor(textMuted)

                    Text(l10n.legalStatutoryNotice)
                        .font(.system(size: 8.5))
                        .foregroundColor(textMuted)

                    if draft.lateFeeAmount > 0 {
                        let footnote = draft.lateFeeFootnote ?? ReceiptSettingsStore.shared.effectiveLateFeeFootnote()
                        Text(footnote)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Financial Totals Box
                VStack(spacing: 5) {
                    if draft.lateFeeAmount > 0 {
                        HStack {
                            Text(l10n.baseDuesAmount)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(textSecondary)
                            Spacer()
                            Text(baseAmountFormatted)
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(textDark)
                        }

                        HStack {
                            Text(l10n.lateFeeCalculated)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                            Spacer()
                            Text("+" + lateFeeAmountFormatted)
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.82, green: 0.42, blue: 0.12))
                        }
                    } else {
                        HStack {
                            Text(l10n.subtotal)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textSecondary)
                            Spacer()
                            Text(formattedAmount)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(textDark)
                        }
                    }

                    HStack {
                        Text(l10n.vatTax)
                            .font(.system(size: 9.5))
                            .foregroundColor(textMuted)
                        Spacer()
                        Text(l10n.vatExempt)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(textSecondary)
                    }

                    Divider().padding(.vertical, 2)

                    HStack {
                        Text(l10n.grandTotal)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textDark)
                        Spacer()
                        Text(formattedAmount)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(badgeColor)
                    }
                    .padding(8)
                    .background(badgeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(badgeColor.opacity(0.35), lineWidth: 1)
                    )
                }
                .frame(width: 220)
                .padding(10)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
            .padding(.bottom, 20)

            Spacer(minLength: 20)

            // MARK: 5. Footer & Authorized Signature
            HStack(alignment: .bottom, spacing: 14) {
                // QR Verification Code
                if let qrImage = QRCodeGenerator.generate(from: qrContent, pointsPerModule: Self.qrPointsPerModule) {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: qrImage.size.width, height: qrImage.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(borderSubtle, lineWidth: 1)
                        )
                }

                // Electronic verification and tracking footer
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.qrVerificationNotice)
                        .font(.system(size: 8))
                        .foregroundColor(textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(documentSerialFormatted)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(textDark)
                        Text("•")
                            .foregroundColor(textMuted)
                        Text(draft.createdDate)
                            .font(.system(size: 8.5))
                            .foregroundColor(textMuted)
                    }

                    Text("\(l10n.appTitle) v\(AppInfo.version) • \(l10n.publisher)")
                        .font(.system(size: 8))
                        .foregroundColor(textMuted.opacity(0.8))
                }

                Spacer()

                // Stamp & Signature Box
                VStack(alignment: .center, spacing: 4) {
                    Text(l10n.signatureStamp)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(textSecondary)
                        .tracking(0.5)

                    if let signatureImage {
                        Image(nsImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 52)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 140, height: 42)
                    }

                    Rectangle()
                        .fill(borderDark.opacity(0.4))
                        .frame(width: 150, height: 1)

                    Text(draft.issuer)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textDark)
                }
                .frame(width: 160)
                .padding(8)
                .background(cardBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(borderSubtle, lineWidth: 1)
        )
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(textMuted)
                .frame(width: 86, alignment: .leading)

            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(textDark)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
