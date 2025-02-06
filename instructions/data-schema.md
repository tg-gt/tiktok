# Data Schema Documentation

## Firebase Collections Schema

### 1. Users Collection
**Path:** `/users/{userId}`
```typescript
interface User {
  userId: string;           // Firebase Auth UID
  email: string;           // User's email address
  displayName: string;    // Optional display name
  interests?: string[];    // Array of interest categories (for Week 2)
  avatarURL?: string;    // Array of interest categories (for Week 2)
  createdAt: Timestamp;    // Account creation timestamp
}
```

### 2. Videos Collection
**Path:** `/videos/{videoId}`
```typescript
interface Video {
  videoId: string;         // Unique video identifier
  title: string;          // Video title
  thumbnailUrl: string;   // URL to video thumbnail in Firebase Storage
  videoUrl: string;       // URL to video file in Firebase Storage
  category: string;       // Video category/theme
  likesCount: number;     // Total number of likes
  commentsCount: number;  // Total number of comments
  createdAt: Timestamp;   // Video creation timestamp
  modelUsed?: string;     // Optional: AI model used to generate (for Week 2)
}
```

### 3. Comments Subcollection
**Path:** `/videos/{videoId}/comments/{commentId}`
```typescript
interface Comment {
  commentId: string;      // Unique comment identifier
  userId: string;         // User who made the comment
  text: string;          // Comment content
  timestamp: Timestamp;   // Comment creation time
}
```

### 4. Video Likes Collection
**Path:** `/videoLikes/{videoId}/userLikes/{userId}`
```typescript
interface VideoLike {
  userId: string;         // User who liked the video
  likedAt: Timestamp;    // When the like was created
}
```

### 5. Saved Videos Subcollection
**Path:** `/users/{userId}/savedVideos/{videoId}`
```typescript
interface SavedVideo {
  videoId: string;        // Reference to saved video
  savedAt: Timestamp;     // When the video was saved
}
```

### 6. Suggestions Collection (Week 2)
**Path:** `/suggestions/{suggestionId}`
```typescript
interface Suggestion {
  userId: string;         // User who made the suggestion
  text: string;          // Suggestion content
  status: 'pending' | 'approved' | 'rejected';  // Suggestion status
  createdAt: Timestamp;  // When suggestion was made
}
```

## Firebase Storage Structure

### Video Files
**Path:** `/videos/{videoId}.mp4`
- Stores the actual video content
- Referenced by `videoUrl` in Videos collection

### Thumbnail Files
**Path:** `/thumbnails/{videoId}.jpg`
- Stores video thumbnail images
- Referenced by `thumbnailUrl` in Videos collection

## Relationships

### User -> Videos
- One-to-many: A user can create multiple videos
- Tracked via `userId` in video documents

### User -> Likes
- Many-to-many: Users can like multiple videos, videos can be liked by multiple users
- Tracked in `videoLikes` collection

### User -> Saved Videos
- Many-to-many: Users can save multiple videos
- Tracked in `savedVideos` subcollection

### Video -> Comments
- One-to-many: A video can have multiple comments
- Tracked in `comments` subcollection

## Indexes Required

1. Videos Collection:
```
- createdAt DESC (for feed ordering)
- category, createdAt DESC (for category filtering)
```

2. Comments Subcollection:
```
- timestamp DESC (for comment ordering)
```

3. SavedVideos Subcollection:
```
- savedAt DESC (for saved videos list)
```

## Security Rules Considerations

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
    
    // Videos are publicly readable
    match /videos/{videoId} {
      allow read: if true;
      allow write: if request.auth != null;  // Authenticated users only
    }
    
    // Comments require authentication
    match /videos/{videoId}/comments/{commentId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Likes require authentication
    match /videoLikes/{videoId}/userLikes/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Performance Considerations

1. Denormalization:
   - Store basic video metadata in savedVideos to avoid extra queries
   - Cache frequently accessed user data

2. Pagination:
   - Implement cursor-based pagination for video feed
   - Limit initial query size (recommended: 20 videos)


## Migration Strategy

1. Initial Setup (Week 1):
   - Create base collections
   - Set up indexes
   - Upload sample content

2. Week 2 Additions:
   - Add AI-related fields
   - Create suggestions collection
   - Expand user profiles with preferences