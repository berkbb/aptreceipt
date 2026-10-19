import AppKit
import SwiftUI

// MARK: - Receipt Archive Sheet

struct ReceiptArchiveSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @ObservedObject var archiveStore = ReceiptArchiveStore.shared
    @Environment(\.presentationMode) private var presentationMode
    var onSelectDraft: (ReceiptDraft) -> Void

    @State private var searchQuery: String = ""
    @State private var selectedFilter: String = "all"

    private var l10n: L10n { settings.l10n }

    private var filteredRecords: [ReceiptRecord] {
        archiveStore.records.filter { rec in
            // Filter by type
            if selectedFilter == "income" && rec.kind != .income { return false }
            if selectedFilter == "outcome" && rec.kind != .outcome { return false }
            if selectedFilter == "management" && rec.kind != .managementExpense { return false }

            // Filter by query
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            let q = searchQuery.lowercased()
            return rec.receiver.lowercased().contains(q)
                || rec.notes.lowercased().contains(q)
                || "\(rec.sequenceNumber)".contains(q)
                || "\(rec.apartmentNumber)".contains(q)
                || rec.monthYear.lowercased().contains(q)
        }
    }

    private var totalFilteredAmount: Double {
        filteredRecords.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 16))
                        Text(l10n.archiveTitle)
                            .font(.headline)
                    }
                    Text(l10n.archiveSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    exportArchiveCSV()
                } label: {
                    Label(l10n.exportCSV, systemImage: "arrow.down.doc.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(filteredRecords.isEmpty)

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

            // Filter & Search Deck
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // Search field
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        TextField(l10n.archiveSearchPlaceholder, text: $searchQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )

                    // Type filter picker
                    Picker("", selection: $selectedFilter) {
                        Text(l10n.filterAll).tag("all")
                        Text(l10n.filterIncome).tag("income")
                        Text(l10n.filterOutcome).tag("outcome")
                        Text(l10n.filterManagement).tag("management")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 380)
                }

                // Stats Bar
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.secondary)
                        Text("\(filteredRecords.count) \(l10n.totalArchived)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                    Spacer()

                    Text(String(format: "%.2f %@", totalFilteredAmount, settings.currency.symbol))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // List of Receipts
            if filteredRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(l10n.archiveEmpty)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredRecords) { record in
                            archiveRecordRow(record)
                        }
                    }
                    .padding(20)
                }
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button(l10n.close) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 800, idealWidth: 860, minHeight: 560, idealHeight: 640)
    }

    private func archiveRecordRow(_ record: ReceiptRecord) -> some View {
        let badgeColor: Color = {
            switch record.kind {
            case .income: return .green
            case .outcome: return .orange
            case .managementExpense: return Color(red: 0.22, green: 0.42, blue: 0.88)
            }
        }()

        return HStack(spacing: 12) {
            // Sequence & Kind Badge
            VStack(spacing: 2) {
                Text("#\(record.sequenceNumber)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(badgeColor)
                Text(record.kind.badgeTitle(l10n: l10n))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .lineLimit(1)
            }
            .frame(width: 86)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(record.receiver)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    if record.showApartmentNumber && record.apartmentNumber > 0 {
                        Text("\(l10n.flatPrefix) \(record.apartmentNumber)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Label(record.createdDate, systemImage: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    if !record.notes.isEmpty && record.notes != "-" {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(record.notes)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Amount
            Text(String(format: "%.2f %@", record.amount, record.currency.symbol))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(badgeColor)
                .frame(width: 130, alignment: .trailing)

            // Actions
            HStack(spacing: 6) {
                // Open Receipt Button
                Button {
                    let draft = record.toDraft()
                    presentationMode.wrappedValue.dismiss()
                    onSelectDraft(draft)
                } label: {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .help(l10n.openReceipt)

                // WhatsApp Share Button
                Button {
                    shareViaWhatsApp(record)
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderless)
                .help(l10n.shareWhatsApp)

                // View Attached Invoice Button (If Available)
                if let path = record.invoiceAttachmentPath, !path.isEmpty {
                    Button {
                        InvoiceAttachmentManager.shared.openAttachment(at: path)
                    } label: {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    }
                    .buttonStyle(.borderless)
                    .help(l10n.viewAttachedInvoice)
                }

                // Delete Button
                Button {
                    archiveStore.remove(id: record.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.borderless)
                .help(l10n.deleteReceipt)
            }
        }
        .padding(10)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func shareViaWhatsApp(_ record: ReceiptRecord) {
        let phone = record.apartmentNumber > 0 ? settings.ownerPhone(for: record.apartmentNumber) : nil
        let msg = WhatsAppShareHelper.receiptSummary(draft: record.toDraft(), buildingName: settings.apartmentName, l10n: l10n)
        if let url = WhatsAppShareHelper.shareURL(phone: phone, message: msg) {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportArchiveCSV() {
        var csv = "Sequence,Kind,Receiver,Apartment,Period,Date,Amount,Currency,Notes,Issuer\n"
        for r in filteredRecords {
            let row = [
                "\(r.sequenceNumber)",
                "\"\(r.kind.rawValue)\"",
                "\"\(r.receiver)\"",
                "\(r.apartmentNumber)",
                "\"\(r.monthYear)\"",
                "\"\(r.createdDate)\"",
                String(format: "%.2f", r.amount),
                "\"\(r.currency.rawValue)\"",
                "\"\(r.notes.replacingOccurrences(of: "\"", with: "\"\""))\"",
                "\"\(r.issuer)\""
            ].joined(separator: ",")
            csv.append(row + "\n")
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "AptReceipt_Archive_\(Date().dayMonthYearString(locale: settings.currentLocale)).csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
