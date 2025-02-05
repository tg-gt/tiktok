# Project Overview

**ReelAI (Fitness Coach Niche)**
We are building an AI-first mobile application (an Android app using Kotlin) that reimagines the TikTok experience from the ground up. Our Week 1 goal is to deliver a “vertical slice” of functionality targeting a **Fitness Coach** as the primary user persona. This means the app will support a Fitness Coach user uploading, editing, and publishing workout videos. It will handle the entire workflow from recording/uploading a raw video to publishing it with difficulty-level tags, muscle-group categories, and exercise timestamps.

For Week 2, we will expand with AI-driven features (e.g., smart editing, AI recommendations) that revolutionize content creation and engagement.

## Tech Stack & Dependencies
1. **Kotlin** (for Android) – Native mobile development  
2. **Firebase Auth** – Secure user authentication and social logins  
3. **Firebase Cloud Storage** – For storing user-uploaded video content  
4. **Firestore** – NoSQL database for user profiles, video metadata, comments, etc.  
5. **Cloud Functions (Firebase)** – Serverless backend logic for video processing triggers and AI calls  
6. **Generative AI in Firebase** – Intelligent content editing and suggestions (Week 2)  
7. **Cloud Messaging** – Push notifications for user engagement (e.g., comments, likes)  
8. **OpenShot Video Editing API (AWS)** – Programmatic video editing features, e.g., trimming, transitions  
9. **AWS SDK** – Integration with OpenShot’s AWS Marketplace endpoint  
10. **Environment Variables** –  
   - `FIREBASE_API_KEY`  
   - `OPENSHOT_API_KEY`  
   - `FIREBASE_PROJECT_ID`  
   - `CLOUD_FUNCTIONS_BASE_URL` (where our serverless functions are hosted)  

---

# Features

Below are the core features for the Week 1 vertical slice. Each feature is an end-to-end flow that satisfies one or more user stories for our Fitness Coach user.

1. **User Authentication**  
   - Fitness Coaches can sign up and log in using Firebase Auth.  
   - Supports social logins (e.g., Google) for easy onboarding.

2. **Video Upload & Processing**  
   - Coaches upload workout videos (recorded in-app or from camera roll).  
   - Video is stored in Firebase Cloud Storage.  
   - A background Cloud Function triggers video processing on OpenShot.

3. **Video Metadata Management**  
   - Coaches can label each video with:  
     - **Difficulty Level** (`beginner`, `intermediate`, `advanced`)  
     - **Muscle Group(s)** (e.g., `legs`, `arms`, `core`, etc.)  
     - **Exercise Timestamps** (e.g., `0:00 Warmup`, `3:45 Cardio`, `10:00 Cool Down`)  
   - This metadata is saved in Firestore for quick retrieval.

4. **Publishing & Sharing**  
   - Once processing is done, coaches can publish the video to the feed.  
   - The feed is *limited in Week 1* to show only the user’s own videos (or a public feed if time permits).

5. **Video Playback**  
   - Users can watch videos in a TikTok-style fullscreen video player.  
   - Timestamps show chapters or sections (e.g., Warmup, Main Workout, Cool Down).

6. **Engagement (Likes & Comments)**  
   - Other users (or the same user for testing) can like and comment on the video.  
   - Comments and likes are stored in Firestore, tied to the video’s document.

**Week 2 Features (AI Expansion) - Preview**  
1. **SmartEdit**  
   - AI-based editing commands, e.g., “remove awkward pause,” “enhance lighting,” etc.  
   - Automatic scene detection for easy trimming.  
2. **TrendLens**  
   - AI-suggested hashtags, optimal video length, recommended trending music, etc.  

---

# Requirements for Each Feature

### 1. User Authentication
**Description:** Provide secure sign-up, login, and session management for the Fitness Coach user.  
1. **Requirements:**
   - **Firebase Auth** must be initialized in the Kotlin app using `FIREBASE_API_KEY` and `FIREBASE_PROJECT_ID`.  
   - Must allow **email/password** sign-up and **Google OAuth**.  
   - **User object** must be created in Firestore upon first sign-up with at least the following fields:  
     - `uid` (Firebase user ID)  
     - `email`  
     - `displayName` (if available from social login)  
     - `createdAt` (timestamp)  

2. **Dependencies:**  
   - Firebase Auth SDK (Android/Kotlin)  
   - Firestore SDK (for storing user profiles)

3. **Acceptance Criteria:**  
   - Fitness Coach can sign up via email/password or Google.  
   - Coach is automatically logged in on successful sign-up.  
   - Auth state is persisted across app restarts.  

---

