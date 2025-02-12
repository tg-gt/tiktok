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
    @State private var player: AVPlayer?
    
    // MARK: - Initialization
    init(video: Video) {
        self.video = video
        _viewModel = StateObject(wrappedValue: VideoDetailViewModel(video: video))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Video Player
            if let url = URL(string: viewModel.swappedVideoUrl ?? viewModel.video.videoUrl ?? "") {
                VideoPlayer(player: AVPlayer(url: url))
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                // Face Swap Button
                Button(action: {
                    viewModel.showFaceSwapPicker = true
                }) {
                    HStack {
                        Image(systemName: "face.smiling")
                        Text("Face Swap")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(25)
                }
                .padding(.bottom, 50)
                .disabled(viewModel.isFaceSwapping)
            }
        }
        .overlay(
            // Loading Overlay
            Group {
                if viewModel.isFaceSwapping {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Creating Face Swap...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                        )
                }
            }
        )
        .sheet(isPresented: $viewModel.showFaceSwapPicker) {
            ImagePicker(selectedImage: $viewModel.selectedFaceImage)
                .onChange(of: viewModel.selectedFaceImage) { _ in
                    if viewModel.selectedFaceImage != nil {
                        viewModel.startFaceSwap()
                        viewModel.showFaceSwapPicker = false
                    }
                }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
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

