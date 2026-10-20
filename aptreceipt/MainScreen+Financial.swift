import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension MainScreen {
    // 3. Financial & Description Hero Section
    var financialAndNotesHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(l10n.financialDetails, systemImage: "banknote.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                // Hero Amount
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(l10n.amount) (\(settings.currency.symbol))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Text(settings.currency.symbol)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                        TextField("0.00", text: $viewModel.totalAmount)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 1.2)
                    )
                }

                // Sequence No
                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.sequenceNo)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "number.square.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                        TextField("1", text: $viewModel.sequenceNumber)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .frame(width: 120)
            }

            // Description / Notes
            VStack(alignment: .leading, spacing: 3) {
                Text(l10n.notesLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        .padding(.top, 2)
                    TextField(viewModel.receiptKind == .managementExpense ? l10n.customExpenseNotePlaceholder : l10n.notesPlaceholder, text: $viewModel.notes)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }

            // Optional Late Fee Section (Income Only, enabled in Settings)
            if viewModel.receiptKind == .income && settings.isLateFeeEnabled {
                lateFeeHeroCard
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var lateFeeHeroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Toggle(isOn: $viewModel.isLateFeeApplied) {
                    HStack(spacing: 5) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(l10n.lateFeeApplyCheckbox)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.primary)
                        Text(settings.lateFeeCountryProfile.flagEmoji)
                            .font(.system(size: 11))
                    }
                }
                .toggleStyle(.checkbox)

                Spacer()

                if viewModel.isLateFeeApplied {
                    Button {
                        viewModel.autoDetectOverdueMonths(settings: settings)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text(l10n.autoDetectOverdue)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let schedule = viewModel.latePaymentSchedule(settings: settings) {
                let overdueMonths = schedule.lateMonths(paidOn: Date())
                HStack(spacing: 5) {
                    Image(systemName: "calendar.badge.clock")
                    Text(l10n.lateFeeDueInfo(
                        due: AppFormat.longDate(schedule.dueDate, l10n: l10n),
                        graceEnd: schedule.hasGracePeriod ? AppFormat.longDate(schedule.graceEnd, l10n: l10n) : nil
                    ))
                    Text("·")
                    Text(overdueMonths > 0 ? l10n.lateFeeStatusLate(months: overdueMonths) : l10n.lateFeeStatusOnTime)
                        .foregroundColor(overdueMonths > 0 ? .orange : .green)
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            if viewModel.isLateFeeApplied {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        // Months
                        HStack(spacing: 6) {
                            Text(l10n.overdueMonthsCount)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Picker("", selection: $viewModel.lateMonths) {
                                ForEach(1...max(24, viewModel.lateMonths), id: \.self) { m in
                                    Text("\(m) \(m > 1 ? l10n.monthsUnit : l10n.monthUnit)").tag(m)
                                }
                            }
                            .frame(width: 85)
                        }

                        // Rate field (manuel oran düzenlenebilir)
                        HStack(spacing: 4) {
                            Text(l10n.lateFeeMonthlyRateTitle)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("5.0", text: $viewModel.customLateFeeRate)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .frame(width: 45)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(NSColor.textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }

                        Spacer()
                    }

                    // Calculation Breakdown
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(l10n.baseDuesAmount)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                            Text(AppFormat.currency(viewModel.baseDuesAmount(), settings.currency, l10n: l10n))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }

                        Text("+")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(l10n.lateFeeCalculated) (\(AppFormat.percent(viewModel.effectiveLateRate(settings: settings), l10n: l10n, maximumFractionDigits: 2)) × \(viewModel.lateMonths))")
                                .font(.system(size: 9.5))
                                .foregroundColor(.orange)
                            Text("+\(AppFormat.currency(viewModel.calculatedLateFee(settings: settings), settings.currency, l10n: l10n))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(l10n.totalWithLateFee)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                            Text(AppFormat.currency(viewModel.grandTotalAmount(settings: settings), settings.currency, l10n: l10n))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .background(Color(NSColor.textBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    // 4. Action Buttons
    var actionButtons: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                viewModel.resetForm(settings: settings)
            } label: {
                Label(l10n.clearForm, systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Spacer()

            Button {
                viewModel.createReceipt(settings: settings)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.plus")
                    Text(l10n.createReceipt)
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 2)
    }
}
