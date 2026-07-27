import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case html, pdf
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .html: return "HTML"
        case .pdf: return "PDF"
        }
    }

    var fileExtension: String {
        rawValue
    }
}
