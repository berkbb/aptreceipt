import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension MainScreen {
    // MARK: - Hero Sections (Left Side)

    // 1. Hero Mode Switcher (Income vs Expense vs Management Spending)
    var heroReceiptTypeSelector: some View {
        HStack(spacing: 8) {
            // Income
            modeHeroCard(
                kind: .income,
                title: l10n.incomeTitle,
                subtitle: l10n.incomeBadge,
                icon: "arrow.down.left",
                activeColor: Color.green
            )

            // Resident Refund
            modeHeroCard(
                kind: .outcome,
                title: l10n.outcomeTitle,
                subtitle: l10n.outcomeBadge,
                icon: "arrow.up.right",
                activeColor: Color.orange
            )

            // Management Operating Expense
            modeHeroCard(
                kind: .managementExpense,
                title: l10n.managementExpenseTitle,
                subtitle: l10n.managementExpenseBadge,
                icon: "briefcase.fill",
                activeColor: Color(red: 0.22, green: 0.42, blue: 0.88)
            )
        }
    }

    func modeHeroCard(kind: ReceiptKind, title: String, subtitle: String, icon: String, activeColor: Color) -> some View {
        let isSelected = viewModel.receiptKind == kind
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.setReceiptKind(kind, settings: settings)
            }
        } label: {
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(isSelected ? activeColor : Color.secondary.opacity(0.12))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? activeColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? activeColor.opacity(0.55) : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // 2. Property & Parties Hero Section
    var propertyAndPartiesHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.receiptKind == .managementExpense {
                // Header Row for Management Expense (No flat toggle, dedicated operating badge)
                HStack {
                    Label(l10n.managementExpenseTitle, systemImage: "briefcase.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                    Spacer()

                    // Date Picker
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(l10n.period)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }

                // Operating badge
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                        .font(.system(size: 11))
                    Text(l10n.commonAreaOperatingBadge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7))

                Divider()

                // Invoice / Receipt OCR & Attachment Hero Card
                invoiceImportHeroCard

                // Parties Fields: Vendor (Payee) & Manager (Payer)
                VStack(spacing: 8) {
                    // Vendor / Payee
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(l10n.payeeVendorCardTitle)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()

                            if !viewModel.ownerName.isEmpty {
                                Button(l10n.clearForm) {
                                    viewModel.ownerName = ""
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .buttonStyle(.link)
                            }

                            if !settings.vendors.isEmpty {
                                Menu {
                                    ForEach(settings.vendors) { vendor in
                                        Button {
                                            viewModel.ownerName = vendor.name
                                        } label: {
                                            if vendor.category.isEmpty {
                                                Text(vendor.name)
                                            } else {
                                                Text("\(vendor.name) (\(vendor.category))")
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "list.bullet.rectangle.portrait")
                                        Text(l10n.selectSavedVendor)
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                }
                                .menuStyle(.borderlessButton)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                                .font(.system(size: 12))
                            TextField(l10n.vendorPlaceholder, text: $viewModel.ownerName)
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

                    // Manager / Payer
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.managerPayerLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            TextField(l10n.issuerPlaceholder, text: $viewModel.issuerName)
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

                    // Ready-Made Expense Services Row
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(l10n.quickServicesLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(settings.expenseServices) { service in
                                    Button {
                                        viewModel.applyPreset(notesText: service.defaultDescription, suggestedVendor: service.suggestedVendor)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: service.iconName.isEmpty ? "briefcase.fill" : service.iconName)
                                                .font(.system(size: 9))
                                            Text(service.name)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                // Header Row: Property & Print Flat Toggle
                HStack {
                    Label(l10n.flatAndPeriod, systemImage: "building.2.crop.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Toggle(isOn: $viewModel.printApartmentNumber) {
                        Text(l10n.printFlatNumber)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)
                }

                // Flat & Period Row
                HStack(spacing: 10) {
                    // Flat Selector
                    HStack(spacing: 6) {
                        Image(systemName: "door.left.hand.closed")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 12))
                        Text(l10n.flatNumber)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.selectedApartment) {
                            ForEach(settings.apartmentNumbers, id: \.self) { number in
                                Text("\(l10n.flatPrefix) \(number)").tag(number)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: viewModel.selectedApartment) { newValue in
                            viewModel.updateApartment(newValue, settings: settings)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )

                    Spacer()

                    // Date Picker
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(l10n.period)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $viewModel.receiptDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }

                Divider()

                // Income & Resident Refund Modes
                VStack(spacing: 8) {
                    // Resident / Payer
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(l10n.receiverLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                viewModel.ownerName = settings.owner(for: viewModel.selectedApartment)
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                    Text(l10n.fetchSavedResident)
                                }
                                .font(.system(size: 10, weight: .semibold))
                            }
                            .buttonStyle(.link)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            TextField(l10n.receiverPlaceholder, text: $viewModel.ownerName)
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

                    // Issuer / Collector
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.issuerLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            TextField(l10n.issuerPlaceholder, text: $viewModel.issuerName)
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
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
