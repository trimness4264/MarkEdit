import Foundation

class HTMLExporter {
    static let shared = HTMLExporter()

    func export(html: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(filename).appendingPathExtension("html")

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("HTML export failed: \(error)")
            return nil
        }
    }
}
