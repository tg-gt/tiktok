//
//  User.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import Foundation
import FirebaseFirestore

// MARK: - User Model
struct User: Identifiable, Codable {
    // MARK: - Properties
    @DocumentID var id: String?  // Firebase document ID
    let email: String
    var displayName: String?
    var interests: [String]?
    var avatarURL: String?
    let createdAt: Date
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case interests
        case avatarURL
        case createdAt
    }
    
    // MARK: - Debug Helpers
    var debugDescription: String {
        return """
        User(id: \(id ?? "nil"),
             email: \(email),
             displayName: \(displayName ?? "nil"),
             interests: \(interests?.joined(separator: ", ") ?? "nil"),
             avatarURL: \(avatarURL ?? "nil"),
             createdAt: \(createdAt))
        """
    }
}

