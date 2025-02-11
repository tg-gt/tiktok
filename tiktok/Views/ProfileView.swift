import SwiftUI
import FirebaseAuth

// MARK: - ProfileView
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Grid Layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // MARK: - Initialization
    init(userId: String? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader
                
                // Stats View
                statsView
                
                // Videos Grid
                videosGrid
            }
        }
        .navigationTitle(viewModel.user?.displayName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show settings button if it's the current user's profile
            if Auth.auth().currentUser?.uid == viewModel.userId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onAppear {
            print("DEBUG: ProfileView appeared")
            viewModel.loadData()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Avatar
            AsyncImage(url: URL(string: viewModel.user?.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            // User Info
            VStack(spacing: 5) {
                Text(viewModel.user?.displayName ?? "No Name")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        HStack(spacing: 40) {
            VStack {
                Text("\(viewModel.userVideos.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Videos")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Add more stats here as needed
        }
        .padding(.vertical)
    }
    
    // MARK: - Videos Grid
    private var videosGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(viewModel.userVideos) { video in
                NavigationLink(destination: VideoDetailView(video: video)) {
                    VideoThumbnail(video: video)
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Settings Button
    private var settingsButton: some View {
        Menu {
            Button(role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "gear")
        }
    }
}

// MARK: - Video Thumbnail View
struct VideoThumbnail: View {
    let video: Video
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Preview Provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthViewModel())
        }
    }
} 