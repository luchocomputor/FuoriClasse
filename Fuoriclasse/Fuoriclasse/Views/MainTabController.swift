import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {
    @State private var navigationPath = NavigationPath() // ✅ Ajout du @State

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
    }

    private func configureTabs() {
        viewControllers = [
            configureNav(
                UIHostingController(rootView: DressingItemListView()),
                title: "Dressing", icon: "hanger"
            ),
            configureNav(
                UIHostingController(rootView: AvatarView(navigationPath: $navigationPath)),
                title: "Avatar", icon: "person.circle.fill"
            )
,
            configureNav(StyleAdvisorViewController(), title: "Conseils", icon: "message.circle"),
            configureNav(ProfileViewController(), title: "Profil", icon: "person.crop.circle")
        ]

        tabBar.tintColor = .systemPink
        tabBar.backgroundColor = .white
    }

    private func configureNav(_ controller: UIViewController, title: String, icon: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: controller)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = UIImage(systemName: icon)
        return nav
    }
}
