# Project Requirements Document (PRD)

## 1. Project Overview

**Product Name:** FitFocus (AI-Enhanced Fitness Video Consumer App)

**Platform:** iOS only (written in Swift, targeting iOS 15+)

**Database:** Firestore (Firebase)  
**Objective:** Provide a TikTok-like short-video consumption experience for fitness enthusiasts, with AI-driven enhancements for content discovery and navigation.

**Key Constraints from Assignment:**
- **User Type:** Consumer (No content upload or editing; focus on discovering and interacting with videos)
- **Niche:** Fitness/Workout/Sports/Exercise
- **AI Features:** Focus on user consumption enhancements (e.g. searching within a video, personalized recommendations)
- **Deployment:** Must be natively built in Swift for iOS, integrated with Firebase services

**High-Level Goal:**
1. **Week 1 (Feb 7 Deadline):**  
   - Deliver a vertical slice for **fitness video consumption** (basic feed, video playback, liking, commenting, saving videos).  
   - Implement **6 user stories** focused on the consumer’s experience.
2. **Week 2 (Feb 14 Deadline):**  
   - Integrate **2 AI features** (for example, “SmartScan” and “PersonalLens”).  
   - Deliver at least **6 AI-focused user stories** that enhance the consumer experience.

---

## 2. Features

Below is the feature list, separated by Week 1 and Week 2 deliverables.

### Week 1 Features (Core Consumer Experience)

1. **User Onboarding & Authentication**  
   - Users can sign up or log in using **Firebase Auth** (email/password and/or social logins).
2. **Home Feed (Basic Recommendation List)**  
   - A scrollable vertical feed of fitness videos.
3. **Video Playback**  
   - Embedded video player for each workout video (hosted in Firebase Cloud Storage).
4. **Liking & Commenting**  
   - Ability to like a video and leave comments.
5. **Search & Filter by Category**  
   - Search videos by keywords, muscle group, difficulty level, etc.
6. **Save/Bookmark Videos**  
   - Users can save videos to their personal “Favorites” list for later viewing.

### Week 2 Features (AI-Powered Enhancements)

1. **SmartScan (AI Video Navigation)**  
   - Users can jump to specific parts of the workout video by asking text-based queries (e.g., “Skip to the squats section” or “Show me the cooldown stretches”).  
   - Under the hood, the system uses AI to analyze video transcripts or metadata.
2. **PersonalLens (Personalized AI Recommendations)**  
   - AI-driven personalized feed that suggests workout videos aligned with user preferences, history, skill level, or goals.  
   - Model training or inference in a Cloud Function that reorders feed results for each user in real time.

---

## 3. Requirements for Each Feature

### Week 1 Requirements

#### 1. User Onboarding & Authentication
- **Dependency:** Firebase Auth (Swift Package version `10.7.0` or newer).
- **Requirement Details:**
  - Users must be able to **create an account** with email/password.
  - Must store **user profile** in Firestore (`/users/{userId}`) upon successful registration.
  - User profile fields: `userId (String)`, `email (String)`, `displayName (String)`, `profilePicUrl (String, optional)`.
  - **Social logins** (e.g. Google Sign-In) should be supported but are optional.

#### 2. Home Feed (Basic Recommendation List)
- **Dependency:** Firestore, SwiftUI (or UIKit) for feed UI.
- **Requirement Details:**
  - Retrieve a list of workout videos from Firestore collection:  
    - Collection name: `videos`
  - Minimal video metadata:  
    - `videoId (String)`, `title (String)`, `thumbnailUrl (String)`, `videoUrl (String)`, `category (String)`, `difficultyLevel (String)`, `likesCount (Number)`, `commentsCount (Number)`, `createdAt (Timestamp)`
  - Display videos in a scrollable list with thumbnail, title, and optional short description.
  - Sorting can be default by `createdAt` descending, or a simple heuristic (e.g., popular first).

#### 3. Video Playback
- **Dependency:** Firebase Cloud Storage for hosting videos, AVFoundation (iOS).
- **Requirement Details:**
  - Tapping a video in the feed launches a detailed view with a video player.
  - Video must **auto-play** on open or play on user action (configurable).
  - Show basic playback controls: pause, play, scrub bar, volume.

