import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    // MARK: - Properties
    @State private var selectedTab = 0
    @State private var showUploadSheet = false
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Home")
            }
            .tag(0)
            
            // Upload Tab (Button)
            Color.clear
                .tabItem {
                    Image(systemName: "plus.square")
                    Text("Upload")
                }
                .tag(1)
                .onAppear {
                    if selectedTab == 1 {
                        showUploadSheet = true
                        selectedTab = 0 // Reset to home tab
                    }
                }
            
            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(2)
        }
        .sheet(isPresented: $showUploadSheet) {
            UploadView()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                showUploadSheet = true
                selectedTab = 0 // Reset to home tab
            }
        }
    }
}

// MARK: - Preview Provider
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
} 