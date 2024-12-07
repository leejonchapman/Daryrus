import SwiftUI

struct FileListView: View {
    @Binding var files: [URL]
    @Binding var fileURL: URL?
    @Binding var showFileImporter: Bool
    let audioPlayer: AudioPlayer
    let onDelete: (URL) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(files, id: \.self) { file in
                    HStack {
                        Text(file.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Button(action: { onDelete(file) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if audioPlayer.isPlaying {
                            audioPlayer.stopPlayback()
                        }
                        fileURL = file
                        audioPlayer.startPlayback(fileURL: file)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFileImporter = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio, .mp3],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let firstURL = urls.first {
                guard firstURL.startAccessingSecurityScopedResource() else {
                    print("Failed to access security scoped resource for file: \(firstURL)")
                    return
                }
                defer { firstURL.stopAccessingSecurityScopedResource() }

                if !files.contains(firstURL) {
                    files.append(firstURL)
                    saveFiles()
                }
            }
        case .failure(let error):
            print("Failed to import file: \(error.localizedDescription)")
        }
    }

    private func saveFiles() {
        let filePaths = files.map { $0.path }
        UserDefaults.standard.set(filePaths, forKey: "savedFiles")
    }
}
