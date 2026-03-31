import SwiftUI

struct DocumentView: View {
    let titleKey: String
    let bodyKey: String

    var body: some View {
        ScrollView {
            Text(L10n.tr(bodyKey))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .textSelection(.enabled)
        }
        .navigationTitle(L10n.tr(titleKey))
    }
}
