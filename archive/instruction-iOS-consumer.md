# Project Requirements Document (PRD)

Below is a comprehensive PRD for an **iOS-only** short-form video application targeted at **content consumers** in the **“recipe discovery”** niche, using **Firestore** as the primary database. This PRD focuses on the consumer experience (no creator/video editing features) and integrates two AI enhancements for content discovery and personalization. 

---

## 1. Project Overview

**Name**: **ReelAI – Recipe Discovery (Consumer-Focused iOS App)**

**Objective**: Build and deploy a TikTok-style application that allows recipe-focused consumers to:
1. Discover short cooking/recipe videos.
2. Interact with videos (like, comment, save/collection).
3. Filter and search for recipes by cooking time, cuisine type, etc.
4. Receive AI-powered features for smarter navigation (“SmartScan”) and personalized recommendations (“PersonalLens”).

**Technical Stack**:
- **Platform**: iOS (Swift)
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Database**: Firestore
- **Hosting**: Firebase App Distribution for iOS
- **AI Features**: Leveraging Generative AI in Firebase & Cloud Functions

---

## 2. Features

### 2.1 Week 1 Features (Vertical Slice)

1. **Video Feed**  
   - Displays a continuous vertical feed of recipe videos.
   - Users can scroll up/down to view new or trending videos.

2. **Video Playback**  
   - Tap on a video to view details in a “full view” player.
   - Playback controls include pause/play, volume, and scrubbing.

3. **Likes**  
   - Allows users to like/unlike a video.
   - Like count is updated in real-time.

4. **Comments**  
   - Users can read and post comments on any video.
   - Real-time updates for new comments.

5. **Save to Favorites**  
   - Users can “save” or bookmark a video to view later.
   - Saved videos are accessible from the user’s profile screen under “My Favorites” or “My Collections.”

6. **Search & Filter**  
   - Users can search videos by recipe name, cooking time, or cuisine type.
   - Filter by cooking time (e.g., under 15 min, 30 min, etc.).

#### Week 1 User Stories (6 Minimum)

1. **US1**: “As a recipe consumer, I can scroll through a feed of recipe videos so that I can quickly find interesting new dishes.”  
2. **US2**: “As a recipe consumer, I can tap on a video to see more details and watch it in a larger view so that I can follow the recipe more clearly.”  
3. **US3**: “As a recipe consumer, I can like a video so that I can easily show my appreciation and help others discover popular recipes.”  
4. **US4**: “As a recipe consumer, I can view and post comments on a video so that I can share my questions or insights about the recipe.”  
5. **US5**: “As a recipe consumer, I can save a video to my favorites so that I can return to it later when I’m ready to cook.”  
6. **US6**: “As a recipe consumer, I can filter or search by cooking time so that I can quickly find recipes suitable for my schedule.”

### 2.2 Week 2 AI Features

1. **SmartScan**  
   - Allows users to jump to specific segments of a recipe video (e.g., “show me the sauce-making part”).
   - AI identifies key segments from video transcripts or metadata for direct navigation.

2. **PersonalLens**  
   - Provides personalized recipe recommendations based on user preferences (e.g., skill level, favorited cuisines).
   - AI ranks videos in the feed or offers a curated “For You” tab.

#### Week 2 User Stories (6 Minimum Across These 2 Features)

- **SmartScan**  
  1. **US7**: “As a recipe consumer, I can ask ‘show me the part where the ingredients are listed’ so that I can quickly note everything I need.”  
  2. **US8**: “As a recipe consumer, I can ask ‘skip to sauce-making section’ so that I can start cooking without watching the entire introduction.”  
  3. **US9**: “As a recipe consumer, I can search for a specific cooking technique in a video (e.g., ‘how to blanch vegetables’) so that I can jump to that moment.”

- **PersonalLens**  
  4. **US10**: “As a recipe consumer, I receive recommended videos based on my saved favorites so that I can discover similar recipes I might enjoy.”  
  5. **US11**: “As a recipe consumer, I get recommended videos that match my skill level (beginner, intermediate, advanced) so I don’t get overwhelmed.”  
  6. **US12**: “As a recipe consumer, I can see a curated ‘For You’ feed that sorts recipes by my cooking time preference so I quickly find relevant meals.”

---

## 3. Requirements for Each Feature

### 3.1 Week 1 – Core Consumer Requirements

#### 3.1.1 Video Feed
- **Functional**:
  - Retrieve a list of videos sorted by popularity or recency.
  - Preload thumbnail/preview to ensure a smooth scrolling experience.
- **Non-functional**:
  - Must load within 2 seconds on a stable network.
  - Infinite scrolling to allow endless feed consumption.

#### 3.1.2 Video Playback
- **Functional**:
  - Tapping on a thumbnail or card opens the full-screen player.
  - Basic controls: play, pause, scrub, volume.
