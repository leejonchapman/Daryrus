import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio, UTType.mp3])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FilePickerView

        init(_ parent: FilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let firstURL = urls.first {
                // Attempt to access the security-scoped resource
                guard firstURL.startAccessingSecurityScopedResource() else {
                    print("Failed to access security scoped resource for file: \(firstURL)")
                    return
                }
                
                // Store the selected file URL
                parent.selectedFileURL = firstURL
            }
        }


    }
}
