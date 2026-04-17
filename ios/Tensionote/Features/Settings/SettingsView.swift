import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "system"
    private let languageOptions: [(code: String, titleKey: String)] = [
        ("system", "settings_language_system"),
        ("zh-Hans", "settings_language_zh"),
        ("en", "settings_language_en"),
        ("hi", "settings_language_hi")
    ]

    var body: some View {
        Form(content: {
            Section(content: {
                ForEach(languageOptions, id: \.code) { option in
                    Button {
                        selectedLanguageCode = option.code
                    } label: {
                        HStack {
                            Text(L10n.tr(option.titleKey))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedLanguageCode == option.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }, header: {
                Text(L10n.tr("settings_language_title"))
            })

            Section(content: {
                NavigationLink(L10n.tr("settings_privacy_policy")) {
                    DocumentView(
                        titleKey: "settings_privacy_policy",
                        bodyKey: "document_privacy_content"
                    )
                }
                NavigationLink(L10n.tr("settings_terms")) {
                    DocumentView(
                        titleKey: "settings_terms",
                        bodyKey: "document_terms_content"
                    )
                }
                NavigationLink(L10n.tr("settings_disclaimer")) {
                    DocumentView(
                        titleKey: "settings_disclaimer",
                        bodyKey: "document_disclaimer_content"
                    )
                }
            }, header: {
                Text(L10n.tr("settings_documents_title"))
            }, footer: {
                Text(L10n.tr("settings_documents_description"))
            })
        })
        .navigationTitle(L10n.tr("tab_settings"))
    }
}
