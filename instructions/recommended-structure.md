tiktok/
├── App/
│   └── tiktokApp.swift   // Main SwiftUI App entry point
├── Models/
│   ├── User.swift                   // Firestore user model
│   └── Video.swift                  // Firestore video model
├── ViewModels/
│   ├── AuthViewModel.swift          // Handles sign-in/sign-up
│   ├── FeedViewModel.swift          // Handles fetching videos, feed logic
│   └── VideoDetailViewModel.swift   // Manages likes/comments for a single video
├── Views/
│   ├── AuthView.swift               // Simple combined login/register or separate them
│   ├── FeedView.swift               // Main feed screen
│   └── VideoDetailView.swift        // Full-screen video player and engagement
├── Services/
│   └── FirebaseService.swift        // Generic Firebase init + Firestore calls
└── Utils/
    └── Logger.swift                 // For debug logging (optional)