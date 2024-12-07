import SwiftUI
import AVFoundation

struct FileListView: View {
    @Binding var files: [URL]
    @Binding var fileURL: URL?
    @Binding var showFileImporter: Bool
    @Binding var showSheet: Bool
    let audioPlayer: AudioPlayer
    let onDelete: (URL) -> Void
    let saveFiles: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(files, id: \.self) { file in
                    FileRowView(
                        file: file,
                        audioPlayer: audioPlayer,
                        fileURL: $fileURL,
                        showSheet: $showSheet
                    )
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
            saveFiles() // Persist changes
        }
    }
}

// MARK: - Subview for Each File
struct FileRowView: View {
    let file: URL
    let audioPlayer: AudioPlayer
    @Binding var fileURL: URL?
    @Binding var showSheet: Bool
    
    @State private var albumArt: Image? = nil
    @State private var trackTitle: String = "Loading..."
    @State private var trackArtist: String = "Loading..."
    
    var body: some View {
        HStack {
            albumArt?
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .clipped()
                .padding(.trailing, 8)
            
            VStack(alignment: .leading) {
                Text(trackTitle)
                    .bold()
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(trackArtist)
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
            
            // Run the async function inside a Task
            Task {
                await audioPlayer.startPlayback(fileURL: file)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showSheet = false
            }
        }

        .task {
            // Load metadata asynchronously
            if let art = await getAlbumArt(from: file) {
                albumArt = art
            } else {
                albumArt = nil
            }
            
            trackTitle = await getTrackTitle(from: file)
            trackArtist = await getTrackArtist(from: file)
        }
    }
    
    // MARK: - Async Metadata Methods
    private func getAlbumArt(from fileURL: URL) async -> Image? {
        let asset = AVURLAsset(url: fileURL)
        guard let metadata = try? await asset.load(.commonMetadata) else {
            return nil
        }
        
        for item in metadata {
            if item.commonKey == .commonKeyArtwork {
                if let data = try? await item.load(.value) as? Data,
                   let uiImage = UIImage(data: data) {
                    return Image(uiImage: uiImage)
                }
            }
        }
        return nil
    }
    
    private func getTrackTitle(from fileURL: URL) async -> String {
        let asset = AVURLAsset(url: fileURL)
        guard let metadata = try? await asset.load(.commonMetadata) else {
            return fileURL.lastPathComponent
        }
        
        if let titleItem = metadata.first(where: { $0.commonKey?.rawValue == "title" }) {
            if let title = try? await titleItem.load(.value) as? String {
                return title
            }
        }
        
        return fileURL.lastPathComponent
    }
    
    private func getTrackArtist(from fileURL: URL) async -> String {
        let asset = AVURLAsset(url: fileURL)
        guard let metadata = try? await asset.load(.commonMetadata) else {
            return "Unknown Artist"
        }
        
        if let artistItem = metadata.first(where: { $0.commonKey?.rawValue == "artist" }) {
            if let artist = try? await artistItem.load(.value) as? String {
                return artist
            }
        }
        
        return "Unknown Artist"
    }
}
