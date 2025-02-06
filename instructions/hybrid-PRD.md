Below is a simplified PRD that meets your Week 1 MVP requirements while laying a clear foundation for the more advanced AI-generated content features (and personalization) you plan to add in Week 2. In Week 1 you’ll manually create a set of AI-generated videos (using your preferred external tools) and load them into Firestore/Storage so that a consumer (viewer) can scroll through, like, comment, and save videos. Later, you can replace or augment the manual workflow with automated, modular Cloud Functions that call AI-generation APIs.

---

# Project Overview

**Product Name:** FlexibleAIVibeTok  
**Platform:** iOS only (native app in Swift)  
**Database:** Firestore  
**Storage:** Firebase Cloud Storage  
**Objective (Week 1):**  
- Build a vertical slice TikTok clone for content consumers who discover and interact with short-form videos (5–60 seconds).  
- Enable basic features like video feed, playback, liking, commenting, and saving videos.  
- Pre-load a set of manually created AI-generated videos so that the consumer experience is fully functional.  
- Lay the groundwork (data models, API endpoints, and modular design) so that in Week 2 you can add automated, plug‑n‑play AI content generation and simple recommendation/customization logic.

---

# Features

### Week 1 (MVP Core Features)
1. **User Onboarding & Authentication**  
   - Users can sign up and log in using Firebase Auth.
2. **Video Feed (Home Screen)**  
   - A vertically scrollable feed showing pre-generated AI videos.
3. **Video Playback**  
   - Each video plays in full-screen mode when selected.
4. **User Engagement (Likes & Comments)**  
   - Consumers can like videos and post comments.
5. **Video Saving (Bookmarking)**  
   - Consumers can save videos to a “Favorites” list.
6. **Manual Content Management (Admin)**
   - A simple back‑office (or manual process via Firestore console) to upload AI-generated video metadata and store video files in Firebase Storage.

### Week 2 (Planned Enhancements – Foundation Laid in Week 1)
1. **Automated AI-Generated Content Pipeline**  
   - Cloud Functions to call external AI video, audio, and text generation APIs in a modular, plug‑n‑play manner.
2. **Feedback-Driven Content Suggestions**  
   - A mechanism for users to suggest what they’d like to see next. Suggestions are stored in Firestore and, once reviewed, trigger the AI video generation process.
3. **Personalized Recommendation Engine**  
   - Enhance the feed by integrating simple behavioral data (likes, views) with the initial interest selections (from sign‑up) to reorder the video feed.

---

# Requirements for Each Feature

### 1. User Onboarding & Authentication
- **Functionality:**  
  - Users can create an account using email/password.  
  - On first sign‑up, a new document is created in `/users/{userId}` with basic profile data.
- **Dependencies:**  
  - Firebase Auth SDK (Swift).  
  - Firestore for user profile data.
- **Key Variables:**  
  - `userId` (string), `email` (string), `displayName` (string), `createdAt` (timestamp).

### 2. Video Feed (Home Screen)
- **Functionality:**  
  - Display a vertically scrollable list of video cards.
  - Each card shows a thumbnail, title/description, and basic engagement stats.
- **Dependencies:**  
  - Firestore query on `videos` collection.  
  - UIKit/SwiftUI list components.
- **Key Variables (per video):**  
  - `videoId` (string), `title` (string), `thumbnailUrl` (string), `videoUrl` (string), `category` (string), `likesCount` (number), `commentsCount` (number), `createdAt` (timestamp).

### 3. Video Playback
- **Functionality:**  
  - Tapping a video card opens a full-screen player.
  - Video plays automatically with basic playback controls.
- **Dependencies:**  
  - AVFoundation / AVKit for video playback.
  - Firebase Storage (for video hosting; URL stored in Firestore).
- **Key Variables:**  
  - `videoUrl` from Firestore (download URL for the video file).

### 4. User Engagement (Likes & Comments)
- **Likes:**  
  - Users tap a heart icon to like a video.
  - Increment `likesCount` in Firestore and store a like record.
- **Comments:**  
  - Users can post comments on a video.
  - Comments are stored in a subcollection under the video.
