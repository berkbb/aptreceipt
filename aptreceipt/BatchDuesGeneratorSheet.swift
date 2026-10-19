import AppKit
import SwiftUI

// MARK: - Batch Dues Generator Sheet

struct BatchDuesGeneratorSheet: View {
    @ObservedObject var settings: ReceiptSettingsStore
    var onComplete: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    @State private var selectedPeriodDate: Date = Date()
    @State private var startSeq: String = ""
    @State private var duesAmount: String = ""
    @State private var selectedFlats: Set<Int> = []
    @State private var isDone: Bool = false
    @State private var generatedCount: Int = 0

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.batchDuesTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(l10n.batchDuesSubtitle)
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

            if isDone {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    Text("\(generatedCount) \(l10n.batchSuccessMessage)")
                        .font(.system(size: 15, weight: .bold))
                    Button(l10n.close) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                // Form Configuration
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Period
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.period)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $selectedPeriodDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        // Starting Sequence #
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.startSequenceNumber)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("106", text: $startSeq)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }

                        // Dues Amount
                        VStack(alignment: .leading, spacing: 4) {
                            Text(l10n.duesAmountPerFlat)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            TextField("1750", text: $duesAmount)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    Divider()

                    // Flat Selection Checklist Header
                    HStack {
                        Text("\(selectedFlats.count) / \(settings.flatCount) \(l10n.duesPaidCount)")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Button(selectedFlats.count == settings.flatCount ? l10n.deselectAll : l10n.selectAll) {
                            if selectedFlats.count == settings.flatCount {
                                selectedFlats.removeAll()
                            } else {
                                selectedFlats = Set(settings.apartmentNumbers)
                            }
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.link)
                    }
                    .padding(.horizontal, 20)

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(settings.apartmentNumbers, id: \.self) { flat in
                                let isSelected = selectedFlats.contains(flat)
                                let owner = settings.owner(for: flat)
                                HStack {
                                    Button {
                                        if isSelected {
                                            selectedFlats.remove(flat)
                                        } else {
                                            selectedFlats.insert(flat)
                                        }
                                    } label: {
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(l10n.flatPrefix) \(flat)")
                                        .font(.system(size: 12, weight: .bold))
                                        .frame(width: 70, alignment: .leading)

                                    Text(owner.isEmpty ? "—" : owner)
                                        .font(.system(size: 12))
                                        .foregroundColor(owner.isEmpty ? .secondary : .primary)

                                    Spacer()

                                    Text("\(duesAmount) \(settings.currency.symbol)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Divider()

                // Footer
                HStack {
                    Button(l10n.cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button {
                        executeBatchGeneration()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text("\(selectedFlats.count) \(l10n.generateBatchReceipts)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFlats.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(minWidth: 640, idealWidth: 700, minHeight: 520, idealHeight: 580)
        .onAppear {
            startSeq = String(settings.seqNumber)
            duesAmount = settings.defaultPayment
            selectedFlats = Set(settings.apartmentNumbers)
        }
    }

    private func executeBatchGeneration() {
        guard let initialSeq = Int(startSeq), let amount = Double(duesAmount.replacingOccurrences(of: ",", with: ".")), amount >= 0 else {
            return
        }

        var currentSeq = initialSeq
        let sortedFlats = Array(selectedFlats).sorted()
        let periodStr = selectedPeriodDate.monthYearString(locale: settings.currentLocale)
        let dateStr = Date().dayMonthYearString(locale: settings.currentLocale)

        for flat in sortedFlats {
            let owner = settings.owner(for: flat)
            let receiverName = owner.isEmpty ? "\(settings.apartmentName) Sakini (Daire \(flat))" : owner

            let draft = ReceiptDraft(
                receiver: receiverName,
                issuer: settings.issuer,
                notes: "\(periodStr) dönemi bina ortak gider ve aidat payı",
                monthYear: periodStr,
                apartmentNumber: flat,
                amount: amount,
                sequenceNumber: currentSeq,
                createdDate: dateStr,
                showApartmentNumber: true,
                kind: .income,
                currency: settings.currency
            )

            ReceiptArchiveStore.shared.add(draft: draft)
            currentSeq += 1
        }

        settings.seqNumber = currentSeq
        generatedCount = sortedFlats.count
        isDone = true
        onComplete()
    }
}
