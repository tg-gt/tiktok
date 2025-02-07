//
//  Video.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Video Model
struct Video: Identifiable, Codable {
    // MARK: - Properties
    @DocumentID var id: String?  // Firebase document ID
    let title: String
    let thumbnailUrl: String?
    let videoUrl: String
    let category: [String]?
    var likesCount: Int
    var commentsCount: Int
    let createdAt: Date
    let userId: String?  // Reference to creator
    
    // MARK: - Computed Properties
    var formattedLikes: String {
        formatCount(likesCount)
    }
    
    var formattedComments: String {
        formatCount(commentsCount)
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case thumbnailUrl
        case videoUrl
        case category
        case likesCount
        case commentsCount
        case createdAt
        case userId
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
        Video(id: \(id ?? "nil"),
              title: \(title),
              category: \(category),
              likes: \(likesCount),
              comments: \(commentsCount),
              userId: \(userId))
        """
    }
}

