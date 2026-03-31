import Foundation

enum L10n {
    private static var resolvedLanguageCode: String {
        let selectedLanguageCode = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "system"

        switch selectedLanguageCode {
        case "zh-Hans":
            return "zh-Hans"
        case "en":
            return "en"
        case "hi":
            return "hi"
        default:
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("zh") {
                return "zh-Hans"
            } else if preferred.hasPrefix("hi") {
                return "hi"
            } else {
                return "en"
            }
        }
    }

    static var locale: Locale {
        Locale(identifier: resolvedLanguageCode)
    }

    static func tr(_ key: String) -> String {
        guard
            let path = Bundle.main.path(forResource: resolvedLanguageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: locale, arguments: arguments)
    }
}
