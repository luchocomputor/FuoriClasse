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
                AvatarView()
            }
            .tabItem {
                Label("Avatar", systemImage: "person.circle.fill")
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
        }
        .tint(.pink)
    }
}
