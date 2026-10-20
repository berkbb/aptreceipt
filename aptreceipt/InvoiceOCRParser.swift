import AppKit
@preconcurrency import Vision
import PDFKit

// MARK: - Parsed Invoice Result

struct ParsedInvoiceResult {
    var vendorName: String?
    var amount: Double?
    var invoiceDate: Date?
    var invoiceNumber: String?
    var rawText: String = ""
}

// MARK: - Invoice OCR Parser (Apple Vision & PDFKit)

final class InvoiceOCRParser {

    static func parse(fileURL: URL, knownVendors: [String] = []) async -> ParsedInvoiceResult {
        let ext = fileURL.pathExtension.lowercased()
        var fullText = ""

        if ext == "pdf" {
            fullText = await extractTextFromPDF(url: fileURL)
        } else {
            fullText = await extractTextFromImage(url: fileURL)
        }

        return analyzeText(fullText, knownVendors: knownVendors)
    }

    private static func extractTextFromPDF(url: URL) async -> String {
        guard let doc = PDFDocument(url: url) else { return "" }
        var aggregated = ""

        for i in 0..<min(doc.pageCount, 3) {
            guard let page = doc.page(at: i) else { continue }
            if let str = page.string, str.trimmingCharacters(in: .whitespacesAndNewlines).count > 40 {
                aggregated += str + "\n"
            } else {
                let pageBounds = page.bounds(for: .mediaBox)
                let renderer = page.thumbnail(of: CGSize(width: max(pageBounds.width, 1200), height: max(pageBounds.height, 1600)), for: .mediaBox)
                if let cgImage = renderer.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let pageText = await recognizeTextInCGImage(cgImage)
                    aggregated += pageText + "\n"
                }
            }
        }

