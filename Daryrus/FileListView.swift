import SwiftUI

struct FileListView: View {
    @Binding var files: [URL]
    @Binding var fileURL: URL?
    @Binding var showFileImporter: Bool
    let audioPlayer: AudioPlayer
    let onDelete: (URL) -> Void

    var body: some View {
        List {
            ForEach(files, id: \.self) { file in
                HStack {
                    Text(file.lastPathComponent)
                    Spacer()
                    Button(action: { onDelete(file) }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}
