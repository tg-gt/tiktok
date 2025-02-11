//
//  VideoDetailView.swift
//  tiktok
//
//  Created by gt on 2/7/25.
//

import SwiftUI
import AVKit

struct VideoDetailView: View {
    // MARK: - Properties
    let video: Video
    @StateObject private var viewModel: VideoDetailViewModel
    
    // MARK: - Initialization
    init(video: Video) {
        self.video = video
        _viewModel = StateObject(wrappedValue: VideoDetailViewModel(video: video))
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            if let videoURL = URL(string: video.videoUrl ?? "") {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 400)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(video.title ?? "Untitled")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let description = video.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("\(video.likesCount)", systemImage: "heart.fill")
                        .foregroundColor(.red)
                    
                    Label("\(video.commentsCount)", systemImage: "message.fill")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview Provider
struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoDetailView(video: Video(
                id: "test",
                userId: "user1",
                title: "Test Video",
                description: "This is a test video",
                videoUrl: "https://example.com/video.mp4",
                thumbnailUrl: "https://example.com/thumbnail.jpg",
                createdAt: Date()
            ))
        }
    }
}

