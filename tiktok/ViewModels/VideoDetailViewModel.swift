//
//  VideoDetailViewModel.swift
//  tiktok
//
//  Created by gt on 2/7/25.
//

import Foundation
import FirebaseFirestore

class VideoDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Properties
    private let video: Video
    private let db = Firestore.firestore()
    
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
}

