Below is a detailed, step-by-step implementation checklist that focuses on building out the Week 1 MVP (with placeholders/preparations for Week 2 where needed) in a logical, chronological order. This checklist is designed to be used in an AI-first workflow (e.g., alongside Cursor Composer) and includes high-level headers with actionable sub‑steps.

> **Note:** For your first native iOS project in Swift, I recommend using **SwiftUI** for the UI layer. SwiftUI offers a modern, declarative approach that tends to simplify many aspects of UI development and integrates well with other frameworks (like AVKit for video playback).

---

## 1. Project & Environment Setup

### 1.1. Xcode Project Initialization
- **Create a new SwiftUI project** in Xcode.
  - Select “App” as the template.
  - Name your project (e.g., `FlexibleAIVibeTok`).
- **Set up source control** (e.g., Git) for version tracking.

### 1.2. Firebase Setup
- **Create a Firebase Project:**
  - Go to the [Firebase Console](https://console.firebase.google.com/).
  - Create a new project (e.g., `FlexibleAIVibeTok`).
- **Add iOS App in Firebase:**
  - Register your app’s bundle identifier.
  - Download the `GoogleService-Info.plist` file and add it to your Xcode project.
- **Integrate Firebase SDKs:**
  - Install necessary pods (or use Swift Package Manager) for:
    - Firebase Auth
    - Firebase Firestore
    - Firebase Storage
  - Configure Firebase in your App Delegate or via the SwiftUI app lifecycle (using the new `@main` App struct).

### 1.3. Backend Environment Setup (Firestore & Storage)
- **Firestore:**
  - Define collections/documents as per the PRD (users, videos, videoLikes, savedVideos).
  - Set up security rules that allow authenticated access.
- **Firebase Storage:**
  - Configure Storage rules.
  - Create a folder structure (e.g., `/videos/`) for hosting video files.
- **Firebase Auth:**
  - Enable Email/Password authentication in the Firebase Console.

---

## 2. User Onboarding & Authentication

### 2.1. Authentication Flow
- **Sign-Up & Login UI:**
  - Create SwiftUI views for sign-up and login.
  - Fields: Email, Password, and (optionally) Display Name.
- **Firebase Auth Integration:**
  - Implement functions for:
    - Creating a new account using email/password.
    - Logging in an existing user.
- **User Profile Creation:**
  - On successful sign-up, create a new document in `/users/{userId}` with:
    - `userId`, `email`, `displayName`, and `createdAt` timestamp.
  - **Placeholder for Week 2:** Reserve an `interests` field (array of strings).

### 2.2. Session Management
- **Persist user session:**
  - Use Firebase’s built‑in session persistence.
- **Implement error handling and user feedback** for authentication failures.

---

## 3. Video Feed (Home Screen)

### 3.1. Firestore Data Query
- **Query Setup:**
  - Use Firestore’s SDK to query the `/videos` collection.
  - Order videos by `createdAt` (descending) and limit to a reasonable number (e.g., 20).
- **Data Model Mapping:**
  - Map Firestore documents to your Swift model (e.g., `Video` struct).

### 3.2. UI Implementation
- **Create a vertical feed using SwiftUI:**
  - Use a `ScrollView` or `List` to display video cards.
- **Design Video Cards:**
  - Display a thumbnail (loaded from `thumbnailUrl`).
  - Show title/description.
  - Display engagement stats (e.g., likesCount, commentsCount).

### 3.3. Placeholder for Future Enhancements (Week 2)
- **Note:** Ensure that your data model includes reserved fields (e.g., `modelUsed`) to support future automated AI-generated content.

---

## 4. Video Playback

### 4.1. Full-Screen Video Player
- **Navigation:**
  - Configure navigation so that tapping a video card navigates to a detailed view.
- **AVKit Integration:**
  - Use `AVKit`’s `VideoPlayer` component in SwiftUI.
  - Retrieve the `videoUrl` from Firestore to load the video.
- **Playback Controls:**
  - Enable basic controls such as play, pause, and scrubbing.

---

## 5. User Engagement (Likes & Comments)

### 5.1. Likes Functionality
- **UI:**
  - Add a “like” (heart) button on the video detail screen.
- **Firestore Write:**
  - On tap, perform two actions:
    - Increment the `likesCount` in the video document (use Firestore’s atomic increment).
    - Optionally create/update a document in `/videoLikes/{videoId}/userLikes/{userId}` with a timestamp.
- **Considerations for Future:**
  - If planning to move to Cloud Functions later, modularize your like logic to easily swap in a server-side endpoint.

### 5.2. Comments Functionality
- **UI:**
  - Add a comments section on the video detail screen.
  - Include a text field and submit button for new comments.
- **Firestore Integration:**
  - On comment submission, write a new document in `/videos/{videoId}/comments` with:
    - `commentId`, `userId`, `text`, and `timestamp`.
- **Display Comments:**
  - Query and display comments in real-time from Firestore.

---

## 6. Video Saving (Bookmarking)

### 6.1. Save Video Feature
- **UI:**
  - Add a “Save” button on the video detail view.
- **Firestore Write:**
  - On tap, add a document to `/users/{userId}/savedVideos/{videoId}` including:
    - `videoId` and `savedAt` (timestamp).
- **Feedback:**
  - Provide user feedback (e.g., UI state change) indicating the video has been saved.

---

## 7. Manual Content Management (Admin)

### 7.1. Video Upload Process (External / Manual)
- **Manual Upload Steps:**
  - Upload pre-generated AI video files to Firebase Storage under `/videos/`.
  - For each video file, manually create a corresponding Firestore document in `/videos` with:
    - `videoId`, `title`, `thumbnailUrl`, `videoUrl` (the public download URL), `category`, `likesCount` (default 0), `commentsCount` (default 0), and `createdAt` timestamp.
- **Documentation:**
  - Maintain a document (or script notes) that details the manual upload process to facilitate Week 2 automation later.

---

## 8. Testing, Debugging & Iteration

### 8.1. End-to-End Testing
- **Authentication:**
  - Test sign-up, login, and user profile creation.
- **Video Feed:**
  - Verify that videos load from Firestore and display correctly.
- **Playback:**
  - Ensure video playback functions as expected using AVKit.
- **Engagement:**
  - Test liking a video (ensure Firestore updates correctly).
  - Test posting and retrieving comments.
- **Saving:**
  - Verify that the save function creates records in the user’s saved videos subcollection.

### 8.2. Debugging & Logging
- **Implement Logging:**
  - Use simple print statements or a logging framework to capture errors.
- **Error Handling:**
  - Ensure that user-facing errors (e.g., network issues) are handled gracefully.

---

## 9. Preparations for Week 2 Enhancements

### 9.1. Code Modularity & Interface Design
- **Abstract Video Generation:**
  - Create a modular function/interface (e.g., `generateVideo(prompt: String, options: [String: Any])`) that currently can be a placeholder.
- **Data Model Reservations:**
  - Ensure your Firestore video documents have reserved fields like `modelUsed` for AI provider identifiers.
- **Cloud Function Placeholders:**
  - Document API contracts (e.g., endpoints for generating videos, submitting suggestions, personalized recommendations) that will be implemented later.
- **Future Recommendations:**
  - Reserve space in your user documents for interests and in your feed query logic to integrate future personalized ranking.

---

## 10. Cursor Composer Integration & Workflow Optimization

### 10.1. Using Cursor Composer in the Workflow
- **Task Breakdown:**
  - Feed this checklist into Cursor Composer to generate initial code stubs or templates.
- **Snippet Generation:**
  - Use agentic capabilities (e.g., generating code for Firebase integration or SwiftUI views) based on the checklist steps.
- **Iteration:**
  - As you implement each step, update the checklist with any additional subtasks identified via Cursor Composer’s recommendations.

---

By following this checklist in a chronological manner—from environment setup through user flows, video playback, and engagement features—you’ll build a solid Week 1 MVP. The structure and modular design will also ensure you’re prepared to integrate more advanced AI-generated content and personalized recommendations in Week 2 without being hamstrung by early architectural choices.

Feel free to ask if you need further elaboration on any step or additional guidance on using Cursor Composer in your workflow!