- **Dependencies:**  
  - Firestore (for real-time updates).
- **Key Variables:**  
  - **For Likes:** `likesCount` on `videos/{videoId}` and an optional document in `/videoLikes/{videoId}/userLikes/{userId}`.  
  - **For Comments:** Each comment document with `commentId` (string), `userId` (string), `text` (string), and `timestamp` (timestamp).

### 5. Video Saving (Bookmarking)
- **Functionality:**  
  - A “Save” button on the video detail view adds the video to the user’s “Favorites.”
- **Dependencies:**  
  - Firestore subcollection: `/users/{userId}/savedVideos/{videoId}`.
- **Key Variables:**  
  - Each saved video record contains `videoId` and `savedAt` (timestamp).

### 6. Manual Content Management (Admin)
- **Functionality:**  
  - For Week 1, videos will be manually created and uploaded:
    - Video files are uploaded to Firebase Storage.
    - A document is added to Firestore’s `videos` collection with metadata.
- **Dependencies:**  
  - Firebase Storage (for storing video files).  
  - Firestore (for video metadata).
- **Key Variables:**  
  - `videoId`, `storagePath` (or public download URL), `title`, `category`, etc.
- **Note:**  
  - This “admin” step is manual in Week 1 but lays the groundwork for automated AI generation in Week 2.  
  - You can use a simple script or Firebase Console to create these records.

### Future-Proofing for Week 2
- **Modular AI Integration:**  
  - Define a common interface for video generation (e.g. a Cloud Function `generateVideo(prompt, options)`) that you can later call instead of manual uploads.
  - Store the chosen AI provider’s identifier in each video document (e.g. `modelUsed: "Runway"`).  
- **Recommendation Engine Foundation:**  
  - Include fields in the user document for storing interests (e.g. `interests: [String]`).  
  - Reserve space in the feed query logic (or Cloud Function) so that later you can mix in a ranking score based on user behavior.
- **User Suggestion Mechanism:**  
  - Reserve a Firestore collection (`suggestions`) for later Week 2 integration. For now, it can be empty but with a known schema.

---

# Data Models

### Firestore Collections

#### 1. Users (`/users/{userId}`)
- **Fields:**  
  - `userId` (string)  
  - `email` (string)  
  - `displayName` (string)  
  - `interests` (array of strings, e.g. `[ "Comedy", "News", "Surreal" ]`) – to be used in 
  - `createdAt` (timestamp)
  - `avatarURL` (string) – Avatar URL

#### 2. Videos (`/videos/{videoId}`)
- **Fields:**  
  - `videoId` (string)  
  - `title` (string)  
  - `thumbnailUrl` (string)  
  - `videoUrl` (string, Firebase Storage URL)  
  - `category` (string) – flexible for different themes  
  - `likesCount` (number)  
  - `commentsCount` (number)  
  - `createdAt` (timestamp)  
  - **(Optional for future)** `modelUsed` (string) – e.g., "Runway" or "Sora"  

#### 3. Comments (`/videos/{videoId}/comments/{commentId}`)
- **Fields:**  
  - `commentId` (string)  
  - `userId` (string)  
  - `text` (string)  
  - `timestamp` (timestamp)

#### 4. Video Likes (`/videoLikes/{videoId}/userLikes/{userId}`)
- **Fields:**  
  - `userId` (string)  
  - `likedAt` (timestamp)

#### 5. Saved Videos (`/users/{userId}/savedVideos/{videoId}`)
- **Fields:**  
  - `videoId` (string)  
  - `savedAt` (timestamp)

#### 6. (Reserved for Week 2) Suggestions (`/suggestions/{suggestionId}`)
- **Fields:**  
  - `userId` (string)  
  - `text` (string)  
  - `status` (string; default “pending”, later “approved” or “rejected”)  
  - `createdAt` (timestamp)

---

# API Contract

For Week 1, most interactions will be handled directly via the Firebase SDK (Firestore CRUD operations, Firebase Auth, and Storage retrieval). However, we define a couple of Cloud Functions endpoints (which will be expanded in Week 2) to provide a foundation for modular AI integration.