- **Non-functional**:
  - Low latency streaming (buffer < 3 seconds) on stable networks.

#### 3.1.3 Likes
- **Functional**:
  - Single-tap like/unlike.
  - Display real-time like count.
- **Non-functional**:
  - Must reflect changes within Firestore in under 1 second.

#### 3.1.4 Comments
- **Functional**:
  - Display existing comments in chronological order (or top comments first).
  - Allow posting new comment with the user’s display name.
- **Non-functional**:
  - Real-time sync for newly added comments.

#### 3.1.5 Save to Favorites
- **Functional**:
  - User can tap a “Save” icon to add the video to their personal “Favorites” collection in Firestore.
  - Display saved videos in a separate “My Favorites” list in the user profile.
- **Non-functional**:
  - Must reflect changes to the user’s data in real-time.

#### 3.1.6 Search & Filter
- **Functional**:
  - Text-based search to match video titles or tags.
  - Filter by cooking time (e.g., <15 min, 15-30 min, 30+ min).
- **Non-functional**:
  - Queries must return results within 2 seconds for typical loads.

### 3.2 Week 2 – AI Features Requirements

#### 3.2.1 SmartScan
- **Functional**:
  - Identify timestamps in the video where certain actions or segments occur (ingredients listing, sauce-making, plating, etc.).
  - Provide an in-video “Table of Contents” or text-based query interface that jumps to the relevant timestamp.
- **Dependencies**:
  - Cloud Functions that process transcripts (or use external AI for video transcript generation).
  - Firestore to store timestamps (e.g., `videoId -> { segmentName, startTime, endTime }`).
- **Non-functional**:
  - Jump to segments within 1 second of user request.

#### 3.2.2 PersonalLens
- **Functional**:
  - Personalized feed generation using user data: favorites, likes, skill level (stored in user profile).
  - Suggest next videos or a dedicated “For You” list updated daily or on app open.
- **Dependencies**:
  - Cloud Functions AI recommendation engine (queries user’s Firestore data).
  - Possibly uses vector similarity or a custom recommendation ML model hosted on Firebase or external service.
- **Non-functional**:
  - Personalized feed updates under 5 seconds from the time user opens or refreshes “For You.”

---

## 4. Data Models

All data is stored in **Firestore** (NoSQL). Collection names are in **singular** or **plural** depending on personal/team convention; for clarity, assume *plural* in this PRD. Key variable names are indicated below.

### 4.1 Collections and Document Structures

#### 4.1.1 `users` Collection
- **Document ID**: `uid` (string, from Firebase Auth)
- **Fields**:
  - `displayName` (string)
  - `email` (string)
  - `profilePictureUrl` (string, optional)
  - `skillLevel` (string, e.g., “beginner”, “intermediate”, “advanced”)
  - `favorites` (array of `videoId` strings or sub-collection) 
    - Alternatively stored in a sub-collection called `favorites`.

Example:
```
users/{uid} = {
  displayName: "ChefJohn",
  email: "chefjohn@example.com",
  profilePictureUrl: "https://firebasestorage...",
  skillLevel: "beginner",
  favorites: ["video123", "video456"]
}
```

#### 4.1.2 `videos` Collection
- **Document ID**: `videoId` (auto-generated or a unique slug)
- **Fields**:
  - `title` (string)
  - `description` (string)
  - `videoUrl` (string, from Firebase Storage)
  - `thumbnailUrl` (string, from Firebase Storage)
  - `creatorName` (string or reference to a user, optional for consumer-only scenario)
  - `cuisineType` (string, e.g., “Italian”, “Mexican”)
  - `cookingTime` (number, total minutes)
  - `likeCount` (number)
  - `createdAt` (timestamp)
  - `aiSegments` (map or sub-collection for SmartScan, e.g. “ingredients”: {start: 10.0, end: 20.0})

Example:
```
videos/{videoId} = {
  title: "Easy Pasta Sauce",
  description: "A quick marinara sauce recipe.",
  videoUrl: "https://firebasestorage.../videos/videoId.mp4",
  thumbnailUrl: "https://firebasestorage.../thumbnails/videoId.jpg",
  cuisineType: "Italian",
  cookingTime: 15,
  likeCount: 34,
  createdAt: <timestamp>,
  aiSegments: {
    "ingredients": {start: 5.0, end: 12.0},
    "sauceMaking": {start: 13.0, end: 25.0}
  }
}
```

#### 4.1.3 `comments` Sub-collection
- **Path**: `videos/{videoId}/comments/{commentId}`
- **Fields**:
  - `userId` (string)
  - `text` (string)
  - `createdAt` (timestamp)

