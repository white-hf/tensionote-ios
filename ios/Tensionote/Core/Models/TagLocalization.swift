import Foundation

enum TagLocalization {
    static func localizedLabels(for tags: [String]) -> String {
        tags.map(L10n.tr).joined(separator: ", ")
    }
}
