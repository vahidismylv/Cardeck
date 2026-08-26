//
//  CDKAppDelegate.swift
//  Cardeck
//

import UIKit

/// Точка входа приложения.
///
/// Никакой работы при запуске здесь не делается: стопка карт должна появиться
/// на экране сразу, без искусственного лоадера.
@main
public final class CDKAppDelegate: UIResponder, UIApplicationDelegate {

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    public func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}
