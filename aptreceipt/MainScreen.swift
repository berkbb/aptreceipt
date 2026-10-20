import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Screen

struct MainScreen: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel = MainScreenViewModel()
    @State private var isInvoiceDropTargeted: Bool = false

    init(settings: ReceiptSettingsStore, initialKind: ReceiptKind = .income, initialVendor: String? = nil, initialNotes: String? = nil) {
        self.settings = settings
        let vm = MainScreenViewModel()
        vm.syncWithSettings(settings)
        if initialKind != .income {
            vm.setReceiptKind(initialKind, settings: settings)
            if let vendor = initialVendor {
                vm.ownerName = vendor
            }
            if let notes = initialNotes {
                vm.notes = notes
            }
        }
        _viewModel = StateObject(wrappedValue: vm)
    }

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            headerBar
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area: Left Form + Right Live Preview
            HSplitView {
                // Left Form (Hero Deck)
                ScrollView {
                    VStack(spacing: 12) {
                        heroReceiptTypeSelector
                        propertyAndPartiesHeroSection
                        financialAndNotesHeroSection
                        actionButtons
                    }
                    .padding(16)
                }
                .frame(minWidth: 440, idealWidth: 500)

                // Right Live Preview
                VStack(spacing: 16) {
                    HStack {
                        Label(l10n.livePreview, systemImage: "eye.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(l10n.printViewBadge)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    ScrollView {
                        LiveReceiptPreview(
                            kind: viewModel.receiptKind,
                            apartmentName: settings.apartmentName,
                            apartmentNumber: viewModel.selectedApartment,
                            showApartmentNumber: viewModel.printApartmentNumber,
                            period: viewModel.receiptDate.monthYearString(locale: settings.currentLocale),
                            issuer: viewModel.issuerName.isEmpty ? "—" : viewModel.issuerName,
                            receiver: viewModel.ownerName.isEmpty ? "—" : viewModel.ownerName,
                            amountString: String(format: "%.2f", viewModel.grandTotalAmount(settings: settings)),
                            sequenceNumber: viewModel.sequenceNumber,
                            notes: viewModel.notes,
                            signatureImage: settings.signatureImage,
                            currency: settings.currency,
                            l10n: l10n,
                            logoImage: settings.logoImage,
                            isLateFeeApplied: viewModel.isLateFeeApplied && viewModel.receiptKind == .income,
                            baseAmount: viewModel.baseDuesAmount(),
                            lateFeeAmount: viewModel.calculatedLateFee(settings: settings),
                            lateFeeRate: viewModel.effectiveLateRate(settings: settings),
                            lateMonths: viewModel.lateMonths
                        )
                        .padding(20)
                    }
                }
                .frame(minWidth: 420, idealWidth: 460)
                .background(Color(NSColor.underPageBackgroundColor).opacity(0.6))
            }
        }
        .onAppear {
            if viewModel.receiptKind == .income && viewModel.ownerName.isEmpty {
                viewModel.syncWithSettings(settings)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidSave)) { _ in
            viewModel.updateLiveFromSettings(settings)
        }
        .onReceive(settings.objectWillChange) { _ in
            DispatchQueue.main.async {
                viewModel.updateLiveFromSettings(settings)
            }
        }
        .sheet(item: $viewModel.previewDraft) { draft in
            ReceiptPreviewSheet(draft: draft, settings: settings)
        }
        .sheet(isPresented: $viewModel.isPresentingArchive) {
            ReceiptArchiveSheet(settings: settings) { selectedDraft in
                viewModel.previewDraft = selectedDraft
            }
            .frame(width: 860, height: 640)
        }
        .sheet(isPresented: $viewModel.isPresentingFinancialReport) {
            ApartmentFinancialReportSheet(settings: settings)
                .frame(width: 880, height: 660)
        }
        .sheet(isPresented: $viewModel.isPresentingBatchDues) {
            BatchDuesGeneratorSheet(settings: settings) {
                viewModel.updateLiveFromSettings(settings)
            }
            .frame(width: 720, height: 580)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            if let logo = settings.logoImage {
                Image(nsImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            } else if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(l10n.appTitle)
                        .font(.system(size: 18, weight: .bold))
                    if !settings.apartmentName.isEmpty {
                        Text(settings.apartmentName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(l10n.appSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Financial Report & Cash Balance Button
            Button {
                viewModel.isPresentingFinancialReport = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Text(l10n.financialSummaryTab)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.financialReportTitle)

            // Batch Dues Button
            Button {
                viewModel.isPresentingBatchDues = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text(l10n.batchDuesTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.batchDuesSubtitle)

            // Archive Button
            Button {
                viewModel.isPresentingArchive = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(l10n.archiveButton)
                        .font(.system(size: 12, weight: .medium))
                    if !ReceiptArchiveStore.shared.records.isEmpty {
                        Text("\(ReceiptArchiveStore.shared.records.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.archiveTitle)

            // Settings Button
            Button {
                openSettingsWindow()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(2)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help(l10n.preferences)
            .accessibilityLabel(l10n.preferences)
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    private func openSettingsWindow() {
        SettingsWindowManager.shared.show(settings: settings)
    }

    // MARK: - Hero Sections (Left Side)

    // 1. Hero Mode Switcher (Income vs Expense vs Management Spending)
    private var heroReceiptTypeSelector: some View {
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

    private func modeHeroCard(kind: ReceiptKind, title: String, subtitle: String, icon: String, activeColor: Color) -> some View {
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
    private var propertyAndPartiesHeroSection: some View {
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

    // Invoice Import Hero Card with Drag & Drop and Apple Vision OCR
    private var invoiceImportHeroCard: some View {
        VStack(spacing: 6) {
            if viewModel.isScanningInvoice {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(l10n.scanningInvoice)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.25), lineWidth: 1)
                )
            } else if let path = viewModel.attachedInvoicePath {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.arrow.up.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(l10n.attachedInvoice)
                                .font(.system(size: 11, weight: .bold))
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let banner = viewModel.invoiceScanBanner {
                            Text(banner)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // View invoice button
                    Button {
                        InvoiceAttachmentManager.shared.openAttachment(at: path)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                            Text(l10n.viewInvoice)
                        }
                        .font(.system(size: 10, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    // Remove invoice button
                    Button {
                        viewModel.removeAttachedInvoice()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(l10n.removeInvoice)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    chooseInvoiceFile()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.importInvoice)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                            Text(l10n.dropInvoiceSubtitle)
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isInvoiceDropTargeted
                        ? Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.15)
                        : Color(red: 0.22, green: 0.42, blue: 0.88).opacity(0.06)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color(red: 0.22, green: 0.42, blue: 0.88).opacity(isInvoiceDropTargeted ? 0.7 : 0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                            )
                    )
                }
                .buttonStyle(.plain)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isInvoiceDropTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let validURL = url {
                            DispatchQueue.main.async {
                                viewModel.importInvoice(from: validURL, settings: settings)
                            }
                        }
                    }
                    return true
                }
            }
        }
    }

    private func chooseInvoiceFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.pdf, .png, .jpeg, .tiff]
        }
        panel.prompt = l10n.importInvoice
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.importInvoice(from: url, settings: settings)
        }
    }

    private func expensePresetChip(title: String, icon: String, text: String) -> some View {
        Button {
            viewModel.applyPreset(notesText: text)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
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

    // 3. Financial & Description Hero Section
    private var financialAndNotesHeroSection: some View {
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

    private var lateFeeHeroCard: some View {
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
    private var actionButtons: some View {
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
