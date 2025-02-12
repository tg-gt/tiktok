//
//  FirebaseService.swift
//  tiktok
//
//  Created by gt on 2/5/25.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

// MARK: - Firebase Service
class FirebaseService {
    // MARK: - Singleton
    static let shared = FirebaseService()
    
    // MARK: - Properties
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Image Upload
    /// Uploads an image to Firebase Storage and returns the download URL
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - path: The storage path where the image should be stored
    /// - Returns: The download URL of the uploaded image
    func uploadImage(_ imageData: Data, path: String) async throws -> String {
        // Create a unique filename using UUID
        let filename = "\(UUID().uuidString).jpg"
        let fullPath = "\(path)/\(filename)"
        
        // Get a reference to the storage location
        let storageRef = storage.reference().child(fullPath)
        
        // Log upload start
        print("Starting image upload to path: \(fullPath)")
        
        // Upload the image data
        _ = try await storageRef.putDataAsync(imageData)
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        
        // Log successful upload
        print("Successfully uploaded image. Download URL: \(downloadURL.absoluteString)")
        
        return downloadURL.absoluteString
    }
}

