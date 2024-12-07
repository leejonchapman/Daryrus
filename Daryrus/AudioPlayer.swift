import AVFoundation
import Combine
import UIKit

class AudioPlayer: ObservableObject {
    var player: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var trackTitle: String = "Title"
    @Published var trackArtist: String = "Artist"
    @Published var artwork: UIImage? = nil

    private var timer: Timer?

    init() {
        configureAudioSession()
    }
    
    func skipBackward() {
        guard let player = player else { return }
        player.currentTime -= 10
        if player.currentTime < 0 {
            player.currentTime = 0
        }
        currentTime = player.currentTime
    }

    func skipForward() {
        guard let player = player else { return }
        player.currentTime += 10
        if player.currentTime > player.duration {
            player.currentTime = player.duration
        }
        currentTime = player.currentTime
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("Audio session configured successfully for background playback.")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        player.currentTime = time
        currentTime = time
    }


    func setupPlayer(fileURL: URL) {
        do {
            // Files in the app's sandbox do not require security-scoped access
            if !fileURL.path.starts(with: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path) {
                guard fileURL.startAccessingSecurityScopedResource() else {
                    print("Failed to access security scoped resource for file: \(fileURL)")
                    return
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }
            }

            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.enableRate = true
            player?.prepareToPlay()
            duration = player?.duration ?? 0

            // Fetch metadata
            extractMetadata(from: fileURL)
        } catch {
            print("Failed to set up audio player: \(error.localizedDescription)")
        }
    }

    private func extractMetadata(from fileURL: URL) {
        let asset = AVAsset(url: fileURL)
        let metadata = asset.commonMetadata

        // Extract title
        if let titleItem = metadata.first(where: { $0.commonKey?.rawValue == "title" }),
           let title = titleItem.value as? String {
            self.trackTitle = title
        } else {
            self.trackTitle = "Unknown Title"
        }

        // Extract artist
        if let artistItem = metadata.first(where: { $0.commonKey?.rawValue == "artist" }),
           let artist = artistItem.value as? String {
            self.trackArtist = artist
        } else {
            self.trackArtist = "Unknown Artist"
        }

        // Extract artwork
        if let artworkItem = metadata.first(where: { $0.commonKey?.rawValue == "artwork" }),
           let data = artworkItem.value as? Data,
           let image = UIImage(data: data) {
            self.artwork = image
        } else {
            self.artwork = nil
        }

        print("Metadata extracted - Title: \(trackTitle), Artist: \(trackArtist)")
    }




    func startPlayback(fileURL: URL? = nil) {
        // If a new file URL is provided, set up a new player
        if let fileURL = fileURL {
            if player == nil || player?.url != fileURL {
                setupPlayer(fileURL: fileURL)
            }
        }

        // Resume playback from the current position
        guard let player = player else { return }
        player.enableRate = true
        player.rate = playbackRate
        if player.play() {
            isPlaying = true
            startTimer()
            print("Playback started from time: \(player.currentTime)")
        }
    }


    func pausePlayback() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func stopPlayback() {
        player?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
