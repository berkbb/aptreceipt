import Foundation

// MARK: - Language Default Sample Data

struct SampleData {
    let apartmentName: String
    let issuer: String
    let defaultPayment: String
    let flatCount: Int
    let currency: AppCurrency
    let residents: [Int: String]
    let sampleNotes: String
    let defaultVendors: [VendorRecord]
    let defaultServices: [ExpenseServicePreset]

    static func defaults(for language: AppLanguage) -> SampleData {
        switch language {
        case .turkish:
            return SampleData(
                apartmentName: "Güleryüz Apartmanı",
                issuer: "Ahmet Yılmaz",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .turkishLira,
                residents: [
                    1: "Mehmet Kaya",
                    2: "Ayşe Demir",
                    3: "Mustafa Çelik",
                    4: "Fatma Şahin",
                    5: "Ali Öztürk",
                    6: "Zeynep Arslan",
                    7: "Emre Koç",
                    8: "Hatice Aydın",
                    9: "Burak Doğan",
                    10: "Elif Yıldız",
                    11: "Serkan Şimşek",
                    12: "Gamze Kurt"
                ],
                sampleNotes: "2026 Ekim ayı aidatı ve asansör periyodik bakım gider payı",
                defaultVendors: [
                    VendorRecord(name: "Kaya Asansör Ltd. Şti.", category: "Asansör Bakımı", contactInfo: "0312 444 01 23"),
                    VendorRecord(name: "Pırıl Temizlik Hizmetleri", category: "Temizlik & Sarf", contactInfo: "0532 111 22 33"),
                    VendorRecord(name: "Başkent Ortak Elektrik A.Ş.", category: "Ortak Elektrik", contactInfo: "Abone No: 98412"),
                    VendorRecord(name: "Usta Tesisat & Onarım (Ahmet Usta)", category: "Tesisat & Onarım", contactInfo: "0555 987 65 43"),
                    VendorRecord(name: "Yeşil Vadi Peyzaj & Bahçe", category: "Bahçe & Peyzaj", contactInfo: "0312 321 00 11")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Asansör Bakımı", defaultDescription: "2026 periyodik bina asansörü bakım, yağlama ve kontrol bedeli", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Kaya Asansör Ltd. Şti."),
                    ExpenseServicePreset(name: "Temizlik & Malzeme", defaultDescription: "Bina ortak alan temizliği ve hijyen sarf malzeme bedeli", iconName: "sparkles", suggestedVendor: "Pırıl Temizlik Hizmetleri"),
                    ExpenseServicePreset(name: "Ortak Elektrik / Su", defaultDescription: "Merdiven otomatiği, hidrofor ve çevre aydınlatma ortak elektrik gideri", iconName: "bolt.fill", suggestedVendor: "Başkent Ortak Elektrik A.Ş."),
                    ExpenseServicePreset(name: "Tesisat & Onarım", defaultDescription: "Bina ortak su tesisatı, çatı izolasyonu ve onarım işçiliği", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Usta Tesisat & Onarım (Ahmet Usta)"),
                    ExpenseServicePreset(name: "Bahçe & Peyzaj", defaultDescription: "Site çevre düzenlemesi, bahçe çim biçme ve budama hizmeti", iconName: "leaf.fill", suggestedVendor: "Yeşil Vadi Peyzaj & Bahçe")
                ]
            )
        case .romanian:
            return SampleData(
                apartmentName: "Asociația Parcul Tineretului",
                issuer: "Andrei Popescu",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .romanianLeu,
                residents: [
                    1: "Elena Radu",
                    2: "Ion Ionescu",
                    3: "Maria Dumitrescu",
                    4: "Mihai Stan",
                    5: "Alexandru Georgescu",
                    6: "Andreea Ilie",
                    7: "Cristian Vasile",
                    8: "Ana Marin",
                    9: "Florin Tudor",
                    10: "Gabriela Dobre",
                    11: "Dan Barbu",
                    12: "Simona Nistor"
                ],
                sampleNotes: "Cotă întreținere octombrie 2026 și fond reparații ascensor",
                defaultVendors: [
                    VendorRecord(name: "Ascensor Servicii SRL", category: "Întreținere Lift", contactInfo: "021 334 55 66"),
                    VendorRecord(name: "Curățenie Totală SRL", category: "Curățenie & Consumabile", contactInfo: "0722 111 222"),
                    VendorRecord(name: "Enel Energie Muntenia SA", category: "Energie Electrică", contactInfo: "Cod Client: 88412"),
                    VendorRecord(name: "Instalații Sanitare (Ion Meșter)", category: "Instalații & Reparații", contactInfo: "0744 987 654"),
                    VendorRecord(name: "Spații Verzi & Grădinărit SRL", category: "Peisagistică", contactInfo: "021 456 78 90")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Întreținere Lift", defaultDescription: "Revizie tehnică lunară, gresare și verificare periodică ascensor", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Ascensor Servicii SRL"),
                    ExpenseServicePreset(name: "Curățenie Spații Comune", defaultDescription: "Servicii de curățenie scară bloc și produse igienico-sanitare", iconName: "sparkles", suggestedVendor: "Curățenie Totală SRL"),
                    ExpenseServicePreset(name: "Energie Electrică Spații Comune", defaultDescription: "Factură energie electrică iluminat casa scării și hidrofor", iconName: "bolt.fill", suggestedVendor: "Enel Energie Muntenia SA"),
                    ExpenseServicePreset(name: "Reparații & Instalații", defaultDescription: "Lucrări de reparații instalații sanitare comune și hidroizolație", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Instalații Sanitare (Ion Meșter)"),
                    ExpenseServicePreset(name: "Întreținere Spații Verzi", defaultDescription: "Tuns gazon, toaletare arbuști și curățenie curte bloc", iconName: "leaf.fill", suggestedVendor: "Spații Verzi & Grădinărit SRL")
                ]
            )
        case .english, .system:
            return SampleData(
                apartmentName: "Sunshine Residence",
                issuer: "John Doe",
                defaultPayment: "1750",
                flatCount: 12,
                currency: .usDollar,
                residents: [
                    1: "Jane Smith",
                    2: "Robert Johnson",
                    3: "Emily Davis",
                    4: "Michael Brown",
                    5: "Sarah Wilson",
                    6: "David Miller",
                    7: "Jessica Taylor",
                    8: "James Anderson",
                    9: "Laura Thomas",
                    10: "Daniel Martinez",
                    11: "Olivia White",
                    12: "Matthew Harris"
                ],
                sampleNotes: "October 2026 monthly dues and elevator maintenance fee",
                defaultVendors: [
                    VendorRecord(name: "Apex Elevator Services Inc.", category: "Elevator Maintenance", contactInfo: "+1 (555) 019-2834"),
                    VendorRecord(name: "CleanPro Facilities LLC", category: "Janitorial & Supplies", contactInfo: "+1 (555) 014-9988"),
                    VendorRecord(name: "City Power & Utilities Co.", category: "Common Utilities", contactInfo: "Acct: #94018"),
                    VendorRecord(name: "Mastercraft Plumbing & Repairs", category: "Repairs & Maintenance", contactInfo: "+1 (555) 018-7722"),
                    VendorRecord(name: "GreenThumb Grounds & Landscaping", category: "Grounds & Lawn", contactInfo: "+1 (555) 012-3344")
                ],
                defaultServices: [
                    ExpenseServicePreset(name: "Elevator Maintenance", defaultDescription: "Monthly periodic elevator safety inspection, lubrication, and service", iconName: "arrow.up.and.down.circle.fill", suggestedVendor: "Apex Elevator Services Inc."),
                    ExpenseServicePreset(name: "Janitorial & Supplies", defaultDescription: "Common area janitorial cleaning services and hygiene supplies", iconName: "sparkles", suggestedVendor: "CleanPro Facilities LLC"),
                    ExpenseServicePreset(name: "Common Utilities & Power", defaultDescription: "Common stairwell lighting, water booster pump, and outdoor electric bill", iconName: "bolt.fill", suggestedVendor: "City Power & Utilities Co."),
                    ExpenseServicePreset(name: "Facility Repairs & Plumbing", defaultDescription: "Facility maintenance, emergency plumbing, and common repairs labor", iconName: "wrench.and.screwdriver.fill", suggestedVendor: "Mastercraft Plumbing & Repairs"),
                    ExpenseServicePreset(name: "Grounds & Landscaping", defaultDescription: "Garden upkeep, lawn mowing, and exterior landscaping service", iconName: "leaf.fill", suggestedVendor: "GreenThumb Grounds & Landscaping")
                ]
            )
        }
    }
}