        return aggregated
    }

    private static func extractTextFromImage(url: URL) async -> String {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }
        return await recognizeTextInCGImage(cgImage)
    }

    private static func recognizeTextInCGImage(_ cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(macOS 13.0, *) {
                request.recognitionLanguages = ["tr-TR", "en-US", "ro-RO"]
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }

    static func analyzeText(_ rawText: String, knownVendors: [String]) -> ParsedInvoiceResult {
        var result = ParsedInvoiceResult(rawText: rawText)
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // 1. Match known vendors first
        for vendor in knownVendors {
            let lowerVendor = vendor.lowercased()
            if rawText.lowercased().contains(lowerVendor) {
                result.vendorName = vendor
                break
            }
        }

        // Company indicators
        if result.vendorName == nil {
            let companyIndicators = [
                "A.Ş", "A.S.", "LTD", "ŞTİ", "STI", "TİC", "TIC", "SAN",
                "S.R.L", "SRL", "INC", "LLC", "LIMITED", "ANONIM", "ANONİM",
                "HİZMETLERİ", "HIZMETLERI", "SERVİSİ", "SERVISI", "ONARIM", "BAKIM",
                "ELEKTRİK", "ELEKTRIK", "ASANSÖR", "ASANSOR", "YÖNETİM", "TEMİZLİK"
            ]

            for line in lines.prefix(15) {
                let upperLine = line.uppercased()
                if companyIndicators.contains(where: { upperLine.contains($0) }) {
                    let cleaned = line.replacingOccurrences(of: #"(?i)vergi no.*"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"(?i)vkn.*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.count >= 4 && cleaned.count <= 60 {
                        result.vendorName = cleaned
                        break
                    }
                }
            }

            if result.vendorName == nil {
                let ignoreKeywords = ["FATURA", "E-FATURA", "E-ARŞİV", "INVOICE", "FACTURA", "RECEIPT", "SAYIN", "TARİH", "DATE"]
                for line in lines.prefix(6) {
                    let upper = line.uppercased()
                    if !ignoreKeywords.contains(where: { upper.contains($0) }) && line.count >= 5 && line.count <= 50 {
                        result.vendorName = line
                        break
                    }
                }
            }
        }

        // 2. Extract Amount
        let totalKeywords = [
            "TOPLAM", "GENEL TOPLAM", "ÖDENECEK", "ODENECEK", "TUTAR", "KDV DAHİL",
            "KDV DAHIL", "VERGİLER DAHİL", "FİŞ TUTARI", "FATURA TUTARI", "ARA TOPLAM",
            "TOTAL", "GRAND TOTAL", "AMOUNT DUE", "TOTAL DUE", "SUMA", "TOTAL DE PLATA"
        ]

        var foundAmount: Double? = nil
        var highestCandidate: Double = 0.0

        for (idx, line) in lines.enumerated() {
            let upper = line.uppercased()
            let hasTotalKeyword = totalKeywords.contains { upper.contains($0) }
            let extractedNumbers = extractNumbers(from: line)

            if hasTotalKeyword {
                if let lastNum = extractedNumbers.last, lastNum > 0 {
                    foundAmount = lastNum
                    break
                }
                if extractedNumbers.isEmpty && idx + 1 < lines.count {
                    let nextNumbers = extractNumbers(from: lines[idx + 1])
                    if let firstNum = nextNumbers.first, firstNum > 0 {
                        foundAmount = firstNum
                        break
                    }
                }
            }

            for num in extractedNumbers {
                if num > highestCandidate && num < 10_000_000.0 {
                    highestCandidate = num
                }
            }
        }

        result.amount = foundAmount ?? (highestCandidate > 0 ? highestCandidate : nil)

        // 3. Extract Date
        let datePatterns = [
            #"\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{4})\b"#,
            #"\b(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})\b"#
        ]

        let dateKeywords = ["TARİH", "TARIH", "DÜZENLEME", "DATE", "DATA"]
        for line in lines {
            let upper = line.uppercased()
            let isDateLine = dateKeywords.contains { upper.contains($0) }

            for pattern in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let nsString = line as NSString
                    let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
                    if let match = matches.first {
                        let dateStr = nsString.substring(with: match.range)
                        if let parsed = parseDateString(dateStr) {
                            result.invoiceDate = parsed
                            break
                        }
                    }
                }
            }
            if result.invoiceDate != nil && isDateLine {
                break
            }
        }

        // 4. Extract Invoice / Receipt Number
        let invPatterns = [
            #"(?i)(?:fatura|fiş|belge|invoice|factura)\s*(?:no|numarası|nr|number|#)?\s*[:.\-]?\s*([A-Za-z0-9\-]{6,20})"#,
            #"\b([A-Z]{3}20\d{10,13})\b"#
        ]

        for pattern in invPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsString = rawText as NSString
                if let match = regex.firstMatch(in: rawText, range: NSRange(location: 0, length: nsString.length)) {
                    if match.numberOfRanges > 1 {
                        let codeRange = match.range(at: 1)
                        if codeRange.location != NSNotFound {
                            result.invoiceNumber = nsString.substring(with: codeRange)
                            break
                        }
                    }
                }
            }
        }

        return result
    }

    private static func extractNumbers(from text: String) -> [Double] {
        var results: [Double] = []
        let pattern = #"[0-9]{1,3}(?:[.,\s][0-9]{3})*(?:[.,][0-9]{2})|[0-9]+(?:[.,][0-9]{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return results }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            var raw = nsString.substring(with: match.range)
            raw = raw.replacingOccurrences(of: " ", with: "")

            if raw.contains(".") && raw.contains(",") {
                let lastDot = raw.lastIndex(of: ".")!
                let lastComma = raw.lastIndex(of: ",")!
                if lastComma > lastDot {
                    raw = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                } else {
                    raw = raw.replacingOccurrences(of: ",", with: "")
                }
            } else if raw.contains(",") {
                raw = raw.replacingOccurrences(of: ",", with: ".")
            }

            if let d = Double(raw), d > 0 {
                results.append(d)
            }
        }

        return results
    }

    private static func parseDateString(_ str: String) -> Date? {
        let formats = ["dd.MM.yyyy", "dd/MM/yyyy", "dd-MM-yyyy", "yyyy-MM-dd", "yyyy.MM.dd"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}
