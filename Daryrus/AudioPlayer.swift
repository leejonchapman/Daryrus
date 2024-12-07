import AVFoundation
import Combine
import UIKit

class AudioPlayer: ObservableObject {
    var player: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var trackTitle: String = "Unknown Title"
    @Published var trackArtist: String = "Unknown Artist"
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
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource for file: \(fileURL)")
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }

            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.enableRate = true
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            currentTime = 0
        } catch {
            print("Failed to set up audio player: \(error.localizedDescription)")
        }
    }

    func startPlayback(fileURL: URL? = nil) {
        if isPlaying { pausePlayback() }
        if let fileURL = fileURL { setupPlayer(fileURL: fileURL) }
        guard let player = player else { return }
        player.enableRate = true
        player.rate = playbackRate
        if player.play() {
            isPlaying = true
            startTimer()
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
