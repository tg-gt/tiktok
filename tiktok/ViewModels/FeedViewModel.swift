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
        print("DEBUG: FeedViewModel initialized")
        // Load initial batch of videos
        Task {
            await fetchVideos()
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetch next batch of videos
    func fetchVideos() async {
        guard !isLoadingMore else {
            print("DEBUG: Already loading more videos, skipping fetch")
            return
        }
        
        do {
            isLoading = true
            isLoadingMore = true
            error = nil
            
            print("DEBUG: Starting to fetch videos. Current count: \(videos.count)")
            
            // Create query
            var query = db.collection("videos")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)
            
            // If we have a last document, start after it
            if let lastDocument = lastDocument {
                query = query.start(afterDocument: lastDocument)
                print("DEBUG: Fetching next page after document: \(lastDocument.documentID)")
            } else {
                print("DEBUG: Fetching first page of videos")
            }
            
            // Fetch videos
            let snapshot = try await query.getDocuments()
            print("DEBUG: Fetched \(snapshot.documents.count) documents from Firestore")
            
            // Parse videos from Firestore
            let newVideos = snapshot.documents.compactMap { document -> Video? in
                print("DEBUG: Processing document: \(document.documentID)")
                do {
                    let video = try document.data(as: Video.self)
                    print("DEBUG: Successfully parsed video: \(video.debugDescription)")
                    return video
                } catch {
                    print("DEBUG: Failed to parse video document: \(error.localizedDescription)")
                    print("DEBUG: Document data: \(document.data())")
                    return nil
                }
            }

            // If no new videos are fetched, log and retain current videos
            if newVideos.isEmpty {
                print("DEBUG: No new videos fetched; retaining current videos.")
            } else {
                // If it's an initial load, set the videos; otherwise, append the newVideos.
                if videos.isEmpty {
                    print("DEBUG: Setting initial videos array with \(newVideos.count) videos")
                    videos = newVideos
                } else {
                    print("DEBUG: Appending \(newVideos.count) new videos to existing \(videos.count) videos")
                    videos.append(contentsOf: newVideos)
                }
                // Update lastDocument for pagination if new videos were fetched.
                lastDocument = snapshot.documents.last
            }

            print("DEBUG: Total videos after fetch: \(videos.count)")
            
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Error fetching videos: \(error.localizedDescription)")
            print("DEBUG: Detailed error: \(error)")
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
        print("DEBUG: videoDidChange triggered for index \(index); current videos count: \(videos.count)")
        // Only trigger fetch if the user is nearing the end of the current videos list.
        guard index >= videos.count - 1 else {
            print("DEBUG: Not at the end of the list. No fetch triggered.")
            return
        }

        // Trigger fetching additional videos (pagination)
        print("DEBUG: Fetching next page after last video")
        Task {
            await fetchVideos()
        }
    }
    
    /// Refresh the feed
    func refresh() async {
        lastDocument = nil  // Reset pagination
        await fetchVideos()
    }
}

