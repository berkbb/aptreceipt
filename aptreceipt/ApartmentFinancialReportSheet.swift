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

    /// Period key of a receipt: "2026-10" when the month is recognized, otherwise the raw text.
    private func periodKey(_ monthYear: String) -> String {
        ReceiptPeriod(monthYear: monthYear)?.id ?? "raw:\(monthYear)"
    }

    /// Picker title in the current language; unrecognized period texts are shown as stored.
    private func periodTitle(_ key: String) -> String {
        if key.hasPrefix("raw:") { return String(key.dropFirst(4)) }
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return key }
        return ReceiptPeriod(year: parts[0], month: parts[1]).title(locale: l10n.locale)
    }

    /// One entry per month, newest first, regardless of the language a receipt was created in.
    private var availablePeriods: [String] {
        var recognized = Set<ReceiptPeriod>()
        var raw = Set<String>()
        for record in archiveStore.records {
            if let period = ReceiptPeriod(monthYear: record.monthYear) {
                recognized.insert(period)
            } else {
                raw.insert("raw:\(record.monthYear)")
            }
        }
        return recognized.sorted(by: >).map(\.id) + raw.sorted()
    }

    private var filteredRecords: [ReceiptRecord] {
        if selectedPeriod == "all" {
            return archiveStore.records
        }
        return archiveStore.records.filter { periodKey($0.monthYear) == selectedPeriod }
    }

    private var totalIncome: Double {
        Money.sum(filteredRecords.filter { $0.kind == .income }.map(\.amount))
    }

    private var totalRefunds: Double {
        Money.sum(filteredRecords.filter { $0.kind == .outcome }.map(\.amount))
    }

    private var totalExpenses: Double {
        Money.sum(filteredRecords.filter { $0.kind == .managementExpense }.map(\.amount))
    }

    private var netCashBalance: Double {
        Money.double(Money.rounded(Money.decimal(totalIncome) - Money.decimal(totalRefunds) - Money.decimal(totalExpenses)))
    }

    private var expenseCategories: [(category: String, amount: Double, percent: Double)] {
        let expenses = filteredRecords.filter { $0.kind == .managementExpense }
        guard !expenses.isEmpty else { return [] }
        var amounts: [String: [Double]] = [:]
        for exp in expenses {
            let cat = exp.notes.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespaces) ?? exp.receiver
            let key = (cat.isEmpty || cat == "-") ? exp.receiver : cat
            amounts[key, default: []].append(exp.amount)
        }
        let map = amounts.mapValues(Money.sum)
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
                $0.kind == .income && $0.apartmentNumber == flat && (periodToMatch.isEmpty || periodKey($0.monthYear) == periodToMatch)
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
                            Text(periodTitle(period)).tag(period)
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
                    Text("\(AppFormat.percent(rate, l10n: l10n)) \(l10n.paidStatus) (\(paidCount) / \(totalFlats))")
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
                                Text(AppFormat.currency(item.amount, settings.currency, l10n: l10n))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Text("(\(AppFormat.percent(item.percent, l10n: l10n)))")
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
                                Text("+\(AppFormat.currency(fee, settings.currency, l10n: l10n)) \(l10n.lateFeeShortBadge)")
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
                    Text(AppFormat.currency(r.amount, r.currency, l10n: l10n))
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
            Text(AppFormat.currency(amount, settings.currency, l10n: l10n))
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
        let periodName = periodTitle(selectedPeriod == "all" ? (availablePeriods.first ?? "") : selectedPeriod)
        let dues = Double(settings.defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
        let message = WhatsAppShareHelper.paymentReminder(
            flat: flat,
            owner: owner,
            period: periodName,
            dues: dues,
            currency: settings.currency,
            lateFeeRate: settings.isLateFeeEnabled ? settings.lateFeeMonthlyRate : nil,
            buildingName: settings.apartmentName.isEmpty ? l10n.defaultBuildingName : settings.apartmentName,
            manager: settings.issuer.isEmpty ? l10n.managerSignatureTitle : settings.issuer,
            l10n: l10n
        )
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let callingCode = WhatsAppShareHelper.defaultCallingCode(for: settings.currency)
        if let url = WhatsAppShareHelper.shareURL(phone: cleanPhone.isEmpty ? nil : cleanPhone, message: message, callingCode: callingCode) {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportBulletinBoardPDF() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.allowedContentTypes = [.pdf]
        let periodStr = (selectedPeriod == "all" ? l10n.allMonths : periodTitle(selectedPeriod)).replacingOccurrences(of: " ", with: "_")
        let aptStr = sanitizeForFileName(settings.apartmentName.isEmpty ? l10n.defaultBuildingName : settings.apartmentName)
        panel.nameFieldStringValue = "\(l10n.bulletinPdfFileName(building: aptStr, period: periodStr)).pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let noticeView = ApartmentBulletinBoardView(
            settings: settings,
            periodTitle: selectedPeriod == "all" ? l10n.allMonths : periodTitle(selectedPeriod),
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
