import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import AVKit

// MARK: - UploadView
struct UploadView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var error: String?
    @State private var showError = false
    @State private var title = ""
    @State private var description = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Video Preview
                    if let url = selectedVideoURL {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 400)
                    } else {
                        videoPickerButton
                    }
                    
                    // Video Details Form
                    if selectedVideoURL != nil {
                        videoDetailsForm
                    }
                }
                .padding()
            }
            .navigationTitle("Upload Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedVideoURL != nil {
                        Button("Upload") {
                            Task {
                                await uploadVideo()
                            }
                        }
                        .disabled(isUploading || title.isEmpty)
                    }
                }
            }
            .overlay {
                if isUploading {
                    uploadingOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "Unknown error occurred")
            }
        }
    }
    
    // MARK: - Video Picker Button
    private var videoPickerButton: some View {
        PhotosPicker(selection: $selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()) {
            VStack(spacing: 12) {
                Image(systemName: "video.badge.plus")
                    .font(.largeTitle)
                Text("Select Video")
                    .font(.headline)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue {
                loadTransferable(from: newValue)
            }
        }
    }
    
    // MARK: - Video Details Form
    private var videoDetailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextField("Description (optional)", text: $description)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Uploading Overlay
    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Uploading... \(Int(uploadProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 150)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        print("DEBUG: Starting to load video from photo picker")
        
        Task {
            do {
                guard let videoData = try await imageSelection.loadTransferable(type: Data.self) else {
                    print("DEBUG: Failed to load video data")
                    throw URLError(.badServerResponse)
                }
                
                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                try videoData.write(to: tempURL)
                
                // Update UI on main thread
                await MainActor.run {
                    self.selectedVideoURL = tempURL
                    print("DEBUG: Successfully loaded video to temp URL: \(tempURL)")
                }
            } catch {
                print("DEBUG: Error loading video: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = "Failed to load video: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    private func uploadVideo() async {
        guard let videoURL = selectedVideoURL else { return }
        
        isUploading = true
        print("DEBUG: Starting video upload")
        
        do {
            // 1. Upload to Storage
            let fileName = "\(UUID().uuidString).mov"
            let storageRef = Storage.storage().reference().child("videos/\(fileName)")
            
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = "video/quicktime"
            
            // Upload with progress monitoring
            let _ = try await storageRef.putFileAsync(from: videoURL, metadata: metadata) { progress in
                if let progress = progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    self.uploadProgress = percentComplete
                    print("DEBUG: Upload progress: \(Int(percentComplete * 100))%")
                }
            }
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            print("DEBUG: Video uploaded successfully. URL: \(downloadURL)")
            
            // 2. Create Firestore document
            let db = Firestore.firestore()
            let videoData: [String: Any] = [
                "userId": Auth.auth().currentUser?.uid ?? "",
                "title": title,
                "description": description,
                "videoUrl": downloadURL.absoluteString,
                "createdAt": Timestamp(),
                "likesCount": 0,
                "commentsCount": 0
            ]
            
            try await db.collection("videos").addDocument(data: videoData)
            print("DEBUG: Firestore document created successfully")
            
            // 3. Dismiss view
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            print("DEBUG: Upload error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.showError = true
                self.isUploading = false
            }
        }
    }
}

// MARK: - Preview Provider
struct UploadView_Previews: PreviewProvider {
    static var previews: some View {
        UploadView()
    }
} 