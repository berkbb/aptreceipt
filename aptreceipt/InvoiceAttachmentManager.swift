import AppKit
import PDFKit

// MARK: - Invoice Attachment Storage Manager

final class InvoiceAttachmentManager {
    static let shared = InvoiceAttachmentManager()

    var directoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let invoicesDir = appSupport.appendingPathComponent("aptreceipt/invoices", isDirectory: true)
        try? FileManager.default.createDirectory(at: invoicesDir, withIntermediateDirectories: true)
        return invoicesDir
    }

    func saveAttachment(from sourceURL: URL) -> String? {
        let ext = sourceURL.pathExtension.isEmpty ? "pdf" : sourceURL.pathExtension
        let newFileName = "\(UUID().uuidString).\(ext)"
        let destinationURL = directoryURL.appendingPathComponent(newFileName)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Failed to save invoice attachment: \(error)")
            return nil
        }
    }

    func openAttachment(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.open(fileURL)
        }
    }

    func removeAttachment(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
