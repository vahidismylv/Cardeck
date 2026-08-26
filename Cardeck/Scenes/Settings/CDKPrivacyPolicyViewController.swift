//
//  CDKPrivacyPolicyViewController.swift
//  Cardeck
//

import UIKit
import WebKit

/// Экран политики конфиденциальности.
///
/// Приложение не ходит в сеть нигде, кроме этого экрана, поэтому офлайн здесь —
/// нормальное состояние, а не ошибка: вместо пустой страницы показывается
/// понятное объяснение и кнопка повтора.
public final class CDKPrivacyPolicyViewController: UIViewController {

    private let webView = WKWebView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    private let retryButton = CDKActionButton.make(title: "Try again", style: .surface) {}
    private let closeButton = UIButton(type: .system)

    private let url: URL?

    /// Создаёт экран политики.
    public init(url: URL? = URL(string: "https://www.apple.com/legal/privacy/en-ww/")) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CDKTheme.Color.background
        setUp()
        load()
    }

    private func load() {
        guard let url else {
            showError("The policy address is unavailable.")
            return
        }
        errorLabel.isHidden = true
        retryButton.isHidden = true
        webView.isHidden = true
        spinner.startAnimating()
        webView.load(URLRequest(url: url))
    }

    private func showError(_ message: String) {
        spinner.stopAnimating()
        webView.isHidden = true
        errorLabel.isHidden = false
        retryButton.isHidden = false
        errorLabel.text = message
    }

    private func setUp() {
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = CDKTheme.Color.background
        webView.scrollView.backgroundColor = CDKTheme.Color.background

        spinner.color = CDKTheme.Color.textSecondary

        errorLabel.font = CDKTheme.Font.body
        errorLabel.textColor = CDKTheme.Color.textSecondary
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.isHidden = true

        retryButton.isHidden = true
        retryButton.addAction(UIAction { [weak self] _ in self?.load() }, for: .touchUpInside)

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "xmark")
        configuration.baseForegroundColor = CDKTheme.Color.textSecondary
        closeButton.configuration = configuration
        closeButton.accessibilityLabel = "Close"
        closeButton.addAction(
            UIAction { [weak self] _ in self?.dismiss(animated: true) },
            for: .touchUpInside
        )

        view.cdkAddSubview(closeButton)
        view.cdkAddSubview(webView)
        view.cdkAddSubview(spinner)
        view.cdkAddSubview(errorLabel)
        view.cdkAddSubview(retryButton)

        let inset = CDKTheme.Card.detailHorizontalInset
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            closeButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -CDKTheme.Spacing.s
            ),

            webView.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),

            retryButton.topAnchor.constraint(
                equalTo: errorLabel.bottomAnchor, constant: CDKTheme.Spacing.l
            ),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

// MARK: - WKNavigationDelegate

extension CDKPrivacyPolicyViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        webView.isHidden = false
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        showError("Could not load the policy. Check your connection and try again.")
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        showError("Could not load the policy. Check your connection and try again.")
    }
}
