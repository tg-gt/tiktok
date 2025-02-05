
# Step-by-Step Implementation Checklist

Below is a **Week 1** development checklist that maps to your PRD. I’ll call out where you might use **Cursor** prompts to speed up coding. The steps assume **SwiftUI** and minimal or no Cloud Functions for now.

---

## A. Project Initialization

1. **Create Xcode Project (SwiftUI + iOS App)**  
   - In Xcode, choose *App* template, language = Swift, interface = SwiftUI.  
   - Minimum iOS version: **iOS 15** (recommended).

2. **Install Firebase SDK**  
   - Add Firebase to your project via Swift Package Manager or Cocoapods.  
   - In `AppDelegate` or `App` struct, configure Firebase:  
     ```swift
     import Firebase
     
     @main
     struct FlexibleAIVibeTokApp: App {
         init() {
             FirebaseApp.configure()
         }
         var body: some Scene {
             WindowGroup {
                 ContentView()
             }
         }
     }
     ```

3. **Set Up Firebase (Console)**  
   - **Create a Firebase project** in the [Firebase console](https://console.firebase.google.com).  
   - Add iOS bundle ID, download the `GoogleService-Info.plist`, and include it in your Xcode project.  
   - **Enable Firestore** and **Firebase Auth** in the console.

4. **(Optional) Cursor Prompt Example**  
   - “Generate SwiftUI skeleton code for an iOS app that integrates Firebase, including a minimal `App` struct that configures Firebase.”  

---

## B. User Onboarding & Authentication

1. **Enable Firebase Auth** with Email/Password  
   - In Firebase console > Authentication, enable Email/Password sign-in.  
2. **Build a SwiftUI View for Registration/Login**  
   - Create a SwiftUI view `AuthView` with two forms: **Login** and **Register**.  
   - Implement sign-up code in a ViewModel that calls `Auth.auth().createUser(withEmail: password:)`.  
   - Implement sign-in code that calls `Auth.auth().signIn(withEmail: password:)`.  
3. **Store User Profiles in Firestore**  
   - On successful sign-up, create a doc in `users/{userId}` with fields: `userId`, `email`, `displayName` (optional), `createdAt`.  
   - Use the `AuthResult.user.uid` as the `userId`.
4. **Navigation / State Flow**  
   - If user is logged in, show your main feed. If not, show the `AuthView`.  
5. **(Optional) Cursor Prompt Example**  
   - “Generate a SwiftUI `AuthView` that handles email/password registration and login with Firebase, and on success transitions to a `MainFeedView`.”  

---

## C. Video Feed (Home Screen)

1. **Firestore Data Model**  
   - Collection: `videos`  
     ```swift
     struct Video: Identifiable, Codable {
         @DocumentID var id: String?
         var title: String
         var thumbnailUrl: String
         var videoUrl: String
         var category: String
         var likesCount: Int
         var commentsCount: Int
         var createdAt: Timestamp
     }
     ```
2. **Fetch Videos**  
   - In your `MainFeedViewModel`, query Firestore:
     ```swift
     Firestore.firestore().collection("videos")
         .order(by: "createdAt", descending: true)
         .limit(to: 20)
         .addSnapshotListener { snapshot, error in
             // parse into [Video]
         }
     ```
3. **Display in a SwiftUI List**  
   - Show a vertical list of `VideoRowView` or similar.  
   - Each row can have the thumbnail, title, and engagement stats.  
4. **Thumbnail Handling**  
   - For a quick solution, you can use SwiftUI’s `AsyncImage(url: URL(string: video.thumbnailUrl))` (iOS 15+).  
5. **(Optional) Cursor Prompt Example**  
   - “Generate a SwiftUI list to display an array of `Video` objects, each showing a title, thumbnail, and like count.”

---

## D. Video Playback (Detail Screen)

1. **Navigation from Feed**  
   - Tapping a row in the list navigates to `VideoDetailView(video: Video)`.  
2. **SwiftUI Video Player**  
   - For iOS 14+, use `AVPlayer` with a custom SwiftUI wrapper. For iOS 15+, consider `VideoPlayer`:  
     ```swift
     import AVKit
     
     struct VideoDetailView: View {
         let video: Video
         @State private var player = AVPlayer()
         
         var body: some View {
             VStack {
                 VideoPlayer(player: player)
                     .onAppear {
                         if let url = URL(string: video.videoUrl) {
                             player.replaceCurrentItem(with: AVPlayerItem(url: url))
                             player.play()
                         }
                     }
             }
         }
     }
     ```
3. **Controls & Full-Screen Behavior**  
   - SwiftUI’s `VideoPlayer` provides basic controls (play/pause, scrub).  
   - For advanced TikTok-like behavior (auto-play on scroll, pause on scroll away), you’d need to sync the feed scroll with playback. That can be a nice-to-have.  

---

## E. User Engagement (Likes & Comments)

### Likes

1. **Data Model**  
   - Firestore doc in `/videos/{videoId}` with `likesCount`.  
   - Sub-collection in `/videoLikes/{videoId}/userLikes/{userId}` (optional if you want to track *which* users liked the video).  
2. **Client-Side Implementation**  
   - In `VideoDetailView`, have a heart button that calls a function:
     ```swift
     func likeVideo(videoId: String) {
         let videoRef = Firestore.firestore().collection("videos").document(videoId)
         videoRef.updateData(["likesCount": FieldValue.increment(Int64(1))])
         
         // Optionally store userLikes doc:
         let userId = Auth.auth().currentUser!.uid
         let userLikeRef = Firestore.firestore()
             .collection("videoLikes").document(videoId)
             .collection("userLikes").document(userId)
         userLikeRef.setData(["likedAt": FieldValue.serverTimestamp()])
     }
     ```
   - Also handle “unlike” if desired, decrementing the count.

### Comments

1. **Data Model**  
   - Subcollection `/videos/{videoId}/comments/{commentId}` with fields `userId`, `text`, `timestamp`.  
2. **Client-Side Implementation**  
   - In `VideoDetailView`, have a text field for a new comment. On submit:  
     ```swift
     let commentId = UUID().uuidString
     let commentData: [String: Any] = [
         "commentId": commentId,
         "userId": userId,
         "text": commentText,
         "timestamp": FieldValue.serverTimestamp()
     ]
     videoRef.collection("comments").document(commentId).setData(commentData)
     
     // Optionally increment commentsCount on the video doc:
     videoRef.updateData(["commentsCount": FieldValue.increment(Int64(1))])
     ```
   - List comments in a sub-view by querying the subcollection.

---

## F. Video Saving (Bookmarking)

1. **Data Model**  
   - `/users/{userId}/savedVideos/{videoId}` with fields: `videoId`, `savedAt`.  
2. **Client-Side**  
   - In `VideoDetailView`, a “Save” button calls:
     ```swift
     let userId = Auth.auth().currentUser!.uid
     let savedRef = Firestore.firestore().collection("users")
         .document(userId).collection("savedVideos").document(video.id)
     
     savedRef.setData([
         "videoId": video.id,
         "savedAt": FieldValue.serverTimestamp()
     ])
     ```
3. **Display Saved Videos**  
   - Provide a separate `SavedView` that fetches documents from `/users/{userId}/savedVideos` and then fetches the corresponding `Video` docs (or store all needed fields in the saved doc).

---

## G. Manual Content Management

1. **Video File Upload**  
   - In Firebase console > Storage, upload your AI-generated `.mp4` file.  
2. **Firestore Document Creation**  
   - In Firebase console > Firestore > `videos` collection:  
     ```json
     {
       "videoId": "someVideoId",
       "title": "My AI Video",
       "thumbnailUrl": "https://firebasestorage.googleapis.com/...",
       "videoUrl": "https://firebasestorage.googleapis.com/...",
       "category": "Test",
       "likesCount": 0,
       "commentsCount": 0,
       "createdAt": <timestamp>
     }
     ```
3. **Repeat** for as many videos as you want in your feed.  

---

## H. Testing & QA

1. **Local Testing**  
   - Use the iOS Simulator or a physical device.  
   - Create multiple Firebase test users with the `name+1@gmail` trick.  
2. **Smoke Test**:
   - **Sign Up** a new user, sign out, sign in again.  
   - Verify the feed loads.  
   - Tap a video to watch it.  
   - Like the video; ensure `likesCount` increments in the UI (can confirm in Firestore console).  
   - Comment on a video, see the comment appear and increment `commentsCount`.  
   - Save a video, then check your saved videos list.  
3. **Edge Cases**  
   - No internet connection.  
   - Rapid likes on the same video.  
   - No videos in the feed (empty state).

---

## I. AI-First Development Workflow (Using Cursor)

Here’s a quick sample flow for each major step:

1. **Prompt Cursor**: “Generate a SwiftUI `LoginView` that uses Firebase email/password auth.”  
2. **Review & Tweak**: Inspect the generated code for correctness (e.g., import statements, function signatures).  
3. **Refactor**: If code is incomplete or uses older Firebase patterns, ask follow-up prompts.  
4. **Implement & Test**: Run the code on the simulator, fix any compile/run-time issues.  
5. **Iterate**: Proceed to the next feature (feed, video detail, likes, etc.) with similar AI prompts.  
6. **Refine**: Once you have a minimal working version, you can refine UI, add error handling, etc.

---

## J. Prepare for Week 2 Expansion

1. **Leave Stubs for AI Generation**  
   - You might create a placeholder function or Cloud Function stub named `generateAIContent(prompt: String) -> String?` so that in Week 2 you can integrate with an external API.  
2. **Store Potential Extra Fields**  
   - If you want to track the **AI model** or **prompt** used to generate a video, add those fields (empty for now).  
3. **Future Recommendation Logic**  
   - If you plan to reorder the feed based on user preferences, store user interest tags in `/users/{userId}`.  
4. **Suggestions Collection**  
   - Optionally create an empty `suggestions` collection to confirm the schema. (e.g., `userId`, `text`, `status`, `createdAt`).

---

# Final Thoughts

By following this step-by-step approach—focusing on **SwiftUI**, **direct Firestore writes**, and minimal overhead—you’ll rapidly get a TikTok-like MVP working. Then, in **Week 2**, you’ll be well-positioned to layer in:

- **Automated AI content generation** (replacing manual uploads).  
- **Recommendation Engine** (query reordering or server-side ranking logic).  
- **Suggestion / feedback** features.  

And throughout, you can rely on **Cursor** (or any AI code assistant) to generate boilerplate and help with repetitive coding tasks. Just remember to test and tweak the generated code to ensure it aligns with the latest Swift, Firebase, and SwiftUI best practices. 

---

**Good luck with your Week 1 MVP!** If anything in the checklist needs elaboration—or if you run into specific code issues—just let me know, and we can drill down further.