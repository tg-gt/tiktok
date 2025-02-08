//
//  CommentViewModel.swift
//  tiktok
//
//  Created by gt on 2/8/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Comment View Model
@MainActor
class CommentViewModel: ObservableObject {
    // MARK: - Properties
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var newCommentText = ""
    
    private let db = Firestore.firestore()
    private let videoId: String
    
    // MARK: - Init
    init(videoId: String) {
        print("DEBUG: CommentViewModel initialized for video: \(videoId)")
        self.videoId = videoId
        Task {
            await fetchComments()
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetch comments for the video
    func fetchComments() async {
        do {
            isLoading = true
            error = nil
            
            print("DEBUG: Fetching comments for video: \(videoId)")
            
            let snapshot = try await db.collection("comments")
                .whereField("videoId", isEqualTo: videoId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            comments = snapshot.documents.compactMap { document -> Comment? in
                do {
                    let comment = try document.data(as: Comment.self)
                    print("DEBUG: Successfully parsed comment: \(comment.debugDescription)")
                    return comment
                } catch {
                    print("DEBUG: Failed to parse comment: \(error.localizedDescription)")
                    return nil
                }
            }
            
            print("DEBUG: Fetched \(comments.count) comments")
            
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Error fetching comments: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Add a new comment
    func addComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("DEBUG: Comment text is empty")
            return
        }
        
        do {
            print("DEBUG: Adding new comment for video: \(videoId)")
            
            let comment = Comment(
                text: newCommentText,
                userId: "currentUserId", // TODO: Get from AuthViewModel
                videoId: videoId,
                createdAt: Date(),
                likesCount: 0
            )
            
            // Add to Firestore
            let ref = try db.collection("comments").addDocument(from: comment)
            print("DEBUG: Added comment with ID: \(ref.documentID)")
            
            // Update video's comment count
            try await db.collection("videos").document(videoId).updateData([
                "commentsCount": FieldValue.increment(Int64(1))
            ])
            
            // Clear the text field and refresh comments
            newCommentText = ""
            await fetchComments()
            
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Error adding comment: \(error.localizedDescription)")
        }
    }
    
    /// Like/unlike a comment
    func toggleCommentLike(commentId: String) async {
        do {
            print("DEBUG: Toggling like for comment: \(commentId)")
            
            // TODO: Implement like/unlike logic with user tracking
            try await db.collection("comments").document(commentId).updateData([
                "likesCount": FieldValue.increment(Int64(1))
            ])
            
            await fetchComments()
            
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: Error toggling comment like: \(error.localizedDescription)")
        }
    }
} 