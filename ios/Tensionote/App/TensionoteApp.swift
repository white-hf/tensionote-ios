import OSLog
import SwiftUI

@main
struct TensionoteApp: App {
    @StateObject private var store = InMemoryBloodPressureRepository()
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode = "system"
    @State private var didFinishBootstrap = false
    private let logger = Logger(subsystem: "com.tensionote.app", category: "app")

    var body: some Scene {
        WindowGroup {
            Group {
                if didFinishBootstrap {
                    MainTabView(store: store, locale: locale)
                } else {
                    VStack(spacing: 12) {
                        Text(L10n.tr("app_name"))
                            .font(.title2.weight(.semibold))
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .task {
                        logger.log("Bootstrap screen appeared")
                        didFinishBootstrap = true
                    }
                }
            }
        }
    }

    private var locale: Locale {
        selectedLanguageCode == "system" ? .autoupdatingCurrent : Locale(identifier: selectedLanguageCode)
    }
}

private struct MainTabView: View {
    @ObservedObject var store: InMemoryBloodPressureRepository
    let locale: Locale

    var body: some View {
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
