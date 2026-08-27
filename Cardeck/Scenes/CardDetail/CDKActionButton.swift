import UIKit

public enum CDKActionButton {

    public enum Style {

        case accent

        case surface

        case destructive
    }

    public static func make(
        title: String,
        style: Style,
        action: @escaping () -> Void
    ) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = CDKTheme.Radius.button
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: CDKTheme.Spacing.m,
            leading: CDKTheme.Spacing.l,
            bottom: CDKTheme.Spacing.m,
            trailing: CDKTheme.Spacing.l
        )
        switch style {
        case .accent:
            configuration.baseBackgroundColor = CDKTheme.Color.accent
            configuration.baseForegroundColor = CDKTheme.Color.textPrimary
        case .surface:
            configuration.baseBackgroundColor = CDKTheme.Color.surfaceElevated
            configuration.baseForegroundColor = CDKTheme.Color.textPrimary
        case .destructive:
            configuration.baseBackgroundColor = CDKTheme.Color.surfaceElevated
            configuration.baseForegroundColor = CDKTheme.Color.destructive
        }
        let button = UIButton(type: .system)
        button.configuration = configuration
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
