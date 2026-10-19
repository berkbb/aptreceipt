import SwiftUI

// MARK: - View Model

@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published var selectedApartment: Int = 1
    @Published var receiptDate: Date = Date()
    @Published var issuerName: String = ""
    @Published var ownerName: String = ""
    @Published var sequenceNumber: String = "1"
    @Published var totalAmount: String = ""
    @Published var notes: String = ""
    @Published var printApartmentNumber: Bool = true
    @Published var receiptKind: ReceiptKind = .income

    @Published var previewDraft: ReceiptDraft?
    @Published var isPresentingSettings: Bool = false
    @Published var isPresentingArchive: Bool = false
    @Published var isPresentingFinancialReport: Bool = false
    @Published var isPresentingBatchDues: Bool = false
    @Published var validationError: ValidationError?

    @Published var attachedInvoicePath: String? = nil
    @Published var isScanningInvoice: Bool = false
    @Published var invoiceScanBanner: String? = nil

    @Published var isLateFeeApplied: Bool = false
    @Published var lateMonths: Int = 1
    @Published var customLateFeeRate: String = ""

    func syncWithSettings(_ settings: ReceiptSettingsStore) {
        selectedApartment = settings.apartmentNumbers.first ?? 1
        receiptDate = Date()
        issuerName = settings.issuer
        ownerName = settings.owner(for: selectedApartment)
        sequenceNumber = String(settings.seqNumber)
        totalAmount = settings.defaultPayment
        notes = ""
        printApartmentNumber = true
        receiptKind = .income
        attachedInvoicePath = nil
        invoiceScanBanner = nil
        isLateFeeApplied = false
        lateMonths = 1
        customLateFeeRate = String(format: "%.1f", settings.lateFeeMonthlyRate)
    }

    func effectiveLateRate(settings: ReceiptSettingsStore) -> Double {
        let cleaned = customLateFeeRate.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let val = Double(cleaned), val >= 0 {
            return val
        }
        return settings.lateFeeMonthlyRate
    }

    func baseDuesAmount() -> Double {
        parseAmount(totalAmount) ?? 0.0
    }

    func calculatedLateFee(settings: ReceiptSettingsStore) -> Double {
        guard isLateFeeApplied && receiptKind == .income else { return 0.0 }
        let base = baseDuesAmount()
        let rate = effectiveLateRate(settings: settings)
        return LateFeeCalculator.fee(base: base, monthlyRate: rate, months: lateMonths)
    }

    func grandTotalAmount(settings: ReceiptSettingsStore) -> Double {
        let base = baseDuesAmount()
        if isLateFeeApplied && receiptKind == .income {
            return LateFeeCalculator.grandTotal(base: base, lateFee: calculatedLateFee(settings: settings))
        }
        return base
    }

    func autoDetectOverdueMonths(settings: ReceiptSettingsStore) {
        let calendar = Calendar.current
        let now = Date()
        let comp = calendar.dateComponents([.month], from: receiptDate, to: now)
        let months = comp.month ?? 0
        if months > 0 {
            self.lateMonths = max(1, months)
        } else {
            self.lateMonths = 1
        }
        self.isLateFeeApplied = true
    }

    func importInvoice(from url: URL, settings: ReceiptSettingsStore) {
        isScanningInvoice = true
        invoiceScanBanner = nil

        let savedPath = InvoiceAttachmentManager.shared.saveAttachment(from: url)
        self.attachedInvoicePath = savedPath

        Task {
            let result = await InvoiceOCRParser.parse(fileURL: url, knownVendors: settings.vendors.map { $0.name })
            await MainActor.run {
                self.isScanningInvoice = false
                if let vendor = result.vendorName, !vendor.isEmpty {
                    self.ownerName = vendor
                }
                if let amt = result.amount, amt > 0 {
                    self.totalAmount = String(format: "%.2f", amt)
                }
                if let date = result.invoiceDate {
                    self.receiptDate = date
                }
                if let invNo = result.invoiceNumber, !invNo.isEmpty {
                    let prefix = settings.l10n.invoiceNumberPrefix
                    let newNote = "\(prefix): \(invNo)"
                    if self.notes.isEmpty || self.notes == "-" {
                        self.notes = newNote
                    } else if !self.notes.contains(invNo) {
                        self.notes = "\(newNote) • \(self.notes)"
                    }
                }

                let l10n = settings.l10n
                let vendorStr = result.vendorName ?? l10n.importInvoice
                let amountStr = result.amount != nil ? String(format: "%.2f %@", result.amount!, settings.currency.symbol) : ""
                self.invoiceScanBanner = "\(l10n.invoiceScanSuccess): \(vendorStr) \(amountStr)".trimmingCharacters(in: .whitespaces)
            }
        }
    }

    func removeAttachedInvoice() {
        if let path = attachedInvoicePath {
            InvoiceAttachmentManager.shared.removeAttachment(at: path)
        }
        attachedInvoicePath = nil
        invoiceScanBanner = nil
    }

    func setReceiptKind(_ kind: ReceiptKind, settings: ReceiptSettingsStore) {
        receiptKind = kind
        if kind == .managementExpense {
            selectedApartment = 0
            printApartmentNumber = false
            if ownerName == settings.owner(for: selectedApartment) {
                ownerName = ""
            }
        } else {
            if selectedApartment == 0 {
                selectedApartment = settings.apartmentNumbers.first ?? 1
            }
            printApartmentNumber = true
            if ownerName.isEmpty {
                ownerName = settings.owner(for: selectedApartment)
            }
        }
    }

    func applyPreset(notesText: String, suggestedVendor: String? = nil) {
        notes = notesText
        if let vendor = suggestedVendor, ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ownerName = vendor
        }
    }

    func updateApartment(_ number: Int, settings: ReceiptSettingsStore) {
        selectedApartment = number
        if receiptKind != .managementExpense {
            ownerName = settings.owner(for: number)
        }
    }

    func updateLiveFromSettings(_ settings: ReceiptSettingsStore) {
        issuerName = settings.issuer
        sequenceNumber = String(settings.seqNumber)
        if receiptKind == .income {
            totalAmount = settings.defaultPayment
            ownerName = settings.owner(for: selectedApartment)
        } else if receiptKind == .outcome {
            ownerName = settings.owner(for: selectedApartment)
        }
        if selectedApartment > settings.flatCount {
            selectedApartment = max(1, settings.flatCount)
            if receiptKind != .managementExpense {
                ownerName = settings.owner(for: selectedApartment)
            }
        }
        objectWillChange.send()
    }

    func resetForm(settings: ReceiptSettingsStore) {
        syncWithSettings(settings)
    }

    func createReceipt(settings: ReceiptSettingsStore) {
        let l10n = settings.l10n
        let trimmedIssuer = issuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSequence = sequenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: l10n.errIssuerRequired)
            return
        }
        guard !trimmedOwner.isEmpty else {
            validationError = ValidationError(message: l10n.errReceiverRequired)
            return
        }
        guard let sequence = Int(trimmedSequence), sequence > 0 else {
            validationError = ValidationError(message: l10n.errSequenceInvalid)
            return
        }
        guard let baseAmt = parseAmount(totalAmount), baseAmt >= 0 else {
            validationError = ValidationError(message: l10n.errAmountInvalid)
            return
        }

        let effectiveApartment = receiptKind == .managementExpense ? 0 : selectedApartment
        let effectiveShowApartment = receiptKind == .managementExpense ? false : printApartmentNumber

        let effectiveLateFee = isLateFeeApplied && receiptKind == .income ? calculatedLateFee(settings: settings) : 0.0
        let effectiveGrandTotal = LateFeeCalculator.grandTotal(base: baseAmt, lateFee: effectiveLateFee)
        let effectiveRate = effectiveLateRate(settings: settings)

        let draft = ReceiptDraft(
            receiver: trimmedOwner.localizedCapitalized,
            issuer: trimmedIssuer.localizedCapitalized,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : notes,
            monthYear: receiptDate.monthYearString(locale: settings.currentLocale),
            apartmentNumber: effectiveApartment,
            amount: effectiveGrandTotal,
            sequenceNumber: sequence,
            createdDate: Date().dayMonthYearString(locale: settings.currentLocale),
            showApartmentNumber: effectiveShowApartment,
            kind: receiptKind,
            currency: settings.currency,
            invoiceAttachmentPath: attachedInvoicePath,
            isLateFeeApplied: isLateFeeApplied && receiptKind == .income && effectiveLateFee > 0,
            lateFeeRate: effectiveRate,
            lateMonths: lateMonths,
            lateFeeAmount: effectiveLateFee,
            baseAmount: baseAmt,
            lateFeeFootnote: settings.effectiveLateFeeFootnote()
        )

        previewDraft = draft
        ReceiptArchiveStore.shared.add(draft: draft)

        settings.seqNumber = sequence + 1
        sequenceNumber = String(settings.seqNumber)
    }

    private func parseAmount(_ input: String) -> Double? {
        let normalized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
