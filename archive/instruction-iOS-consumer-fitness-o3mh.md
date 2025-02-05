Below is a detailed Product Requirements Document (PRD) for a fitness/workout consumer video app built exclusively for iOS. The app leverages Firestore as its primary database and is designed for fitness enthusiasts who want to browse, filter, and save workout videos while benefiting from AI-powered enhancements. In this PRD, we specify the project overview, core features, detailed requirements for each feature (including dependencies, variable names, and external API calls), data models, and the API contract.

---

# Project Overview

**Name:** FitStream

**Description:**  
FitStream is an iOS-native social video platform designed specifically for fitness enthusiasts. Users browse a curated feed of workout and exercise videos, filter by workout type (e.g., HIIT, bodybuilding, yoga, cardio), and save their favorite routines. FitStream leverages Firestore for real-time data and integrates AI-powered features that enhance the user experience. Two main AI features are:
- **Workout Jump:** Users can issue natural language commands (e.g., “show warm-up” or “skip to cardio”) to jump to relevant segments in a workout video.
- **Personalized Recommendation:** Based on user workout history and preferences, the system recommends new fitness videos tailored to the user’s fitness level and interests.

**Technical Stack & Dependencies:**
- **iOS Development:** Swift (using SwiftUI/UIKit as needed)
- **Authentication:** Firebase Auth (for secure user sign-in/sign-up)
- **Database:** Google Firestore (for storing video metadata, user profiles, comments, etc.)
- **Media Storage:** Firebase Cloud Storage (for hosting video files and thumbnails)
- **Backend Logic:** Firebase Cloud Functions (for video processing, AI integration, notifications)
- **Push Notifications:** Firebase Cloud Messaging
- **AI Integration:** Firebase Cloud Functions calling external AI APIs (for natural language commands processing in “Workout Jump” and recommendation engine for “Personalized Recommendation”)
- **Networking (iOS):** Use of URLSession or third-party libraries (e.g., Alamofire) for RESTful API calls to the AI endpoints

---

# Features

1. **Video Feed**
   - Display a vertical scrolling list of workout videos.
   - Each video shows a thumbnail, title, workout type, difficulty, and short description.
   - Real-time updates from Firestore ensure the feed stays current.

2. **Video Details & Playback**
   - Detailed view for a selected video that includes full playback, metadata, and interactive elements.
   - Support for likes, comments, and sharing.
   - Integration with the AI “Workout Jump” feature to allow users to jump to specific workout sections.

3. **Search & Filter**
   - Ability to search videos by keywords.
   - Filter videos based on workout type, difficulty level, muscle group targeted, or duration.
   
4. **Saved Collections**
   - Allow users to save favorite videos and create custom workout collections.
   - Provide a “My Workouts” section for quick access to saved videos.

5. **AI-Powered Features**
   - **Workout Jump:** Natural language commands enable users to quickly navigate to workout segments.
   - **Personalized Recommendation:** An AI engine analyzes user preferences and workout history to recommend videos.

6. **Push Notifications**
   - Real-time notifications for new content matching a user’s saved preferences or for AI-generated suggestions.
   - Reminders to check new workout routines or comment on trending videos.

---

# Requirements for Each Feature

### 1. Video Feed
- **Functional Requirements:**
  - On app launch, load a paginated list of video posts from the Firestore `videos` collection.
  - Each post must display:
    - `video_id` (unique identifier)
    - `title`
    - `thumbnailUrl`
    - `workoutType` (e.g., HIIT, bodybuilding)
    - `difficulty` (e.g., beginner, intermediate, advanced)
    - `uploadTime`
- **Dependencies & Data Sources:**
  - Firestore (collection: `videos`)
  - Firebase Cloud Storage (for `thumbnailUrl`)
- **Variable Names & UI Components:**
  - iOS ViewController or SwiftUI View named `VideoFeedView`
  - Video cell UI: `VideoCell` with properties: `videoId`, `titleLabel`, `thumbnailImageView`, `workoutTypeLabel`, `difficultyLabel`
  
### 2. Video Details & Playback
- **Functional Requirements:**
  - When a user selects a video, open a detail view (`VideoDetailView`) that plays the video using AVPlayer.
  - Display video metadata including description, workout type, duration, and upload date.
  - Show interactive buttons for:
    - Liking (POST call to `/videos/{video_id}/like`)
    - Commenting (POST call to `/videos/{video_id}/comment`)
    - Saving video to personal collections (POST call to `/users/{user_id}/saveVideo`)
  - **AI Integration:**  
    - Include a “Workout Jump” button. When tapped, users can input natural language commands.
    - The app calls the AI endpoint (see API Contract below) to receive a timestamp to jump to.
