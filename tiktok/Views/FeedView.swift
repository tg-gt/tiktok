//
//  ContentView.swift
//  tiktok
//
//  Created by gt on 2/3/25.
//

import SwiftUI
import AVKit

// MARK: - Feed View
struct FeedView: View {
    // MARK: - Properties
    @EnvironmentObject private var playerManager: VideoPlayerManager
    @StateObject private var viewModel: FeedViewModel
    @State private var selectedIndex = 0
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Init
    init() {
        // Create FeedViewModel with a temporary manager
        // The actual playerManager will be injected via environmentObject
        let tempManager = VideoPlayerManager()
        _viewModel = StateObject(wrappedValue: FeedViewModel(playerManager: tempManager))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedIndex) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                    VideoCardView(video: video, isCurrentVideo: index == selectedIndex, viewModel: viewModel)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: selectedIndex) { oldValue, newValue in
                print("DEBUG: Swiped from index \(oldValue) to \(newValue)")
                viewModel.playVideo(at: newValue)
            }
            .onAppear {
                print("DEBUG: FeedView appeared")
                // Update the viewModel's playerManager with the one from environment
                viewModel.updatePlayerManager(playerManager)
                Task {
                    await viewModel.refresh()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                print("DEBUG: Scene phase changed from \(oldPhase) to \(newPhase)")
                if newPhase != .active {
                    viewModel.pauseCurrentVideo()
                }
            }
        }
        .overlay(alignment: .center) {
            if viewModel.isLoading && viewModel.videos.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .overlay(alignment: .top) {
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .background(Color.black)
        .sheet(isPresented: $viewModel.showComments) {
            if let videoId = viewModel.selectedVideoId {
                CommentView(
                    videoId: videoId,
                    onCommentAdded: {
                        Task {
                            await viewModel.refreshVideo(videoId: videoId)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Video Card View
struct VideoCardView: View {
    // MARK: - Properties
    let video: Video
    let isCurrentVideo: Bool
    @ObservedObject var viewModel: FeedViewModel
    @State private var isLiked = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video Player
            if let videoUrlString = video.videoUrl,
               let videoUrl = URL(string: videoUrlString) {
                VideoPlayerView(url: videoUrl, isCurrentVideo: isCurrentVideo, viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Fallback view when video URL is invalid
                Rectangle()
                    .fill(Color.black)
                    .overlay {
                        Text("Video Unavailable")
                            .foregroundColor(.white)
                    }
            }
            
            // Overlay Content
            VStack(alignment: .leading, spacing: 10) {
                // Title and Description
                Text(video.title ?? "Untitled")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Category Tag
                if let categories = video.category, !categories.isEmpty {
                    let categoryText = categories.joined(separator: ", ")
                    if !categoryText.isEmpty {
                        Text(categoryText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 50)
            
            // Engagement Buttons
            VStack(spacing: 20) {
                // Like Button
                Button(action: {
                    if let id = video.id {
                        Task {
                            await viewModel.toggleVideoLike(videoId: id)
                            isLiked = await viewModel.checkIfVideoLiked(videoId: id)
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                            .font(.system(size: 30))
                        Text(video.formattedLikes)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                // Comment Button
                Button(action: {
                    if let id = video.id {
                        viewModel.showCommentsForVideo(videoId: id)
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 30))
                        Text(video.formattedComments)
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 50)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .background(Color.black)
        .onAppear {
            if let id = video.id {
                Task {
                    isLiked = await viewModel.checkIfVideoLiked(videoId: id)
                }
            }
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    let isCurrentVideo: Bool
    @ObservedObject var viewModel: FeedViewModel
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        print("DEBUG: Creating player view for URL: \(url.lastPathComponent)")
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        
        if isCurrentVideo {
            viewModel.prepareVideo(url: url, controller: controller)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isCurrentVideo {
            // If the player is nil or has no current item, we need to reinitialize
            if uiViewController.player == nil || uiViewController.player?.currentItem == nil {
                print("DEBUG: Reinitializing player for URL: \(url.lastPathComponent)")
                viewModel.prepareVideo(url: url, controller: uiViewController)
            } else {
                print("DEBUG: Updating existing player for URL: \(url.lastPathComponent)")
                viewModel.prepareVideo(url: url, controller: uiViewController)
            }
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        print("DEBUG: Dismantling player view")
        uiViewController.player = nil
    }
}

// MARK: - Preview Provider
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
