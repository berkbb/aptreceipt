import Foundation

// MARK: - Number to Words Converter

struct NumberToWords {
    private static let turkishOnes = ["", "Bir", "İki", "Üç", "Dört", "Beş", "Altı", "Yedi", "Sekiz", "Dokuz"]
    private static let turkishTens = ["", "On", "Yirmi", "Otuz", "Kırk", "Elli", "Altmış", "Yetmiş", "Seksen", "Doksan"]

    private static let englishOnes = [
        "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
        "Seventeen", "Eighteen", "Nineteen"
    ]
    private static let englishTens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]

    static func convert(_ amount: Double, language: AppLanguage, currency: AppCurrency = .turkishLira) -> String {
        let cents = max(0, Money.cents(amount))
        let integerPart = cents / 100
        let fractionalPart = cents % 100

        switch language {
        case .turkish:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = "Türk Lirası"
                fracUnit = "Kuruş"
            case .romanianLeu:
                mainUnit = "Rumen Leyi"
                fracUnit = "Bani"
            case .usDollar:
                mainUnit = "Amerikan Doları"
                fracUnit = "Sent"
            case .euro:
                mainUnit = "Euro"
                fracUnit = "Sent"
            case .britishPound:
                mainUnit = "İngiliz Sterlini"
                fracUnit = "Peni"
            }
            let lirasText = integerToTurkishWords(integerPart)
            let kurusText = integerToTurkishWords(fractionalPart)
            let lirasString = lirasText.isEmpty ? "Sıfır \(mainUnit)" : "\(lirasText) \(mainUnit)"
            let kurusString = kurusText.isEmpty ? "Sıfır \(fracUnit)" : "\(kurusText) \(fracUnit)"
            return "\(lirasString) \(kurusString)"

        case .romanian:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = integerPart == 1 ? "Liră Turcească" : "Lire Turcești"
                fracUnit = fractionalPart == 1 ? "Kuruș" : "Kuruși"
            case .romanianLeu:
                mainUnit = integerPart == 1 ? "Leu" : "Lei"
                fracUnit = fractionalPart == 1 ? "Ban" : "Bani"
            case .usDollar:
                mainUnit = integerPart == 1 ? "Dolar SUA" : "Dolari SUA"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cenți"
            case .euro:
                mainUnit = "Euro"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cenți"
            case .britishPound:
                mainUnit = integerPart == 1 ? "Liră Sterlină" : "Lire Sterline"
                fracUnit = fractionalPart == 1 ? "Pence" : "Pence"
            }
            let leiText = integerToRomanianWords(integerPart)
            let baniText = integerToRomanianWords(fractionalPart)
            let leiString = leiText.isEmpty ? "Zero \(mainUnit)" : "\(leiText) \(mainUnit)"
            let baniString = baniText.isEmpty ? "Zero \(fracUnit)" : "\(baniText) \(fracUnit)"
            return "\(leiString) și \(baniString)"

        default:
            let mainUnit: String
            let fracUnit: String
            switch currency {
            case .turkishLira:
                mainUnit = integerPart == 1 ? "Turkish Lira" : "Turkish Liras"
                fracUnit = fractionalPart == 1 ? "Kurus" : "Kurus"
            case .romanianLeu:
                mainUnit = integerPart == 1 ? "Romanian Leu" : "Romanian Lei"
                fracUnit = fractionalPart == 1 ? "Ban" : "Bani"
            case .usDollar:
                mainUnit = integerPart == 1 ? "US Dollar" : "US Dollars"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cents"
            case .euro:
                mainUnit = "Euro"
                fracUnit = fractionalPart == 1 ? "Cent" : "Cents"
            case .britishPound:
                mainUnit = integerPart == 1 ? "British Pound" : "British Pounds"
                fracUnit = fractionalPart == 1 ? "Penny" : "Pence"
            }
            let mainText = integerToEnglishWords(integerPart)
            let fracText = integerToEnglishWords(fractionalPart)
            let mainString = mainText.isEmpty ? "Zero \(mainUnit)" : "\(mainText) \(mainUnit)"
            let fracString = fracText.isEmpty ? "Zero \(fracUnit)" : "\(fracText) \(fracUnit)"
            return "\(mainString) and \(fracString)"
        }
    }

    private static func integerToTurkishWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Eksi " + integerToTurkishWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            result += integerToTurkishWords(millions) + " Milyon "
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            if thousands == 1 {
                result += "Bin "
            } else {
                result += integerToTurkishWords(thousands) + " Bin "
            }
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            if hundreds == 1 {
                result += "Yüz "
            } else {
                result += turkishOnes[hundreds] + " Yüz "
            }
            num %= 100
        }

        let tens = num / 10
        if tens > 0 {
            result += turkishTens[tens] + " "
            num %= 10
        }

        if num > 0 {
            result += turkishOnes[num] + " "
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private static func integerToRomanianWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Minus " + integerToRomanianWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            if millions == 1 {
                result += "Un Milion "
            } else {
                result += integerToRomanianWords(millions) + " Milioane "
            }
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            if thousands == 1 {
                result += "O Mie "
            } else if thousands == 2 {
                result += "Două Mii "
            } else {
                result += integerToRomanianWords(thousands) + " Mii "
            }
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            if hundreds == 1 {
                result += "O Sută "
            } else if hundreds == 2 {
                result += "Două Sute "
            } else {
                let digitFems = ["", "Una", "Două", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
                let digit = (hundreds < digitFems.count) ? digitFems[hundreds] : "\(hundreds)"
                result += digit + " Sute "
            }
            num %= 100
        }

        if num >= 20 {
            let tens = num / 10
            let remainder = num % 10
            let tensNames = ["", "", "Douăzeci", "Treizeci", "Patruzeci", "Cincizeci", "Șaizeci", "Șaptezeci", "Optzeci", "Nouăzeci"]
            let digitMascs = ["", "Unu", "Doi", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
            if remainder > 0 {
                let digit = (remainder < digitMascs.count) ? digitMascs[remainder] : "\(remainder)"
                result += tensNames[tens] + " și " + digit + " "
            } else {
                result += tensNames[tens] + " "
            }
            num = 0
        } else if num >= 10 {
            let teens = [
                "Zece", "Unsprezece", "Doisprezece", "Treisprezece", "Paisprezece",
                "Cincisprezece", "Șaisprezece", "Șaptesprezece", "Optsprezece", "Nouăsprezece"
            ]
            result += teens[num - 10] + " "
            num = 0
        } else if num > 0 {
            let digitMascs = ["", "Unu", "Doi", "Trei", "Patru", "Cinci", "Șase", "Șapte", "Opt", "Nouă"]
            let digit = (num < digitMascs.count) ? digitMascs[num] : "\(num)"
            result += digit + " "
            num = 0
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private static func integerToEnglishWords(_ number: Int) -> String {
        if number == 0 { return "" }
        if number < 0 { return "Minus " + integerToEnglishWords(abs(number)) }

        var result = ""
        var num = number

        let millions = num / 1_000_000
        if millions > 0 {
            result += integerToEnglishWords(millions) + " Million "
            num %= 1_000_000
        }

        let thousands = num / 1_000
        if thousands > 0 {
            result += integerToEnglishWords(thousands) + " Thousand "
            num %= 1_000
        }

        let hundreds = num / 100
        if hundreds > 0 {
            result += englishOnes[hundreds] + " Hundred "
            num %= 100
        }

        if num >= 20 {
            let tens = num / 10
            result += englishTens[tens] + " "
            num %= 10
        }

        if num > 0 && num < 20 {
            result += englishOnes[num] + " "
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
}
