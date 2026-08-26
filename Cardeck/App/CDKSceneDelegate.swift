//
//  CDKSceneDelegate.swift
//  Cardeck
//

import UIKit

/// Делегат сцены: поднимает окно и передаёт управление координатору.
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

        // Карта, открытая до убийства приложения, возвращается на экран.
        // Стопка к этому моменту уже наполнена, поэтому ячейка-источник найдётся
        // и переход отработает штатно.
        let activity = connectionOptions.userActivities.first
            ?? session.stateRestorationActivity
        window.layoutIfNeeded()
        coordinator.restore(from: activity)
    }

    public func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        coordinator?.restorationActivity
    }
}
