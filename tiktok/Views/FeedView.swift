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
    @StateObject private var viewModel = FeedViewModel()
    @State private var player: AVPlayer?
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $viewModel.currentVideoIndex) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                    VideoCardView(video: video, player: player)
                        .rotationEffect(.degrees(0)) // Fixes a SwiftUI TabView bug
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: viewModel.currentVideoIndex) { oldIndex, newIndex in
                viewModel.videoDidChange(to: newIndex)
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
    }
}

// MARK: - Video Card View
struct VideoCardView: View {
    // MARK: - Properties
    let video: Video
    let player: AVPlayer?
    @State private var isLiked = false
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video Player
            VideoPlayerView(url: URL(string: video.videoUrl)!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Overlay Content
            VStack(alignment: .leading, spacing: 10) {
                // Title and Description
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Category Tag
                if let categories = video.category, !categories.isEmpty {
                    Text(categories.joined(separator: ", "))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 50)
            
            // Engagement Buttons
            VStack(spacing: 20) {
                // Like Button
                Button(action: { isLiked.toggle() }) {
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
                Button(action: {}) {
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
    }
}

// MARK: - Video Player View
struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        player.play()
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - Preview Provider
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
