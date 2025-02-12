//
//  VideoDetailViewModel.swift
//  tiktok
//
//  Created by gt on 2/7/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions
import SwiftUI

@MainActor
class VideoDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var video: Video
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var showFaceSwapPicker = false
    @Published var selectedFaceImage: UIImage?
    @Published var isFaceSwapping = false
    @Published var swappedVideoUrl: String?
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    // MARK: - Initialization
    init(video: Video) {
        self.video = video
        print("DEBUG: VideoDetailViewModel initialized with video: \(video.id ?? "")")
    }
    
    // MARK: - Methods
    func loadData() {
        isLoading = true
        print("DEBUG: Loading video details")
        
        // Add any additional data loading logic here
        
        isLoading = false
    }
    
    // MARK: - Face Swap Functions
    
    /// Uploads a face image to Firebase Storage
    private func uploadFaceImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FaceSwapError", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let path = "face-images/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child(path)
        
        _ = try await storageRef.putDataAsync(imageData, metadata: nil)
        return try await storageRef.downloadURL().absoluteString
    }
    
    /// Performs face swap operation using Cloud Function
    private func performFaceSwap(sourceVideoUrl: String, faceImageUrl: String) async throws -> (String, String) {
        let data: [String: Any] = [
            "sourceVideoUrl": sourceVideoUrl,
            "faceImageUrl": faceImageUrl
        ]
        
        let result = try await functions.httpsCallable("generateFaceSwap").call(data)
        guard let response = result.data as? [String: Any],
              let videoUrl = response["videoUrl"] as? String,
              let videoId = response["videoId"] as? String else {
            throw NSError(domain: "FaceSwapError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return (videoUrl, videoId)
    }
    
    /// Starts the face swap process
    func startFaceSwap() {
        guard let image = selectedFaceImage else { return }
        guard let sourceVideoUrl = video.videoUrl else {
            error = NSError(domain: "FaceSwapError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Source video URL is missing"])
            showError = true
            return
        }
        
        Task {
            do {
                isFaceSwapping = true
                defer { isFaceSwapping = false }
                
                // 1. Upload face image
                let faceImageUrl = try await uploadFaceImage(image)
                
                // 2. Start face swap
                let (videoUrl, _) = try await performFaceSwap(
                    sourceVideoUrl: sourceVideoUrl,
                    faceImageUrl: faceImageUrl
                )
                
                // 3. Update UI with new video
                swappedVideoUrl = videoUrl
                
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }
}

