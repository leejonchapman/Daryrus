import SwiftUI
import AVFoundation

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
                        // Album art
                        getAlbumArt(from: file)?
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            .clipped()
                            .padding(.trailing, 8)

                        // Title and artist
                        VStack(alignment: .leading) {
                            Text(getTrackTitle(from: file))
                                .bold()
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text(getTrackArtist(from: file))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
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

   // Helper method to extract album art
    private func getAlbumArt(from fileURL: URL) -> Image? {
        let asset = AVAsset(url: fileURL)
        for metadata in asset.commonMetadata {
            if metadata.commonKey == .commonKeyArtwork,
               let data = metadata.value as? Data,
               let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        }
        return nil // Return nil if no artwork is found
    }

    // Helper methods to extract MP3 metadata
    private func getTrackTitle(from fileURL: URL) -> String {
        let asset = AVAsset(url: fileURL)
        let metadata = asset.commonMetadata
        if let titleMetadata = metadata.first(where: { $0.commonKey?.rawValue == "title" }),
           let title = titleMetadata.value as? String {
            return title
        }
        return fileURL.lastPathComponent // Fallback to file name if no title is found
    }

    private func getTrackArtist(from fileURL: URL) -> String {
        let asset = AVAsset(url: fileURL)
        let metadata = asset.commonMetadata
        if let artistMetadata = metadata.first(where: { $0.commonKey?.rawValue == "artist" }),
           let artist = artistMe tadata.value as? String {
            return artist
        }
        return "Unknown Artist" // Fallback if no artist is found
    }
}
