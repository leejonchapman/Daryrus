import SwiftUI

struct FileListView: View {
    @Binding var files: [URL]
    @Binding var fileURL: URL?
    @Binding var showFileImporter: Bool
    @Binding var showSheet: Bool
    let audioPlayer: AudioPlayer
    let onDelete: (URL) -> Void
    let saveFiles: () -> Void // Add saveFiles parameter

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
                    Button(action: {
                        // Close the Library sheet before opening the file importer
                        showSheet = false

                        // Open file importer after a small delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showFileImporter = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func deleteFile(at offsets: IndexSet) {
        offsets.forEach { index in
            let fileToDelete = files[index]
            do {
                try FileManager.default.removeItem(at: fileToDelete)
            } catch {
                print("Failed to delete file: \(error.localizedDescription)")
            }
            files.remove(at: index)
            saveFiles() // Call saveFiles to persist changes
        }
    }
}
