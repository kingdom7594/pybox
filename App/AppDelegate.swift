import UIKit
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupAppearance()
        setupNotifications()
        return true
    }

    private func setupAppearance() {
        // MARK: Navigation Bar — surface 底，fg 文字，1px 底边
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.Colors.surface)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
        // 底部分隔线
        navAppearance.shadowColor = UIColor(Theme.Colors.border)

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.Colors.accent)

        // MARK: Tab Bar — tabBarBg 底，1px 顶边，accent 激活色
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.Colors.tabBarBg)
        tabAppearance.shadowColor = UIColor(Theme.Colors.border)

        // 未激活文字/图标：muted2
        let normalColor: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Theme.Colors.textMuted)
        ]
        // 激活：accent
        let selectedColor: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Theme.Colors.accent)
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.Colors.textMuted)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalColor
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.accent)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedColor

        tabAppearance.inlineLayoutAppearance.normal.iconColor = UIColor(Theme.Colors.textMuted)
        tabAppearance.inlineLayoutAppearance.normal.titleTextAttributes = normalColor
        tabAppearance.inlineLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.accent)
        tabAppearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedColor

        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Theme.Colors.textMuted)
        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalColor
        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.accent)
        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedColor

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor(Theme.Colors.accent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Theme.Colors.textMuted)
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
}
