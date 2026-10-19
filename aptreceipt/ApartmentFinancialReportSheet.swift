import AppKit
import SwiftUI

// MARK: - Apartment Financial Report & Cash Balance Sheet

struct ApartmentFinancialReportSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @ObservedObject private var archiveStore = ReceiptArchiveStore.shared
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedPeriod: String = "all"
    @State private var selectedTab: Int = 0
    @State private var successNotice: String?

    private var l10n: L10n { settings.l10n }

    private var availablePeriods: [String] {
        let set = Set(archiveStore.records.map { $0.monthYear })
        return Array(set).sorted().reversed()
    }

    private var filteredRecords: [ReceiptRecord] {
        if selectedPeriod == "all" {
            return archiveStore.records
        }
        return archiveStore.records.filter { $0.monthYear == selectedPeriod }
    }

    private var totalIncome: Double {
        filteredRecords.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalRefunds: Double {
        filteredRecords.filter { $0.kind == .outcome }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        filteredRecords.filter { $0.kind == .managementExpense }.reduce(0) { $0 + $1.amount }
    }

    private var netCashBalance: Double {
        totalIncome - totalRefunds - totalExpenses
    }

    private var expenseCategories: [(category: String, amount: Double, percent: Double)] {
        let expenses = filteredRecords.filter { $0.kind == .managementExpense }
        guard !expenses.isEmpty else { return [] }
        var map: [String: Double] = [:]
        for exp in expenses {
            let cat = exp.notes.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespaces) ?? exp.receiver
            let key = (cat.isEmpty || cat == "-") ? exp.receiver : cat
            map[key, default: 0.0] += exp.amount
        }
        let total = totalExpenses > 0 ? totalExpenses : 1.0
        return map.map { (category: $0.key, amount: $0.value, percent: ($0.value / total) * 100.0) }
            .sorted { $0.amount > $1.amount }
    }

    private var flatDuesStatusList: [(flat: Int, owner: String, phone: String, isPaid: Bool, record: ReceiptRecord?)] {
        let periodToMatch = selectedPeriod == "all" ? (availablePeriods.first ?? "") : selectedPeriod
        return settings.apartmentNumbers.map { flat in
            let owner = settings.owner(for: flat)
            let phone = settings.ownerPhone(for: flat)
            let matchingRecord = archiveStore.records.first {
                $0.kind == .income && $0.apartmentNumber == flat && (periodToMatch.isEmpty || $0.monthYear == periodToMatch)
            }
            return (flat: flat, owner: owner, phone: phone, isPaid: matchingRecord != nil, record: matchingRecord)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.financialReportTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.financialReportSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Control Bar (Period Filter & View Selector)
            HStack(spacing: 16) {
                // Period Dropdown
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    Picker("", selection: $selectedPeriod) {
                        Text(l10n.allMonths).tag("all")
                        ForEach(availablePeriods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                    .frame(width: 170)
                }

                Spacer()

                // Tab Switcher
                Picker("", selection: $selectedTab) {
                    Text(l10n.financialSummaryTab).tag(0)
                    Text(l10n.duesTrackingTab).tag(1)
                    Text(l10n.allTransactionsTab).tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            // Active Tab Content
            ScrollView {
                VStack(spacing: 16) {
                    if selectedTab == 0 {
                        summaryTabContent
                    } else if selectedTab == 1 {
                        duesTrackingTabContent
                    } else {
                        transactionsTabContent
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                if let notice = successNotice {
                    Label(notice, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }

                Spacer()

                Button {
                    exportBulletinBoardPDF()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.richtext.fill")
                        Text(l10n.exportBulletinBoardPDF)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 840, idealWidth: 880, minHeight: 600, idealHeight: 660)
        .onAppear {
            if let latest = availablePeriods.first {
                selectedPeriod = latest
            }
        }
    }

    // MARK: - Tab 0: Summary Content
    private var summaryTabContent: some View {
        VStack(spacing: 16) {
            // KPI Balance Cards
            HStack(spacing: 12) {
                kpiCard(title: l10n.totalIncome, amount: totalIncome, color: .green, icon: "arrow.down.left.circle.fill", subtitle: "\(filteredRecords.filter { $0.kind == .income }.count) \(l10n.archiveTitle)")
                kpiCard(title: l10n.totalExpenses, amount: totalExpenses, color: .red, icon: "arrow.up.right.circle.fill", subtitle: "\(filteredRecords.filter { $0.kind == .managementExpense }.count) \(l10n.managementExpenseTitle)")
                kpiCard(title: l10n.netCashBalance, amount: netCashBalance, color: netCashBalance >= 0 ? Color(red: 0.22, green: 0.42, blue: 0.88) : .red, icon: "banknote.fill", subtitle: l10n.commonAreaOperatingBadge)
            }

            // Dues Collection Rate Card
            let paidCount = flatDuesStatusList.filter { $0.isPaid }.count
            let totalFlats = max(1, settings.flatCount)
            let rate = (Double(paidCount) / Double(totalFlats)) * 100.0

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(l10n.duesTrackingTab, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                    Text(String(format: "%%%0.1f \(l10n.paidStatus) (%d / %d)", rate, paidCount, totalFlats))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(rate / 100.0), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Expense Breakdown
            if !expenseCategories.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label(l10n.managementExpenseTitle, systemImage: "briefcase.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                    VStack(spacing: 8) {
                        ForEach(expenseCategories, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.2f %@", item.amount, settings.currency.symbol))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Text(String(format: "(%%%0.1f)", item.percent))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(red: 0.22, green: 0.42, blue: 0.88))
                                        .frame(width: geo.size.width * CGFloat(item.percent / 100.0), height: 5)
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Tab 1: Dues Tracking Content
    private var duesTrackingTabContent: some View {
        VStack(spacing: 8) {
            ForEach(flatDuesStatusList, id: \.flat) { item in
                HStack(spacing: 12) {
                    Text("\(l10n.flatPrefix) \(item.flat)")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 70, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.owner.isEmpty ? "—" : item.owner)
                            .font(.system(size: 12, weight: .semibold))
                        if !item.phone.isEmpty {
                            Text(item.phone)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if item.isPaid {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(l10n.paidStatus)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                            if let rec = item.record {
                                Text("#\(rec.sequenceNumber)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    } else {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.exclamationmark.fill")
                                    .foregroundColor(.orange)
                                Text(l10n.unpaidStatus)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())

                            if settings.isLateFeeEnabled {
                                let defaultAmt = Double(settings.defaultPayment.replacingOccurrences(of: ",", with: ".")) ?? 1750.0
                                let fee = LateFeeCalculator.fee(base: defaultAmt, monthlyRate: settings.lateFeeMonthlyRate, months: 1)
                                Text("+\(String(format: "%.2f", fee)) \(settings.currency.symbol) \(l10n.lateFeeShortBadge)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.08))
                                    .clipShape(Capsule())
                            }

                            Button {
                                sendWhatsAppReminder(flat: item.flat, owner: item.owner, phone: item.phone)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "message.fill")
                                    Text(l10n.remindWhatsApp)
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Tab 2: All Transactions Content
    private var transactionsTabContent: some View {
        VStack(spacing: 8) {
            ForEach(filteredRecords) { r in
                HStack(spacing: 12) {
                    Text("#\(r.sequenceNumber)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(width: 50, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.receiver)
                            .font(.system(size: 12, weight: .bold))
                        Text(r.createdDate + " • " + r.notes)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    let color: Color = r.kind == .income ? .green : (r.kind == .outcome ? .orange : Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(String(format: "%.2f %@", r.amount, r.currency.symbol))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func kpiCard(title: String, amount: Double, color: Color, icon: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Text(String(format: "%.2f %@", amount, settings.currency.symbol))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func sendWhatsAppReminder(flat: Int, owner: String, phone: String) {
        let periodName = selectedPeriod == "all" ? (availablePeriods.first ?? "") : selectedPeriod
        let duesAmt = settings.defaultPayment.isEmpty ? "1750" : settings.defaultPayment
        let duesAmtValue = Double(duesAmt.replacingOccurrences(of: ",", with: ".")) ?? 1750.0
        let currencySym = settings.currency.symbol
        let apt = settings.apartmentName.isEmpty ? l10n.defaultBuildingName : settings.apartmentName
        let manager = settings.issuer.isEmpty ? l10n.managerSignatureTitle : settings.issuer

        let message: String
        if settings.isLateFeeEnabled {
            let lateFeeVal = LateFeeCalculator.fee(base: duesAmtValue, monthlyRate: settings.lateFeeMonthlyRate, months: 1)
            let totalVal = duesAmtValue + lateFeeVal
            let rateStr = String(format: "%.1f", settings.lateFeeMonthlyRate)
            let feeStr = String(format: "%.2f", lateFeeVal)
            let totalStr = String(format: "%.2f", totalVal)
            switch l10n.resolvedLanguage {
            case .turkish:
                message = "Sayın Komşumuz (Daire \(flat)), \(apt) \(periodName) dönemi \(duesAmt) \(currencySym) aidat ve aylık %\(rateStr) gecikme tazminatı (\(feeStr) \(currencySym)) ile birlikte toplam \(totalStr) \(currencySym) ödemeniz henüz kaydımıza geçmemiştir. Bilginize sunar, iyi günler dileriz. - \(manager)"
            case .romanian:
                message = "Stimate Vecin (Ap. \(flat)), plata întreținerii pentru \(periodName) la \(apt) (\(duesAmt) \(currencySym)) plus penalități de întârziere (%\(rateStr): \(feeStr) \(currencySym)), total \(totalStr) \(currencySym) este în așteptare. Vă mulțumim! - \(manager)"
            default:
                message = "Dear Resident (Flat \(flat)), dues for \(periodName) at \(apt) (\(duesAmt) \(currencySym)) plus late fee compensation (%\(rateStr): \(feeStr) \(currencySym)), total \(totalStr) \(currencySym) is currently pending. Thank you! - \(manager)"
            }
        } else {
            switch l10n.resolvedLanguage {
            case .turkish:
                message = "Sayın Komşumuz (Daire \(flat)), \(apt) \(periodName) dönemi \(duesAmt) \(currencySym) aidat ödemeniz henüz kaydımıza geçmemiştir. Bilginize sunar, iyi günler dileriz. - \(manager)"
            case .romanian:
                message = "Stimate Vecin (Ap. \(flat)), plata întreținerii pentru perioada \(periodName) la \(apt) în valoare de \(duesAmt) \(currencySym) este în așteptare. Vă mulțumim! - \(manager)"
            default:
                message = "Dear Resident (Flat \(flat)), dues payment for \(periodName) at \(apt) in the amount of \(duesAmt) \(currencySym) is currently pending. Thank you! - \(manager)"
            }
        }

        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = WhatsAppShareHelper.shareURL(phone: cleanPhone.isEmpty ? nil : cleanPhone, message: message) {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportBulletinBoardPDF() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.pdf]
        let periodStr = selectedPeriod == "all" ? "Genel" : selectedPeriod.replacingOccurrences(of: " ", with: "_")
        let aptStr = sanitizeForFileName(settings.apartmentName.isEmpty ? "Apartman" : settings.apartmentName)
        panel.nameFieldStringValue = "\(aptStr)_Mali_Pano_Raporu_\(periodStr).pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let noticeView = ApartmentBulletinBoardView(
            settings: settings,
            periodTitle: selectedPeriod == "all" ? l10n.allMonths : selectedPeriod,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netBalance: netCashBalance,
            expenseCategories: expenseCategories,
            paidFlatsCount: flatDuesStatusList.filter { $0.isPaid }.count,
            totalFlatsCount: settings.flatCount,
            records: filteredRecords,
            l10n: l10n
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: noticeView)
        renderer.proposedSize = ProposedViewSize(width: 595, height: 842)

        var box = CGRect(origin: .zero, size: CGSize(width: 595, height: 842))
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return
        }

        pdfContext.beginPDFPage(nil)
        renderer.render { size, context in
            context(pdfContext)
        }
        pdfContext.endPDFPage()
        pdfContext.closePDF()

        successNotice = l10n.saveSuccessPDF
    }
}
