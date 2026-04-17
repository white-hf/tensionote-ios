import MessageUI
import SwiftUI

struct MailComposer: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let attachmentData: Data
    let attachmentFileName: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let attachmentData = self.attachmentData
        let attachmentFileName = self.attachmentFileName
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.addAttachmentData(attachmentData, mimeType: "application/pdf", fileName: attachmentFileName)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
        }
    }
}
