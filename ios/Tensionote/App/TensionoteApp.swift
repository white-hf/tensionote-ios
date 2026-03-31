import SwiftUI

@main
struct TensionoteApp: App {
    @StateObject private var store = InMemoryBloodPressureRepository()
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "system"

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    HomeView(repository: store)
                }
                .tabItem {
                    Label(L10n.tr("tab_home"), systemImage: "heart.text.square")
                }

                NavigationStack {
                    HistoryView(repository: store)
                }
                .tabItem {
                    Label(L10n.tr("tab_history"), systemImage: "clock.arrow.circlepath")
                }

                NavigationStack {
                    ReminderView()
                }
                .tabItem {
                    Label(L10n.tr("tab_reminder"), systemImage: "bell")
                }

                NavigationStack {
                    ReportView(repository: store)
                }
                .tabItem {
                    Label(L10n.tr("tab_report"), systemImage: "doc.text")
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(L10n.tr("tab_settings"), systemImage: "gearshape")
                }
            }
            .environment(\.locale, locale)
        }
    }

    private var locale: Locale {
        selectedLanguageCode == "system" ? .autoupdatingCurrent : Locale(identifier: selectedLanguageCode)
    }
}