### 1. Manual Video Upload (Admin Use Only – Week 1)
- **Purpose:**  
  - Manually create a video document after uploading an AI-generated video file.
- **Process (Manual/Scripted):**  
  - Upload video file to Firebase Storage at path:  
    `/videos/{videoId}.mp4`
  - Create a Firestore document in `videos`:
    ```json
    {
      "videoId": "video123",
      "title": "Surreal Hyperborea",
      "thumbnailUrl": "https://firebasestorage.googleapis.com/.../video123_thumbnail.jpg",
      "videoUrl": "https://firebasestorage.googleapis.com/.../video123.mp4",
      "category": "Surreal",
      "likesCount": 0,
      "commentsCount": 0,
      "createdAt": "<timestamp>"
    }
    ```

### 2. Get Feed (Client-side Firestore Query)
- **Endpoint:** Not a Cloud Function; handled via Firestore SDK.
- **Query Example (Swift):**
  ```swift
  Firestore.firestore().collection("videos")
      .order(by: "createdAt", descending: true)
      .limit(to: 20)
      .getDocuments { (snapshot, error) in
          // Process documents into video model array
      }
  ```
- **Response:**  
  - A list of video documents with fields: `videoId`, `title`, `thumbnailUrl`, `videoUrl`, etc.

### 3. Like Video (Cloud Function Optional, or Direct Firestore Write)
- **Purpose:**  
  - Process a like action and update counts.
- **Method:**  
  - Client calls a Cloud Function (if implemented) or directly writes to `videoLikes/{videoId}/userLikes/{userId}` and uses Firestore’s atomic increment to update `likesCount`.
- **Cloud Function (Optional) Contract Example:**
  - **Function Name:** `likeVideo`
  - **Input:**  
    ```json
    {
      "videoId": "video123",
      "userId": "user456",
      "isLike": true
    }
    ```
  - **Output (Success):**
    ```json
    {
      "success": true,
      "newLikesCount": 25
    }
    ```

### 4. Comment on Video (Direct Firestore Write)
- **Process:**  
  - Client writes a new document in `/videos/{videoId}/comments` with fields: `commentId`, `userId`, `text`, `timestamp`.
- **No dedicated Cloud Function required for MVP.**

### Future API Endpoints for Week 2
- **Generate Video:**  
  - **Endpoint:** `POST /generateVideo`  
  - **Request Body:**  
    ```json
    {
      "prompt": "A hot couple doing acrobatics on the beach with their new humanoid robot",
      "options": { "duration": 30 }
    }
    ```
  - **Response:**  
    ```json
    {
      "videoId": "videoXYZ",
      "storageUrl": "https://firebasestorage.googleapis.com/.../videoXYZ.mp4",
      "modelUsed": "Runway"
    }
    ```
- **Get Recommendations:**  
  - **Endpoint:** `GET /recommendations?userId=user456`  
  - **Response:**  
    ```json
    {
      "videos": [ /* list of video objects ordered by personalized ranking */ ]
    }
    ```
- **Submit Suggestion:**  
  - **Endpoint:** `POST /submitSuggestion`  
  - **Request Body:**  
    ```json
    {
      "userId": "user456",
      "text": "I want to see a newscast about Elon Musk growing gardens on Mars"
    }
    ```
  - **Response:**  
    ```json
    {
      "suggestionId": "sugg789",
      "status": "pending"
    }
    ```

---

## Final Notes

- **Week 1 Focus:**  
  - Build a fully functioning TikTok-like consumer app with a vertical feed, video playback, basic engagement (likes/comments), and saving functionality.  
  - Manually create and upload AI-generated videos so the app has content.
- **Foundation for Week 2:**  
  - Data models include fields like `modelUsed` and reserved collections (e.g. `suggestions`) that make future automated AI-generation and recommendation engines straightforward to implement.
  - API contracts for video generation and personalized recommendations are defined but remain unimplemented in Week 1 (to be added in Week 2).

This simplified PRD keeps Week 1 lean and focused on delivering a solid MVP while providing a clear, modular architecture and API contract that allows you to integrate AI content generation and enhanced recommendation logic as you evolve the product.