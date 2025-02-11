import Foundation
import AVKit

@MainActor
class VideoPlayerManager: ObservableObject {
    // MARK: - Properties
    private var player: AVPlayer?
    private var loopObserver: NSObjectProtocol?
    private var currentController: AVPlayerViewController?
    private var currentURL: URL?
    
    // MARK: - Init
    init() {
        print("DEBUG: VideoPlayerManager initialized")
    }
    
    deinit {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    func prepareVideo(url: URL, controller: AVPlayerViewController) {
        print("DEBUG: Preparing video for URL: \(url.lastPathComponent)")
        
        // If we're already playing this URL, just ensure it's playing and the controller is updated
        if let currentItem = player?.currentItem,
           let currentAsset = currentItem.asset as? AVURLAsset,
           currentAsset.url == url {
            controller.player = player
            currentController = controller
            player?.play()
            return
        }
        
        // Create new player
        let item = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: item)
            setupLooping()
        } else {
            player?.replaceCurrentItem(with: item)
        }
        
        // Update controller and state
        controller.player = player
        currentController = controller
        currentURL = url
        player?.play()
    }
    
    func pauseCurrentVideo() {
        print("DEBUG: Pausing current video")
        player?.pause()
    }
    
    func resumeCurrentVideo() {
        print("DEBUG: Resuming current video")
        if let url = currentURL, let controller = currentController {
            // Reinitialize the player with the current URL
            print("DEBUG: Reinitializing player for resume")
            prepareVideo(url: url, controller: controller)
        } else {
            player?.play()
        }
    }
    
    // MARK: - Private Methods
    private func setupLooping() {
        // Remove existing observer
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Set up new observer
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("DEBUG: Video reached end, looping")
            Task { @MainActor [weak self] in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
    }
} 