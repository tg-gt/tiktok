//
//  CommentView.swift
//  tiktok
//
//  Created by gt on 2/8/25.
//

import SwiftUI

// MARK: - Comment View
struct CommentView: View {
    // MARK: - Properties
    @StateObject private var viewModel: CommentViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Init
    init(videoId: String) {
        _viewModel = StateObject(wrappedValue: CommentViewModel(videoId: videoId))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Comments List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(comment: comment) { commentId in
                            Task {
                                await viewModel.toggleCommentLike(commentId: commentId)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Comment Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Add comment...", text: $viewModel.newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isInputFocused)
                    
                    Button(action: {
                        Task {
                            await viewModel.addComment()
                        }
                    }) {
                        Text("Post")
                            .fontWeight(.semibold)
                            .foregroundColor(!viewModel.newCommentText.isEmpty ? .blue : .gray)
                    }
                    .disabled(viewModel.newCommentText.isEmpty)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment
    let onLike: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar (placeholder)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                // Username (placeholder)
                Text("User")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                // Comment text
                Text(comment.text)
                    .font(.subheadline)
                
                // Metadata
                HStack(spacing: 16) {
                    Text(timeAgo(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        if let id = comment.id {
                            onLike(id)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(comment.formattedLikes)
                                .font(.caption)
                            Text("likes")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Like button
            Button(action: {
                if let id = comment.id {
                    onLike(id)
                }
            }) {
                Image(systemName: "heart")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Helper function to format date
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 