#### 4. Liking & Commenting
- **Dependency:** Firestore for real-time interactions, SwiftUI or UIKit for UI.
- **Requirement Details:**
  - **Like a Video:**  
    - When user taps “Like,” increment the `likesCount` in `videos/{videoId}`.  
    - Store user’s like in a subcollection or separate collection e.g. `videoLikes/{videoId}/userLikes/{userId}`.
  - **Comment on a Video:**  
    - Submit a text comment to `videos/{videoId}/comments` subcollection.  
    - Each comment doc: `{ commentId, userId, text, timestamp }`.  
    - Increment `commentsCount` in the parent video document.

#### 5. Search & Filter by Category
- **Dependency:** Firestore queries.
- **Requirement Details:**
  - Provide a **search bar** for free-text search on `title` or `category`.
  - Provide a **filter option** (dropdown or segmented control) for muscle group or difficulty level.  
  - Firestore query examples:  
    - By muscle group: `videos.whereField("category", isEqualTo: "legs")`  
    - By difficulty: `videos.whereField("difficultyLevel", isEqualTo: "beginner")`
  - Return results in a list UI with same format as the home feed.

#### 6. Save/Bookmark Videos
- **Dependency:** Firestore subcollection or references.
- **Requirement Details:**
  - User can tap a “Save” or “Bookmark” icon on any video detail view.
  - Saved videos stored in `users/{userId}/savedVideos/{videoId}` with minimal metadata.
  - Saved videos displayed in the user’s “Favorites” screen, accessible from profile or main menu.

### Week 2 Requirements (AI Enhancements)

#### 1. SmartScan (AI Video Navigation)
- **Dependency:** 
  - **Cloud Functions** for AI transcript processing.  
  - Potentially an external LLM or Generative AI in Firebase to parse video transcripts or manual timestamps.
- **Requirement Details:**
  - Each video will have either a pre-computed transcript or labeled segments in Firestore:  
    - `transcripts/{videoId}/segments/{segmentId}` with fields like `{ startTime, endTime, label }`.
  - When the user types or speaks a query (e.g., “Show me the warm-up”), the app calls a **Cloud Function**:  
    - Endpoint: `POST /smartScan/searchSegment`  
    - Request body example:  
      ```json
      {
        "videoId": "<videoId>",
        "userQuery": "Show me the warm-up"
      }
      ```
    - The Cloud Function uses AI to match the user query to the most relevant segment’s start/end time.
    - The function returns:
      ```json
      {
        "segmentId": "<segmentId>",
        "startTime": 30, 
        "endTime": 90
      }
      ```
  - The app automatically **seeks** the video player to `startTime`.

**SmartScan User Stories (examples):**
1. “As a fitness consumer, I can type ‘Show me the chest exercises’ and jump directly to that section of the workout video.”  
2. “As a fitness consumer, I can quickly skip the introduction by typing ‘Skip intro’ and be taken to the main workout.”  
3. “As a fitness consumer, I can see labeled sections (Warm-up, Main Workout, Cool-down) and tap to jump.”

#### 2. PersonalLens (Personalized AI Recommendations)
- **Dependency:** 
  - **Cloud Functions** that host a personalization or ranking model (could be a recommendation model).  
  - Firestore for storing user watch history, likes, etc.
- **Requirement Details:**
  - The feed calls a new endpoint on app launch or feed refresh:
    - Endpoint: `GET /recommendations?userId=<userId>`
  - The Cloud Function processes user watch history, preferences, likes to produce a ranked list of `videoId`s.
  - Return payload example:
    ```json
    {
      "recommendations": [
        { "videoId": "abc123", "score": 0.95 },
        { "videoId": "def456", "score": 0.90 }
      ]
    }
    ```
  - The app displays the recommended videos in order, building a personalized feed.

**PersonalLens User Stories (examples):**
1. “As a fitness consumer, I get recommended videos based on my previous viewed categories.”  
2. “As a fitness consumer, I want to see new workouts aligned with my skill level (beginner, intermediate, advanced).”  
3. “As a fitness consumer, I appreciate personalized suggestions that reduce browsing time.”  

---

## 4. Data Models

### Firestore Collections

#### 1. `users/{userId}`
**Fields:**  
- `displayName: String`  
- `email: String`  
- `profilePicUrl: String` (optional)  
- `createdAt: Timestamp`  
- `preferences: Map` (e.g., `{ "primaryGoal": "strength", "skillLevel": "intermediate" }`)

**Subcollections:**
- `savedVideos/{videoId}`  
  - `videoId: String`  
  - `savedAt: Timestamp`  

