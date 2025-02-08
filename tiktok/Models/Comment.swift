//
//  Comment.swift
//  tiktok
//
//  Created by gt on 2/8/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    // MARK: - Properties
    @DocumentID var id: String?  // Firebase document ID
    let text: String
    let userId: String
    let videoId: String
    let createdAt: Date
    var likesCount: Int
    
    // MARK: - Computed Properties
    var formattedLikes: String {
        formatCount(likesCount)
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case userId
        case videoId
        case createdAt
        case likesCount
    }
    
    // MARK: - Helper Methods
    private func formatCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            return String(format: "%.1fK", Double(count) / 1000)
        default:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
    }
    
    // MARK: - Debug Helpers
    var debugDescription: String {
        return """
        Comment(id: \(id ?? "nil"),
                text: \(text),
                userId: \(userId),
                videoId: \(videoId),
                likes: \(likesCount))
        """
    }
} 