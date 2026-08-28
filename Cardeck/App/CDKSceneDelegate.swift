import UIKit

public final class CDKSceneDelegate: UIResponder, UIWindowSceneDelegate {

    public var window: UIWindow?

    private var coordinator: CDKAppCoordinator?

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = CDKTheme.Color.background
        window.overrideUserInterfaceStyle = .dark

        let coordinator = CDKAppCoordinator(window: window)
        coordinator.start()

        self.window = window
        self.coordinator = coordinator
        window.makeKeyAndVisible()
        coordinator.showLaunchOverlay()

        let activity = connectionOptions.userActivities.first
            ?? session.stateRestorationActivity
        window.layoutIfNeeded()
        coordinator.restore(from: activity)
    }

    public func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        coordinator?.restorationActivity
    }
}
