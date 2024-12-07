import SwiftUI

struct FileListView: View {
    @Binding var files: [URL]
    @Binding var fileURL: URL?
    @Binding var showFileImporter: Bool
    @Binding var showSheet: Bool
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
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if audioPlayer.isPlaying {
                            audioPlayer.stopPlayback()
                        }
                        fileURL = file
                        audioPlayer.startPlayback(fileURL: file)

                        // Delay dismissing the sheet slightly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showSheet = false
                        }
                    }
                }
                .onDelete(perform: deleteFile)
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

    private func deleteFile(at offsets: IndexSet) {
        offsets.forEach { index in
            let fileToDelete = files[index]
            files.remove(at: index) // Remove the file from the array
            onDelete(fileToDelete) // Call the onDelete closure to handle persistence
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
