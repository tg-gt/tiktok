//
//  VideoDetailView.swift
//  tiktok
//
//  Created by gt on 2/7/25.
//

import SwiftUI
import AVKit
import FirebaseFunctions

struct VideoDetailView: View {
    // MARK: - Properties
    let video: Video
    @StateObject private var viewModel: VideoDetailViewModel
    @State private var showingFaceImagePicker = false
    @State private var selectedFaceImage: UIImage?
    @State private var isProcessingFaceSwap = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
            
            // Face Swap Button
            if video.isAIGenerated != true {  // Show for all videos except AI-generated ones
                Button(action: {
                    showingFaceImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "face.dashed")
                        Text("Face Swap")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isProcessingFaceSwap)
            }
            
            // Processing indicator
            if isProcessingFaceSwap {
                ProgressView("Processing Face Swap...")
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFaceImagePicker) {
            ImagePicker(image: $selectedFaceImage, sourceType: .photoLibrary)
                .onDisappear {
                    if let image = selectedFaceImage {
                        uploadFaceImageAndGenerateSwap(image)
                    }
                }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func uploadFaceImageAndGenerateSwap(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            showError = true
            return
        }
        
        isProcessingFaceSwap = true
        
        // First upload the face image
        Task {
            do {
                // Upload face image to Firebase Storage
                let faceImageUrl = try await FirebaseService.shared.uploadImage(imageData, path: "face-images")
                
                // Call the face swap Cloud Function
                let functions = Functions.functions()
                let data: [String: Any] = [
                    "sourceVideoId": video.id ?? "",
                    "faceImageUrl": faceImageUrl
                ]
                
                let result = try await functions.httpsCallable("generateFaceSwap").call(data)
                
                if let response = result.data as? [String: Any],
                   let success = response["success"] as? Bool,
                   success {
                    print("Face swap generation started successfully")
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
                }
                
                DispatchQueue.main.async {
                    isProcessingFaceSwap = false
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessingFaceSwap = false
                    errorMessage = "Failed to generate face swap: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
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