### 2. Video Upload & Processing
**Description:** Fitness Coach can upload a video; video is stored in Firebase Storage and processed by OpenShot.  
1. **Workflow:**
   - Coach selects a video from device gallery or records in-app.  
   - Video is uploaded to **Firebase Cloud Storage** under path: `videos/{userId}/{videoId}.mp4`.  
   - A **Cloud Function** (`onVideoUpload`) is triggered once the file is successfully uploaded.  
   - The Cloud Function calls **OpenShot API** to process/transform the video if needed (e.g., basic trimming).  
   - Processed video is then stored or replaced in Firebase Storage.  
   - The final video URL is saved in Firestore under `videos/{videoId}/videoUrl`.  

2. **Dependencies:**  
   - Firebase Cloud Storage  
   - Cloud Functions for triggers  
   - OpenShot AWS Marketplace API, called via `AWS SDK` or direct REST calls to `OPENSHOT_API_KEY` endpoint  

3. **Variable Names:**  
   - `storageRef` → reference to Firebase Storage  
   - `videoFileUri` → local URI before upload  
   - `videoId` → auto-generated ID for each video (Firestore doc ID)  
   - `processVideoFunctionUrl` → environment variable for the Cloud Function endpoint (if needed)

4. **Acceptance Criteria:**  
   - Coach can successfully upload a video from the app.  
   - The video is processed with no user intervention required.  
   - The processed video URL is accessible from Firestore.  

---

### 3. Video Metadata Management
**Description:** Allows the Coach to label each uploaded video with difficulty levels, muscle groups, and exercise timestamps.  
1. **Workflow & Requirements:**
   - After uploading/processing, the Coach is prompted to fill out metadata:  
     - **Title** (text input)  
     - **Description** (multi-line text)  
     - **Difficulty** (enum: `beginner`, `intermediate`, `advanced`)  
     - **Muscle Groups** (multi-select: `arms`, `legs`, `core`, `back`, `chest`, etc.)  
     - **Timestamps** (Coach can add structured timestamp fields like `[time, label]`)  
   - This metadata is stored in Firestore in the video document:  
     ```
     videos
       └── {videoId}
           ├── title: string
           ├── description: string
           ├── difficulty: string
           ├── muscleGroups: array of strings
           ├── timestamps: array of objects [{ timestampSec: number, label: string }, ...]
           └── videoUrl: string
     ```

2. **Dependencies:**  
   - Firestore for storing metadata  
   - Kotlin UI for collecting metadata from the user  

3. **Acceptance Criteria:**  
   - Coach can select from a predefined set of muscle groups.  
   - Coach can only choose one difficulty level.  
   - Timestamps must include a `timestampSec` (parsed from “mm:ss”) and a `label`.  
   - All metadata saves successfully to Firestore.  

---

### 4. Publishing & Sharing
**Description:** Fitness Coach can publish videos to a public feed or personal feed.  
1. **Requirements:**
   - **Publish Button** triggers an update to the video document, setting `status = "published"`.  
   - A minimal feed displays published videos sorted by `createdAt` or `publishedAt`.  
   - **Week 1** scope: Only show the same user’s published videos in the feed. If time allows, we can have a public feed of all videos.  

2. **Dependencies:**  
   - Firestore for listing published videos  
   - Kotlin UI for feed design  

3. **Acceptance Criteria:**  
   - Once published, the video is visible in the feed.  
   - The Coach sees their newly published video at the top of the feed.  

---

### 5. Video Playback
**Description:** Users (including the Coach) can view a video in a swipe-based, full-screen player.  
1. **Workflow & Requirements:**  
   - The app fetches video metadata (title, difficulty, timestamps, etc.) and displays it in the UI.  
   - The **Video Player** (e.g., ExoPlayer in Kotlin) streams from the video’s Storage URL.  
   - Timestamps appear as clickable chapters (Week 1 can be minimal: maybe a simple list that jumps the playback to the specified time).  

2. **Dependencies:**  
   - ExoPlayer or other Android video player  
   - Firestore to retrieve metadata (timestamps, etc.)  

3. **Acceptance Criteria:**  
   - User can tap on a timestamp label to jump to that point in the video.  
   - Video playback is smooth and ends without error.  

---

### 6. Engagement (Likes & Comments)
**Description:** A minimal engagement layer so the Coach can see how users (or themselves, for testing) respond.  
1. **Requirements:**  
   - **Likes**:  
     - A user can toggle like/unlike on a video.  
     - The total like count is stored in Firestore under `videos/{videoId}/likeCount`.  
     - Each user’s like is stored in a sub-collection or separate doc to avoid double-likes.  
   - **Comments**:  
     - A user can post text comments.  
     - Comments stored in `videos/{videoId}/comments/{commentId}` with fields: `authorId`, `text`, `createdAt`.  

2. **Dependencies:**  
   - Firestore for likes/comments  
   - Firebase Auth to identify user  

