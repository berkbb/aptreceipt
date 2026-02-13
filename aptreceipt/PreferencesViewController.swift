import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ReceiptSettingsStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var apartmentName = ""
    @State private var issuer = ""
    @State private var defaultPayment = ""
    @State private var flatCount = "1"
    @State private var sequenceNumber = "1"

    @State private var selectedApartment = 1
    @State private var selectedOwner = ""

    @State private var validationError: ValidationError?

    var body: some View {
        VStack(spacing: 14) {
            Text("Tercihler")
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            TabView {
                Form {
                    TextField("Apartman Adı", text: $apartmentName)
                    TextField("Varsayılan Tahsil Eden", text: $issuer)
                    TextField("Varsayılan Tutar", text: $defaultPayment)
                    TextField("Daire Sayısı", text: $flatCount)
                    TextField("Sıra No", text: $sequenceNumber)

                    HStack {
                        Picker("Daire", selection: $selectedApartment) {
                            ForEach(availableApartments, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        TextField("Daire Sakini", text: $selectedOwner)
                        Button("Kaydet") {
                            settings.saveOwner(selectedOwner.localizedCapitalized, apartmentNumber: selectedApartment)
                        }
                    }
                }
                .tabItem {
                    Text("Apartman")
                }

                VStack(alignment: .leading, spacing: 14) {
                    if let image = settings.signatureImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Button("İmza Yükle") {
                            settings.importSignature()
                        }

                        Button("İmzayı Temizle") {
                            settings.clearSignature()
                        }
                    }

                    if settings.signatureImage != nil {
                        Text("İmza yüklendi")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
                .tabItem {
                    Text("İmza")
                }
            }

            HStack {
                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Kaydet") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .onAppear {
            loadFromStore()
        }
        .onChange(of: selectedApartment) { apartment in
            selectedOwner = settings.owner(for: apartment)
        }
        .alert(item: $validationError) { issue in
            Alert(
                title: Text("Doğrulama Hatası"),
                message: Text(issue.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    private var availableApartments: [Int] {
        if let count = Int(flatCount), count > 0 {
            return Array(1...count)
        }
        return [1]
    }

    private func loadFromStore() {
        apartmentName = settings.apartmentName
        issuer = settings.issuer
        defaultPayment = settings.defaultPayment
        flatCount = String(settings.flatCount)
        sequenceNumber = String(settings.seqNumber)
        selectedApartment = settings.apartmentNumbers.first ?? 1
        selectedOwner = settings.owner(for: selectedApartment)
    }

    private func saveSettings() {
        let trimmedApartmentName = apartmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDefaultPayment = defaultPayment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let flats = Int(flatCount), flats > 0 else {
            validationError = ValidationError(message: "Daire sayısı pozitif tam sayı olmalıdır.")
            return
        }
        guard let sequence = Int(sequenceNumber), sequence > 0 else {
            validationError = ValidationError(message: "Sıra numarası pozitif tam sayı olmalıdır.")
            return
        }
        guard Double(trimmedDefaultPayment.replacingOccurrences(of: ",", with: ".")) != nil else {
            validationError = ValidationError(message: "Varsayılan tutar sayısal olmalıdır.")
            return
        }
        guard !trimmedApartmentName.isEmpty, !trimmedIssuer.isEmpty else {
            validationError = ValidationError(message: "Apartman adı ve tahsil eden boş bırakılamaz.")
            return
        }

        settings.apartmentName = trimmedApartmentName
        settings.issuer = trimmedIssuer.localizedCapitalized
        settings.defaultPayment = trimmedDefaultPayment
        settings.flatCount = flats
        settings.seqNumber = sequence
        settings.saveOwner(selectedOwner.localizedCapitalized, apartmentNumber: selectedApartment)

        presentationMode.wrappedValue.dismiss()
    }
}
