import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Screen

struct MainScreen: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject var viewModel = MainScreenViewModel()
    @State var isInvoiceDropTargeted: Bool = false
    @ObservedObject var registry = BuildingRegistry.shared
    @State var isAddingBuilding = false
    @State var newBuildingName = ""
    @State var confirmsBuildingDelete = false

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

    var l10n: L10n { settings.l10n }

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
        .onReceive(settings.$apartmentName) { _ in
            registry.refresh()
        }
        .alert(l10n.buildingAddTitle, isPresented: $isAddingBuilding) {
            TextField(l10n.buildingNewNamePlaceholder, text: $newBuildingName)
            Button(l10n.buildingAddConfirm) { addBuilding() }
                .disabled(newBuildingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button(l10n.cancel, role: .cancel) { newBuildingName = "" }
        } message: {
            Text(l10n.buildingAddMessage)
        }
        .confirmationDialog(l10n.buildingDeleteTitle(buildingTitle(settings.apartmentName)), isPresented: $confirmsBuildingDelete, titleVisibility: .visible) {
            Button(l10n.buildingDeleteConfirm, role: .destructive) { deleteActiveBuilding() }
            Button(l10n.cancel, role: .cancel) {}
        } message: {
            Text(l10n.buildingDeleteMessage)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text(l10n.validationErrorTitle),
                message: Text(issue.message),
                dismissButton: .default(Text(l10n.okButton))
            )
        }
    }
}