- **Dependencies & Data Sources:**
  - Firestore (`videos` collection for metadata; `comments` subcollection under each video)
  - Firebase Cloud Storage (for video files)
  - Firebase Cloud Functions for AI processing
- **Variable Names & UI Components:**
  - Video Detail View: `VideoDetailView`
  - Interactive buttons: `likeButton`, `commentButton`, `saveButton`, `workoutJumpButton`
  - Video player variable: `avPlayer`
  
### 3. Search & Filter
- **Functional Requirements:**
  - Provide a search bar on the Video Feed screen.
  - Users can enter keywords that match against video `title` and `description`.
  - Include filter options (dropdowns or chips) for:
    - `workoutType` (e.g., cardio, strength)
    - `difficulty`
    - `muscleGroup` (if applicable)
    - `duration` (e.g., short, medium, long)
  - Dynamically update the feed based on search/filter criteria.
- **Dependencies & Data Sources:**
  - Firestore querying capabilities using composite indexes where necessary.
- **Variable Names & UI Components:**
  - Search bar: `videoSearchBar`
  - Filter components: `workoutTypeFilter`, `difficultyFilter`, etc.
  - Function: `performSearch(query: String, filters: [String: String])`
  
### 4. Saved Collections
- **Functional Requirements:**
  - Allow authenticated users to save videos.
  - Maintain a user-specific collection in Firestore (`users` collection, field `savedVideos`: array of video IDs).
  - Provide a “My Workouts” view listing saved videos.
- **Dependencies & Data Sources:**
  - Firestore: Collection `users` with document fields including `savedVideos`
- **Variable Names & UI Components:**
  - User profile view: `UserProfileView`
  - Saved collection view: `SavedVideosView`
  - Variable: `savedVideos` (array of video IDs)
  
### 5. AI-Powered Features

#### A. Workout Jump
- **Functional Requirements:**
  - Users tap the “Workout Jump” button and input a command (e.g., “show warm-up”).
  - The app sends a POST request to the AI endpoint with:
    - `videoId` (string)
    - `command` (string)
  - Receive a response containing a `timestamp` (in seconds) to jump to in the video.
  - The video player then seeks to the provided timestamp.
- **Dependencies:**
  - Firebase Cloud Functions endpoint for AI (e.g., integrated with an external AI API).
- **Variable Names & API Call Details:**
  - API Endpoint: `POST https://<firebase_function_base_url>/ai/workoutJump`
  - Request body JSON:
    ```json
    {
      "videoId": "<video_id>",
      "command": "<user_command>"
    }
    ```
  - Response JSON:
    ```json
    {
      "timestamp": <number>
    }
    ```
  - iOS Function: `performWorkoutJump(videoId: String, command: String)`

#### B. Personalized Recommendation
- **Functional Requirements:**
  - On the home screen or in a dedicated “Recommended” tab, display AI-curated videos.
  - The recommendation engine evaluates the user’s:
    - Saved videos (`savedVideos`)
    - Liked video history
    - Defined workout preferences stored in the user profile (e.g., preferred workout types)
  - The app calls an AI endpoint to fetch recommended videos.
- **Dependencies:**
  - Firebase Cloud Functions endpoint for AI recommendation.
- **Variable Names & API Call Details:**
  - API Endpoint: `GET https://<firebase_function_base_url>/ai/recommendations?user_id=<user_id>`
  - Response JSON:
    ```json
    {
      "recommendations": [
        { "videoId": "<id>", "score": <number> },
        ...
      ]
    }
    ```
  - iOS Function: `fetchPersonalizedRecommendations(userId: String)`

### 6. Push Notifications
- **Functional Requirements:**
  - Utilize Firebase Cloud Messaging to send notifications for:
    - New video uploads that match a user’s fitness interests.
    - AI-generated suggestions or reminders.
  - Notifications trigger from backend events (e.g., on new video upload, via Cloud Functions).
- **Dependencies:**
  - Firebase Cloud Messaging and Cloud Functions.
- **Variable Names & Implementation:**
  - Topic subscription: `fitness_updates_<userId>`
  - Cloud Function triggers to send notifications using the FCM API.

---

# Data Models

### 1. Video Document (Firestore Collection: `videos`)
```json
{
  "video_id": "string",             // Unique video identifier
  "title": "string",
  "description": "string",
  "videoUrl": "string",             // URL to the video file in Cloud Storage
  "thumbnailUrl": "string",         // URL to the thumbnail image
  "workoutType": "string",          // e.g., "HIIT", "Yoga", "Bodybuilding"
  "difficulty": "string",           // e.g., "Beginner", "Intermediate", "Advanced"
  "duration": "number",             // Duration in seconds
  "uploadTime": "timestamp",
  "muscleGroup": "string"           // Optional (e.g., "Upper Body", "Legs")
}
```