Example:
```
videos/{videoId}/comments/{commentId} = {
  userId: "userXYZ",
  text: "This recipe looks amazing!",
  createdAt: <timestamp>
}
```

#### 4.1.4 `recommendations` (Optional)
- For storing personalized recommendations or caching them.
- **Path**: `users/{uid}/recommendations/{recommendationId}`
- **Fields**:
  - `videoId` (string)
  - `score` (number, AI relevance score)

---

## 5. API Contract

Since this is a **Firebase/Firestore**-driven app, most functionality will be handled via **SDK** calls in Swift. However, for clarity and to leave no ambiguities, below are the high-level endpoints or function calls (both direct Firestore queries and Cloud Functions) that the iOS client will invoke.

### 5.1 Firebase Auth
- **Sign Up / Sign In**  
  - Method: `Auth.auth().createUser(...)` or `Auth.auth().signInWithEmailPassword(...)`  
  - **Parameters**: `email`, `password`  
  - **Response**: A user object with `uid`.  
- **Sign Out**  
  - Method: `Auth.auth().signOut()`

### 5.2 Firestore Queries

#### 5.2.1 Retrieve Video Feed
- **Method**: Firestore query on `videos` collection.  
  - Example (pseudo-Swift):  
    ```swift
    db.collection("videos")
      .order(by: "createdAt", descending: true)
      .limit(to: 20)
      .getDocuments { ... }
    ```
  - **Response**: Array of video documents (title, thumbnailUrl, etc.).

#### 5.2.2 Search & Filter
- **Method**: Firestore composite query or Cloud Function.  
  - **Cooking Time Filter** example:  
    ```swift
    db.collection("videos")
      .whereField("cookingTime", isLessThanOrEqualTo: 15) // for <15 min
      .getDocuments { ... }
    ```
  - **Full-Text Search**: May require a dedicated search service (e.g., Algolia) or a Cloud Function that queries Firestore. 

#### 5.2.3 Like / Unlike Video
- **Method**: Batched write or direct update to `videos/{videoId}`.  
  - **Increment**:
    ```swift
    let videoRef = db.collection("videos").document(videoId)
    videoRef.updateData([
      "likeCount": FieldValue.increment(Int64(1))
    ])
    ```
  - **Unlike**:
    ```swift
    videoRef.updateData([
      "likeCount": FieldValue.increment(Int64(-1))
    ])
    ```

#### 5.2.4 Add Comment
- **Method**: `db.collection("videos").document(videoId).collection("comments").addDocument(...)`  
  - **Body**: `{ userId, text, createdAt }`  
  - **Response**: `commentId` automatically generated.

#### 5.2.5 Save to Favorites
- **Method**: `db.collection("users").document(uid).updateData(...)`  
  - **Body**: `favorites: FieldValue.arrayUnion([videoId])`  

### 5.3 Cloud Functions

#### 5.3.1 SmartScan (Week 2)
- **Endpoint**: `POST https://<cloudfunctions-domain>/smartScan`  
  - **Description**: Processes a given `videoId`, extracts transcript or uses precomputed metadata, and returns identified segments or direct jump times.  
  - **Request**:
    ```json
    {
      "videoId": "abc123",
      "query": "sauce-making"
    }
    ```
  - **Response**:
    ```json
    {
      "segmentName": "sauceMaking",
      "startTime": 13.0,
      "endTime": 25.0
    }
    ```
  - The iOS client then updates the player’s current time to `startTime`.

#### 5.3.2 PersonalLens (Week 2)
- **Endpoint**: `GET https://<cloudfunctions-domain>/getPersonalizedFeed?uid={uid}`  
  - **Description**: Generates a recommended feed for a user based on favorites, skill level, watch history, etc.  
  - **Response**:
    ```json
    [
      {
        "videoId": "vid001",
        "score": 0.89
      },
      {
        "videoId": "vid002",
        "score": 0.76
      }
    ]
    ```
  - The client then queries `videos/{videoId}` to get actual metadata and displays them in the recommended feed order.

---

### 5.4 External Dependencies / Integrations
- **Generative AI**: Potentially used for transcript analysis and segment detection (SmartScan).  
- **Push Notifications**: (If used) via Firebase Cloud Messaging for new recommended videos or comment replies.

---

## Summary

This PRD outlines a clear path for building an **iOS** short-form video app for **recipe discovery** using **Firestore**. The focus is on **consumer-only** features, with an emphasis on building a robust vertical slice in Week 1 (feed, watch, interact, and basic search) and adding 2 AI-driven features in Week 2 (SmartScan for direct video segment jumps, and PersonalLens for personalized feed).

By adhering to the above feature requirements, data models, and API contracts, the development team can minimize ambiguity, ensure consistent implementation, and deliver a production-ready application that leverages Firebase’s real-time capabilities and Cloud Functions for AI-driven enhancements.