import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - Tab: Vendors & Services

    var vendorsTab: some View {
        Form {
            Section {
                LabeledContent {
                    Text("\(viewModel.vendors.count)")
                } label: {
                    Label(l10n.registeredVendorsBadge, systemImage: "building.2.fill")
                }
                LabeledContent {
                    Text("\(viewModel.expenseServices.count)")
                } label: {
                    Label(l10n.presetServicesBadge, systemImage: "sparkles")
                }

                Button {
                    viewModel.loadSampleVendorsAndServices(for: viewModel.language)
                } label: {
                    Label(l10n.loadSampleVendorsButton, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                if viewModel.showSampleVendorsFeedback {
                    Label(l10n.sampleVendorsLoadedFeedback, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } header: {
                Text(l10n.vendorsTitle)
            } footer: {
                Text(l10n.vendorsSubtitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                TextField(formLabel(l10n.vendorNameField), text: $viewModel.newVendorName)
                TextField(formLabel(l10n.vendorCategoryField), text: $viewModel.newVendorCategory)
                TextField(formLabel(l10n.vendorContactField), text: $viewModel.newVendorContact)
                HStack {
                    Spacer()
                    Button {
                        viewModel.addVendor()
                    } label: {
                        Label(l10n.saveVendorButton, systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newVendorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                searchRow(text: $viewModel.vendorSearchQuery, prompt: l10n.searchVendorsPlaceholder)

                if viewModel.filteredVendors.isEmpty {
                    Text(l10n.noVendorsFound)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.filteredVendors) { vendor in
                        vendorRow(vendor)
                    }
                }
            } header: {
                Text(l10n.vendorListHeader)
            }

            Section {
                TextField(formLabel(l10n.serviceNameField), text: $viewModel.newServiceName)
                TextField(formLabel(l10n.serviceSuggestedVendorField), text: $viewModel.newServiceSuggestedVendor)
                TextField(formLabel(l10n.serviceDescriptionField), text: $viewModel.newServiceDescription)
                HStack {
                    Spacer()
                    Button {
                        viewModel.addExpenseService()
                    } label: {
                        Label(l10n.saveServiceButton, systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.newServiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if viewModel.expenseServices.isEmpty {
                    Text(l10n.noServicesFound)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.expenseServices) { service in
                        serviceRow(service)
                    }
                }
            } header: {
                Text(l10n.serviceListHeader)
            }
        }
        .formStyle(.grouped)
    }

    func searchRow(text: Binding<String>, prompt: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("", text: text, prompt: Text(prompt))
                .textFieldStyle(.plain)
                .labelsHidden()
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func vendorRow(_ vendor: VendorRecord) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "building.2.fill")
                .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.88))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vendor.name)
                        .font(.system(size: 12, weight: .bold))
                    if !vendor.category.isEmpty {
                        Text(vendor.category)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if !vendor.contactInfo.isEmpty {
                    Text(vendor.contactInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                viewModel.deleteVendor(id: vendor.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(l10n.deleteButton)
        }
    }

    func serviceRow(_ service: ExpenseServicePreset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: service.iconName.isEmpty ? "briefcase.fill" : service.iconName)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 12, weight: .bold))
                    if let vendor = service.suggestedVendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text(service.defaultDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                viewModel.deleteExpenseService(id: service.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(l10n.deleteButton)
        }
    }
}