### 2. User Document (Firestore Collection: `users`)
```json
{
  "user_id": "string",              // Unique user identifier (from Firebase Auth)
  "name": "string",
  "profileImageUrl": "string",
  "savedVideos": [ "video_id1", "video_id2" ],
  "likedVideos": [ "video_id1", "video_id2" ],
  "workoutPreferences": {           // User-defined workout interests
      "preferredWorkoutTypes": ["HIIT", "Strength"],
      "preferredDifficulty": "Intermediate"
  }
}
```

### 3. Comment Document (Subcollection under each video in Firestore)
```json
{
  "comment_id": "string",           // Unique comment identifier
  "user_id": "string",
  "text": "string",
  "timestamp": "timestamp"
}
```

---

# API Contract

All endpoints below are intended to be invoked by the iOS client (via Swift using URLSession/Alamofire) and are backed by Firebase Cloud Functions.

### 1. Video Feed API
- **Endpoint:** `GET https://<firebase_function_base_url>/videos`
- **Description:** Returns a paginated list of workout videos.
- **Request Parameters:**
  - `limit` (optional, default: 20)
  - `startAfter` (optional, for pagination)
- **Response:** JSON array of video objects (as defined in the Video Document).

### 2. Video Details API
- **Endpoint:** `GET https://<firebase_function_base_url>/videos/{video_id}`
- **Description:** Returns full details for the selected video.
- **Response:** A single video object with all metadata.

### 3. Like Video API
- **Endpoint:** `POST https://<firebase_function_base_url>/videos/{video_id}/like`
- **Description:** Registers a like for the video.
- **Request Body:**
  ```json
  {
    "user_id": "<user_id>"
  }
  ```
- **Response:** Status message and updated like count.

### 4. Comment API
- **Endpoint:** `POST https://<firebase_function_base_url>/videos/{video_id}/comment`
- **Description:** Adds a comment to the video.
- **Request Body:**
  ```json
  {
    "user_id": "<user_id>",
    "text": "<comment_text>"
  }
  ```
- **Response:** The created comment object with `comment_id` and `timestamp`.

### 5. Save Video API
- **Endpoint:** `POST https://<firebase_function_base_url>/users/{user_id}/saveVideo`
- **Description:** Saves a video to the user’s collection.
- **Request Body:**
  ```json
  {
    "video_id": "<video_id>"
  }
  ```
- **Response:** Updated user document status.

### 6. Search Videos API
- **Endpoint:** `GET https://<firebase_function_base_url>/search/videos`
- **Description:** Searches for videos based on query and filters.
- **Request Query Parameters:**
  - `q`: search keyword (matches against title/description)
  - `workoutType` (optional)
  - `difficulty` (optional)
  - `muscleGroup` (optional)
- **Response:** JSON array of matching video objects.

### 7. Workout Jump AI API
- **Endpoint:** `POST https://<firebase_function_base_url>/ai/workoutJump`
- **Description:** Processes a natural language command and returns a timestamp to jump to in the video.
- **Request Body:**
  ```json
  {
    "videoId": "<video_id>",
    "command": "<natural_language_command>"
  }
  ```
- **Response:**
  ```json
  {
    "timestamp": <number>
  }
  ```

### 8. Personalized Recommendation AI API
- **Endpoint:** `GET https://<firebase_function_base_url>/ai/recommendations`
- **Description:** Provides AI-curated video recommendations.
- **Request Query Parameter:**
  - `user_id`: the authenticated user’s ID
- **Response:**
  ```json
  {
    "recommendations": [
      { "videoId": "<video_id>", "score": <number> },
      ...
    ]
  }
  ```

### 9. Push Notification Trigger (Server-Side)
- **Mechanism:** Cloud Functions subscribe to Firestore triggers (e.g., new video uploads) and call the Firebase Cloud Messaging API.
- **Payload Example:**
  ```json
  {
    "to": "<device_token>",
    "notification": {
      "title": "New Workout Video!",
      "body": "A new HIIT routine has been uploaded that matches your interests."
    },
    "data": {
      "videoId": "<video_id>"
    }
  }
  ```

---

This PRD for FitStream defines all the major components needed for a consumer-facing fitness video platform. By detailing the features, precise requirements (including UI variable names, dependencies, and API contracts), and data models, the document leaves little ambiguity for development. The integration of AI features—Workout Jump and Personalized Recommendations—further differentiates the product, ensuring a modern, engaging experience for fitness enthusiasts on iOS.