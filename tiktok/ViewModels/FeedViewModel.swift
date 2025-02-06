//
//  FeedView.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - Feed View Model
@MainActor
class FeedViewModel: ObservableObject {
    // MARK: - Properties
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentVideoIndex = 0
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 5
    private var isLoadingMore = false
    
    // MARK: - Init
    init() {
        // Load initial batch of videos
        Task {
            await fetchVideos()
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetch next batch of videos
    func fetchVideos() async {
        guard !isLoadingMore else { return }
        
        do {
            isLoading = true
            isLoadingMore = true
            error = nil
            
            // Create query
            var query = db.collection("videos")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)
            
            // If we have a last document, start after it
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            // Fetch videos
            let snapshot = try await query.getDocuments()
            
            // Update last document for pagination
            lastDocument = snapshot.documents.last
            
            // Parse videos
            let newVideos = snapshot.documents.compactMap { document -> Video? in
                try? document.data(as: Video.self)
            }
            
            // Append new videos
            if lastDocument == nil {
                // First page, replace all videos
                videos = newVideos
            } else {
                // Subsequent pages, append
                videos.append(contentsOf: newVideos)
            }
            
            print("DEBUG: Fetched \(newVideos.count) videos")
            
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Error fetching videos: \(error.localizedDescription)")
        }
        
        isLoading = false
        isLoadingMore = false
    }
    
    /// Load more videos when reaching near the end
    func loadMoreIfNeeded(currentIndex: Int) {
        // If we're within 2 videos of the end, fetch more
        if currentIndex >= videos.count - 2 {
            Task {
                await fetchVideos()
            }
        }
    }
    
    /// Handle video index change
    func videoDidChange(to index: Int) {
        currentVideoIndex = index
        loadMoreIfNeeded(currentIndex: index)
    }
    
    /// Refresh the feed
    func refresh() async {
        lastDocument = nil  // Reset pagination
        await fetchVideos()
    }
}