3. **Acceptance Criteria:**  
   - The total like count updates instantly after toggling a like.  
   - The comment appears in a comment list sorted by `createdAt`.  

---

# Data Models

Below are the primary Firestore collections and documents used in Week 1:

```
/users
  └── {userId}
      ├── displayName: string
      ├── email: string
      ├── createdAt: timestamp

/videos
  └── {videoId}
      ├── title: string
      ├── description: string
      ├── difficulty: string (beginner|intermediate|advanced)
      ├── muscleGroups: string[] (["arms", "legs", "core", ...])
      ├── timestamps: [
      │     {
      │       timestampSec: number,
      │       label: string
      │     },
      │     ...
      │   ]
      ├── videoUrl: string (Firebase Storage URL)
      ├── likeCount: number
      ├── status: string (draft|published)
      ├── createdAt: timestamp
      ├── publishedAt: timestamp

/videos/{videoId}/comments
  └── {commentId}
      ├── authorId: string
      ├── text: string
      ├── createdAt: timestamp

/videos/{videoId}/likes
  └── {userId}
      ├── likedAt: timestamp
```

**Important Fields:**
- `videoId`: Firestore auto-generated ID for the video document.  
- `likeCount`: An aggregated integer count to display total likes quickly.  
- `status`: `draft` until coach decides to publish, then set to `published`.  

---

# API Contract

We will use a combination of:

1. **Firebase SDK Methods (Client-side in Kotlin)**  
   - `FirebaseAuth.getInstance().signInWithEmailAndPassword(...)`  
   - `FirebaseAuth.getInstance().signInWithCredential(GoogleAuthProvider.getCredential(...))`  
   - `FirebaseStorage.getInstance().reference.child("videos/$userId/$videoId.mp4").putFile(uri)`  
   - `Firestore.collection("videos").document(videoId).set(videoDataMap)`  
   - `Firestore.collection("videos").document(videoId).collection("comments").add(commentData)`  
   - etc.

2. **Cloud Functions Endpoints** (Invoked automatically or via HTTP calls)  
   - **Trigger**: `onFinalize` for `videos/{userId}/{videoId}.mp4` in Cloud Storage.  
     - This function calls the OpenShot API to process the video.  
   - **HTTP Function** (optional for advanced tasks):  
     - `POST /processVideo` – Manually trigger or debug the video processing.  
       - **Request Body**:
         ```json
         {
           "videoStoragePath": "videos/{userId}/{videoId}.mp4",
           "videoId": "{videoId}"
         }
         ```
       - **Response**:
         ```json
         {
           "status": "success",
           "processedVideoUrl": "https://storage.googleapis.com/..."
         }
         ```

3. **OpenShot AWS Marketplace API**  
   - **Endpoint**: `https://{openshot-api-url}/projects/{projectId}/clips` (example)  
   - **API Key**: `OPENSHOT_API_KEY` (stored as an environment variable on Cloud Functions)  
   - **Payload**:  
     ```json
     {
       "videoUrl": "https://storage.googleapis.com/...",
       "actions": [
         {"action": "trim", "startSec": 0, "endSec": 120},
         {"action": "addTransition", "type": "fadeIn", "durationSec": 2}
       ]
     }
     ```
   - **Response**:  
     ```json
     {
       "status": "completed",
       "downloadUrl": "https://processed-video-url..."
     }
     ```

**Usage Flow:**  
1. Cloud Storage finalizes upload → `onFinalize` Cloud Function triggers → calls OpenShot API with `videoUrl`.  
2. OpenShot processes → returns `downloadUrl`.  
3. Cloud Function updates Firestore document: `videos/{videoId}/videoUrl = processedUrl`.  

---

### Summary of Flow
1. **User signs up/logs in** (Firebase Auth).  
2. **User uploads video** (Firebase Storage).  
3. **Cloud Function** triggers, calls **OpenShot** to process video.  
4. **Firestore** updated with processed video URL.  
5. **Coach** adds metadata (difficulty, muscle groups, timestamps).  
6. **Coach publishes** the video → the feed updates.  
7. **Users** can watch the video, like/comment as part of the engagement flow.  

That completes the **Week 1** vertical slice for the Fitness Coach.  
For **Week 2**, we will integrate advanced AI features (SmartEdit, TrendLens, etc.) using **Generative AI in Firebase** or external LLM-based services. This will allow natural language video editing and AI-based content recommendations, as well as auto-captioning, highlight detection, or advanced user analytics.

---

**End of PRD**  
This document should leave no ambiguity about which services, variable names, environment variables, data models, or API endpoints to use. Upon completion of Week 1, we expect a deployed, end-to-end experience for a Fitness Coach user uploading, editing, and publishing workout videos with basic engagement features. Week 2 builds upon this foundation with AI-driven innovations.