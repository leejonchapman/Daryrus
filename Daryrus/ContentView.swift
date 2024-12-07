import SwiftUI

struct ContentView: View {
    @State private var fileURL: URL?
    @ObservedObject private var audioPlayer = AudioPlayer()
    @State private var files: [URL] = []
    @State private var showFileImporter = false
    @State private var showFileList = false
    @State private var showSleepTimerSheet = false
    @State private var sleepTimerDuration: TimeInterval = 0
    @State private var remainingTime: TimeInterval = 0
    @State private var sleepTimer: Timer? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Artwork Display
                if let artwork = audioPlayer.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .cornerRadius(16)
                        .overlay(
                            Text("No Artwork")
                                .foregroundColor(.gray)
                                .font(.caption)
                        )
                        .padding()
                }

                // Track Info
                VStack(spacing: 5) {
                    Text(audioPlayer.trackTitle)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.top, 10)

                    Text(audioPlayer.trackArtist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal)

                // Playback Controls
                VStack {
                    // Slider
                    Slider(
                        value: Binding(
                            get: { audioPlayer.currentTime },
                            set: { newValue in audioPlayer.seek(to: newValue) }
                        ),
                        in: 0...audioPlayer.duration
                    )
                    .accentColor(.blue)
                    .padding([.horizontal, .top])

                    HStack {
                        Text(timeString(from: audioPlayer.currentTime))
                            .font(.footnote)

                        Spacer()

                        Text(timeString(from: audioPlayer.duration - audioPlayer.currentTime))
                            .font(.footnote)
                    }
                    .padding(.horizontal)

                    // Playback and Skip Buttons
                    HStack {
                        Button(action: { audioPlayer.skipBackward() }) {
                            Image(systemName: "gobackward.10")
                                .font(.largeTitle)
                        }

                        Spacer()

                        Button(action: {
                            if audioPlayer.isPlaying {
                                audioPlayer.pausePlayback()
                            } else if let url = fileURL {
                                audioPlayer.startPlayback(fileURL: url)
                            }
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                        }

                        Spacer()

                        Button(action: { audioPlayer.skipForward() }) {
                            Image(systemName: "goforward.10")
                                .font(.largeTitle)
                        }
                    }
                    .padding(.horizontal)
                }

                // Sleep Timer Display
                if sleepTimerDuration > 0 {
                    Text("Time Remaining: \(timeString(from: remainingTime))")
                        .font(.headline)
                        .padding()
                }

                Spacer()

                // Library and Sleep Timer Buttons
                HStack {
                    Button(action: { showFileList = true }) {
                        Text("Library")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showFileList) {
                        FileListView(
                            files: $files,
                            fileURL: $fileURL,
                            showFileImporter: $showFileImporter,
                            audioPlayer: audioPlayer,
                            onDelete: deleteFile
                        )
                    }


                    Button(action: { showSleepTimerSheet = true }) {
                        Text("Sleep Timer")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showSleepTimerSheet) {
                        SleepTimerView(
                            showSheet: $showSleepTimerSheet,
                            sleepTimerDuration: $sleepTimerDuration,
                            startSleepTimer: startSleepTimer,
                            resetSleepTimer: resetSleepTimer
                        )
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Duryrus")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio, .mp3],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onAppear {
                loadFiles()
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

                fileURL = firstURL
                audioPlayer.setupPlayer(fileURL: firstURL)
            }
        case .failure(let error):
            print("Failed to import file: \(error.localizedDescription)")
        }
    }
    
    private func openFileImporter() {
        // Close the Library view first, then open the file picker
        showFileList = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFileImporter = true
        }
    }

    

    private func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startSleepTimer(duration: TimeInterval) {
        sleepTimer?.invalidate()
        remainingTime = duration
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                audioPlayer.pausePlayback()
                sleepTimer?.invalidate()
                sleepTimer = nil
                sleepTimerDuration = 0
            }
        }
    }

    private func resetSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerDuration = 0
        remainingTime = 0
    }

    private func deleteFile(_ url: URL) {
        if let index = files.firstIndex(of: url) {
            files.remove(at: index)
            saveFiles()
        }
    }

    private func saveFiles() {
        let filePaths = files.map { $0.path }
        UserDefaults.standard.set(filePaths, forKey: "savedFiles")
    }

    private func loadFiles() {
        if let savedPaths = UserDefaults.standard.array(forKey: "savedFiles") as? [String] {
            files = savedPaths.compactMap { URL(fileURLWithPath: $0) }
        }
    }
}
