import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DressingItemListView()
            }
            .tabItem {
                Label("Dressing", systemImage: "hanger")
            }

            NavigationStack {
                StyleAdvisorView()
            }
            .tabItem {
                Label("Conseils", systemImage: "message.circle")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle")
            }

            SocialFeedView()
            .tabItem {
                Label("Social", systemImage: "person.2.fill")
            }
        }
        .tint(.pink)
    }
}
