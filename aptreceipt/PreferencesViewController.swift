import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View

@MainActor
struct SettingsView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gearshape.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tercihler & Ayarlar")
                        .font(.system(size: 18, weight: .bold))
                    Text("Apartman bilgileri, varsayılan değerler ve imzanızı düzenleyin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Tab Content
            TabView {
                generalSettingsTab
                    .tabItem {
                        Label("Apartman", systemImage: "building.2.fill")
                    }

                residentsTab
                    .tabItem {
                        Label("Sakinler", systemImage: "person.2.fill")
                    }

                signatureTab
                    .tabItem {
                        Label("İmza", systemImage: "signature")
                    }

                aboutTab
                    .tabItem {
                        Label("Hakkında", systemImage: "info.circle.fill")
                    }
            }
            .padding(16)

            Divider()

            // Footer Buttons
            HStack {
                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Kaydet ve Kapat") {
                    if viewModel.save(to: settings) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .onAppear {
            viewModel.load(from: settings)
        }
        .alert(item: $viewModel.validationError) { issue in
            Alert(
                title: Text("Doğrulama Hatası"),
                message: Text(issue.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    // MARK: - Tab 1: General Settings

    private var generalSettingsTab: some View {
        Form {
            Section {
                TextField("Apartman Adı:", text: $viewModel.apartmentName)
                    .textFieldStyle(.roundedBorder)

                TextField("Varsayılan Yönetici (Tahsil Eden):", text: $viewModel.issuer)
                    .textFieldStyle(.roundedBorder)

                TextField("Toplam Daire Sayısı:", text: $viewModel.flatCount)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Apartman Bilgileri")
                    .font(.headline)
            }

            Section {
                TextField("Varsayılan Aidat / Ödeme Tutarı (₺):", text: $viewModel.defaultPayment)
                    .textFieldStyle(.roundedBorder)

                TextField("Sıradaki Makbuz Numarası:", text: $viewModel.sequenceNumber)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Mali & Makbuz Ayarları")
                    .font(.headline)
            }
        }
        .padding(12)
    }

    // MARK: - Tab 2: Residents Directory

    private var residentsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daire Sakinleri Rehberi")
                .font(.headline)

            Text("Her daire için kayıtlı ev sahibi veya kiracı ismini belirleyin. Makbuz düzenlerken daire seçildiğinde otomatik doldurulacaktır.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Picker("Daire:", selection: $viewModel.selectedApartment) {
                    ForEach(viewModel.availableApartments, id: \.self) { number in
                        Text("Daire \(number)").tag(number)
                    }
                }
                .frame(width: 150)
                .onChange(of: viewModel.selectedApartment) { newValue in
                    viewModel.selectedOwner = settings.owner(for: newValue)
                }

                TextField("Sakin Adı Soyadı", text: $viewModel.selectedOwner)
                    .textFieldStyle(.roundedBorder)

                Button("Kaydet") {
                    settings.saveOwner(viewModel.selectedOwner.localizedCapitalized, apartmentNumber: viewModel.selectedApartment)
                    viewModel.showOwnerSavedFeedback = true
                }
                .buttonStyle(.bordered)
            }

            if viewModel.showOwnerSavedFeedback {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Daire \(viewModel.selectedApartment) sakini başarıyla kaydedildi.")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Tab 3: Signature

    private var signatureTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yetkili İmzası")
                .font(.headline)

            Text("Makbuzların alt kısmında yer alacak imza görselini (PNG veya JPG) yükleyin.")
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 180)

                if let image = settings.signatureImage {
                    VStack(spacing: 8) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 4)

                        Text("Yüklü İmza")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "signature")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Henüz imza yüklenmedi")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    settings.importSignature()
                } label: {
                    Label("İmza Görseli Yükle...", systemImage: "arrow.up.doc.fill")
                }
                .buttonStyle(.borderedProminent)

                if settings.signatureImage != nil {
                    Button(role: .destructive) {
                        settings.clearSignature()
                    } label: {
                        Label("İmzayı Kaldır", systemImage: "trash.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Tab 4: About

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "building.2.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("Apartman Makbuzu")
                    .font(.title2.bold())
                Text("Sürüm 3.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(width: 300)

            VStack(spacing: 6) {
                Text("Yayıncı: **berkbb**")
                    .font(.callout)
                Text("Lisans: **GNU General Public License v3.0 (GPL-3.0)**")
                    .font(.callout)
                Text("Copyright © 2023-2026 berkbb. Tüm hakları saklıdır.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}

// MARK: - Settings View Model

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apartmentName: String = ""
    @Published var issuer: String = ""
    @Published var defaultPayment: String = ""
    @Published var flatCount: String = "1"
    @Published var sequenceNumber: String = "1"

    @Published var selectedApartment: Int = 1
    @Published var selectedOwner: String = ""
    @Published var showOwnerSavedFeedback: Bool = false

    @Published var validationError: ValidationError?

    var availableApartments: [Int] {
        if let count = Int(flatCount), count > 0 {
            return Array(1...count)
        }
        return [1]
    }

    func load(from settings: ReceiptSettingsStore) {
        apartmentName = settings.apartmentName
        issuer = settings.issuer
        defaultPayment = settings.defaultPayment
        flatCount = String(settings.flatCount)
        sequenceNumber = String(settings.seqNumber)
        selectedApartment = settings.apartmentNumbers.first ?? 1
        selectedOwner = settings.owner(for: selectedApartment)
        showOwnerSavedFeedback = false
    }

    func save(to settings: ReceiptSettingsStore) -> Bool {
        let trimmedApartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let flats = Int(flatCount), flats > 0 else {
            validationError = ValidationError(message: "Daire sayısı pozitif bir tam sayı olmalıdır.")
            return false
        }
        guard let sequence = Int(sequenceNumber), sequence > 0 else {
            validationError = ValidationError(message: "Sıra numarası pozitif bir tam sayı olmalıdır.")
            return false
        }
        guard Double(trimmedDefaultPayment.replacingOccurrences(of: ",", with: ".")) != nil else {
            validationError = ValidationError(message: "Varsayılan tutar sayısal olmalıdır.")
            return false
        }
        guard !trimmedApartmentName.isEmpty, !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: "Apartman adı ve varsayılan yönetici boş bırakılamaz.")
            return false
        }

        settings.apartmentName = trimmedApartmentName
        settings.issuer = trimmedIssuer.localizedCapitalized
        settings.defaultPayment = trimmedDefaultPayment
        settings.flatCount = flats
        settings.seqNumber = sequence

        if !selectedOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings.saveOwner(selectedOwner.localizedCapitalized, apartmentNumber: selectedApartment)
        }

        return true
    }
}
