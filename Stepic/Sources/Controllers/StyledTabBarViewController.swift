import UIKit

final class StyledTabBarViewController: UITabBarController {
    private let items = StepikApplicationsInfo.Modules.tabs?.compactMap { TabController(rawValue: $0)?.itemInfo } ?? []

    private var notificationsBadgeNumber: Int {
        get {
            if let notificationsTab = self.tabBar.items?.first(where: { $0.tag == TabController.notifications.tag }) {
                return Int(notificationsTab.badgeValue ?? "0") ?? 0
            }
            return 0
        }
        set {
            if let notificationsTab = self.tabBar.items?.first(where: { $0.tag == TabController.notifications.tag }) {
                notificationsTab.badgeValue = newValue > 0 ? "\(newValue)" : nil
                self.fixBadgePosition()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = UIColor.stepikAccent
        self.tabBar.unselectedItemTintColor = UIColor(hex6: 0xbabac1)
        self.tabBar.isTranslucent = false

        let tabBarViewControllers = self.items.map { tabBarItem -> UIViewController in
            let viewController = tabBarItem.controller
            viewController.tabBarItem = tabBarItem.makeTabBarItem()
            return viewController
        }
        self.setViewControllers(tabBarViewControllers, animated: false)
        self.fixBadgePosition()

        self.delegate = self

        if !AuthInfo.shared.isAuthorized {
            self.selectedIndex = TabController.explore.position
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didBadgeUpdate(systemNotification:)),
            name: .badgeUpdated,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didScreenRotate),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !DefaultsContainer.launch.didLaunch {
            DefaultsContainer.launch.didLaunch = true

            let onboardingViewController = ControllerHelper.instantiateViewController(
                identifier: "Onboarding",
                storyboardName: "Onboarding"
            )
            onboardingViewController.modalPresentationStyle = .fullScreen

            self.present(onboardingViewController, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Private API

    @objc
    private func didBadgeUpdate(systemNotification: Foundation.Notification) {
        guard let userInfo = systemNotification.userInfo,
              let value = userInfo["value"] as? Int else {
            return
        }

        self.notificationsBadgeNumber = value
    }

    @objc
    private func didScreenRotate() {
        DispatchQueue.main.async {
            self.fixBadgePosition()
        }
    }

    private func fixBadgePosition() {
        for i in 1...items.count {
            if i >= tabBar.subviews.count { break }

            for badgeView in tabBar.subviews[i].subviews {
                if NSStringFromClass(badgeView.classForCoder) == "_UIBadgeView" {
                    badgeView.layer.transform = CATransform3DIdentity

                    if DeviceInfo.current.orientation.interface.isLandscape {
                        badgeView.layer.transform = CATransform3DMakeTranslation(-2.0, 5.0, 1.0)
                    } else {
                        if DeviceInfo.current.isPad {
                            badgeView.layer.transform = CATransform3DMakeTranslation(1.0, 3.0, 1.0)
                        } else {
                            badgeView.layer.transform = CATransform3DMakeTranslation(-6.0, -1.0, 1.0)
                        }
                    }
                }
            }
        }
    }
}

extension StyledTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController),
              let eventName = self.items[safe: selectedIndex]?.clickEventName else {
            return
        }

        AnalyticsReporter.reportEvent(eventName)
    }
}

private struct TabBarItemInfo {
    var title: String
    var controller: UIViewController
    var clickEventName: String
    var image: UIImage
    var tag: Int

    func makeTabBarItem() -> UITabBarItem {
        UITabBarItem(title: self.title, image: self.image, tag: self.tag)
    }
}

private enum TabController: String {
    case profile = "Profile"
    case home = "Home"
    case notifications = "Notifications"
    case explore = "Catalog"

    var tag: Int { self.hashValue }

    var position: Int {
        switch self {
        case .home:
            return 0
        case .explore:
            return 1
        case .profile:
            return 2
        case .notifications:
            return 3
        }
    }

    var itemInfo: TabBarItemInfo {
        switch self {
        case .profile:
            let viewController = ControllerHelper.instantiateViewController(
                identifier: "ProfileNavigation",
                storyboardName: "Main"
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Profile", comment: ""),
                controller: viewController,
                clickEventName: AnalyticsEvents.Tabs.profileClicked,
                image: UIImage(named: "tab-profile").require(),
                tag: self.tag
            )
        case .home:
            let viewController = HomeAssembly().makeModule()
            let navigationViewController = StyledNavigationController(
                rootViewController: viewController
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Home", comment: ""),
                controller: navigationViewController,
                clickEventName: AnalyticsEvents.Tabs.myCoursesClicked,
                image: UIImage(named: "tab-home").require(),
                tag: self.tag
            )
        case .notifications:
            let viewController = ControllerHelper.instantiateViewController(
                identifier: "NotificationsNavigation",
                storyboardName: "Main"
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Notifications", comment: ""),
                controller: viewController,
                clickEventName: AnalyticsEvents.Tabs.notificationsClicked,
                image: UIImage(named: "tab-notifications").require(),
                tag: self.tag
            )
        case .explore:
            let viewController = ExploreAssembly().makeModule()
            let navigationViewController = StyledNavigationController(
                rootViewController: viewController
            )
            return TabBarItemInfo(
                title: NSLocalizedString("Catalog", comment: ""),
                controller: navigationViewController,
                clickEventName: AnalyticsEvents.Tabs.catalogClicked,
                image: UIImage(named: "tab-explore").require(),
                tag: self.tag
            )
        }
    }
}