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
    let userId: String?  // Reference to creator
    let title: String?
    let description: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    var category: [String]?
    var likesCount: Int
    var commentsCount: Int
    let createdAt: Date
    
    // MARK: - AI Generation Properties
    var isAIGenerated: Bool?
    var status: String?  // "processing", "completed", "failed"
    var sourceVideoId: String?  // Original video ID if this is a face swap
    var originalVideoUrl: String?  // URL of the source video
    var faceImageUrl: String?  // URL of the face image used for swap
    var generationError: String?  // Error message if generation failed
    
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
        case userId
        case title
        case description
        case videoUrl
        case thumbnailUrl
        case category
        case likesCount
        case commentsCount
        case createdAt
        case isAIGenerated
        case status
        case sourceVideoId
        case originalVideoUrl
        case faceImageUrl
        case generationError
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
              userId: \(userId ?? "nil"),
              title: \(title ?? "nil"),
              description: \(description ?? "nil"),
              category: \(category?.description ?? "nil"),
              likes: \(likesCount),
              comments: \(commentsCount))
        """
    }
    
    // MARK: - Initialization
    init(id: String? = nil,
         userId: String?,
         title: String?,
         description: String?,
         videoUrl: String?,
         thumbnailUrl: String?,
         category: [String]? = nil,
         createdAt: Date,
         likesCount: Int = 0,
         commentsCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.category = category
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.commentsCount = commentsCount
    }
}