#### 2. `videos/{videoId}`
**Fields:**  
- `title: String`  
- `thumbnailUrl: String`  
- `videoUrl: String`  
- `category: String` (e.g., “legs,” “arms,” “cardio”)  
- `difficultyLevel: String` (e.g., “beginner,” “advanced”)  
- `likesCount: Number`  
- `commentsCount: Number`  
- `createdAt: Timestamp`

**Subcollections:**
- `comments/{commentId}`  
  - `commentId: String`  
  - `userId: String`  
  - `text: String`  
  - `timestamp: Timestamp`
- `segments/{segmentId}` (for SmartScan)  
  - `label: String` (e.g. “Warm-up”)  
  - `startTime: Number` (in seconds)  
  - `endTime: Number` (in seconds)

#### 3. `videoLikes/{videoId}/userLikes/{userId}`
Optionally, to handle likes as a separate collection if needed:
- `likedAt: Timestamp`

#### 4. `recommendations/{userId}`
- This can be ephemeral or generated by a function.  
- Optionally store a personalized list:  
  - `videos: [ { videoId, score } ]`

---

## 5. API Contract

Because we are using Firebase extensively, many operations happen via the client SDK. However, for advanced AI logic (especially in Week 2), we will define Cloud Functions endpoints:

### Cloud Function Endpoints

1. **SmartScan - Search Segments**  
   **Endpoint:** `POST /smartScan/searchSegment`  
   **Request Body:**  
   ```json
   {
     "videoId": "<videoId>",
     "userQuery": "Show me the warm-up"
   }
   ```  
   **Response Body (200):**  
   ```json
   {
     "segmentId": "<segmentId>",
     "startTime": 30,
     "endTime": 90
   }
   ```  
   **Error Response (400 or 500):**  
   ```json
   {
     "error": "Video not found or AI analysis failed."
   }
   ```

2. **PersonalLens - Personalized Recommendations**  
   **Endpoint:** `GET /recommendations?userId=<userId>`  
   **Response Body (200):**  
   ```json
   {
     "recommendations": [
       { "videoId": "abc123", "score": 0.95 },
       { "videoId": "def456", "score": 0.90 }
     ]
   }
   ```  
   **Error Response (400 or 500):**  
   ```json
   {
     "error": "No user found or recommendation service error."
   }
   ```

### Firebase Client Operations (No Dedicated Endpoint)

1. **User Authentication**  
   - `FirebaseAuth.auth().createUser(withEmail:)`  
   - `FirebaseAuth.auth().signIn(withEmail:)`  
   - Automatically triggers creation of `/users/{userId}` in Firestore if not present.

2. **Fetching Videos**  
   - Firestore query to `videos` collection:  
     ```swift
     Firestore.firestore().collection("videos")
       .order(by: "createdAt", descending: true)
       .limit(to: 20)
       .getDocuments { ... }
     ```

3. **Liking a Video**  
   - Increment `likesCount` in `videos/{videoId}`.  
   - Create doc in `videoLikes/{videoId}/userLikes/{userId}`.

4. **Commenting on a Video**  
   - Create doc in `videos/{videoId}/comments` with `commentId`, `text`, `userId`, `timestamp`.  
   - Increment `commentsCount` on parent doc.

5. **Saving a Video**  
   - Create doc in `users/{userId}/savedVideos/{videoId}` with `savedAt`.

6. **Searching & Filtering**  
   - Firestore queries with `.whereField("category", isEqualTo: <value>)` or `.whereField("title", isGreaterThanOrEqualTo: <searchTerm>)` etc.

---

### Final Notes & Dependencies

- **Language:** Swift 5.7+  
- **Firebase iOS SDK Dependencies (Version 10.7.0+ recommended):**  
  1. `FirebaseAuth`  
  2. `FirebaseFirestore`  
  3. `FirebaseStorage`  
  4. `FirebaseFunctions` (for AI endpoints)  
  5. `FirebaseMessaging` (optional for push notifications)  
- **Video Player:** `AVKit/AVFoundation` on iOS.  
- **AI Model/Service**: 
  - For transcript-based queries: a function calling a language model (e.g., GPT API or Generative AI on Firebase)  
  - For personalization: a custom Cloud Function that calculates a recommendation ranking.

This PRD outlines **all required features, data models, and API contracts** for a fitness-themed, iOS-only, Firestore-backed video consumer app with AI-based content navigation and personalized recommendations.