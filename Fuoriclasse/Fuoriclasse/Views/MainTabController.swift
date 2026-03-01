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

            SocialFeedView()
            .tabItem {
                Label("Social", systemImage: "person.2.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle")
            }
        }
        .tint(Color(red: 180/255, green: 120/255, blue: 255/255))
    }
}
