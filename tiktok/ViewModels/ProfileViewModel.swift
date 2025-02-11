import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var userVideos: [Video] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Properties
    let userId: String
    private let db = Firestore.firestore()
    private var videosListener: ListenerRegistration?
    
    // MARK: - Initialization
    init(userId: String? = nil) {
        // If no userId provided, use current user's ID
        self.userId = userId ?? Auth.auth().currentUser?.uid ?? ""
        
        // Debug log
        print("DEBUG: ProfileViewModel initialized with userId: \(self.userId)")
    }
    
    // MARK: - Public Methods
    func loadData() {
        isLoading = true
        error = nil
        
        // Debug log
        print("DEBUG: Starting to load profile data for userId: \(userId)")
        
        // Fetch user doc
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching user: \(error.localizedDescription)")
                self.error = "Failed to load user data"
                self.isLoading = false
                return
            }
            
            if let user = try? snapshot?.data(as: User.self) {
                DispatchQueue.main.async {
                    self.user = user
                    print("DEBUG: Successfully loaded user: \(user.debugDescription)")
                }
            }
            
            self.isLoading = false
        }
        
        // Setup videos listener
        setupVideosListener()
    }
    
    // MARK: - Private Methods
    private func setupVideosListener() {
        // Remove existing listener if any
        videosListener?.remove()
        
        // Debug log
        print("DEBUG: Setting up videos listener for userId: \(userId)")
        
        // Create new listener
        videosListener = db.collection("videos")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("DEBUG: Error fetching videos: \(error.localizedDescription)")
                    self.error = "Failed to load videos"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No videos found")
                    return
                }
                
                // Update videos
                self.userVideos = documents.compactMap { document in
                    try? document.data(as: Video.self)
                }
                
                print("DEBUG: Loaded \(self.userVideos.count) videos")
            }
    }
    
    // MARK: - Cleanup
    deinit {
        videosListener?.remove()
        print("DEBUG: ProfileViewModel deinitialized")
    }
} 