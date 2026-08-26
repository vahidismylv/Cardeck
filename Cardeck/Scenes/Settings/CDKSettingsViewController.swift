//
//  CDKSettingsViewController.swift
//  Cardeck
//

import UIKit

/// События экрана настроек.
public protocol CDKSettingsViewControllerDelegate: AnyObject {
    /// Данные сброшены — стопке нужно перечитать себя.
    func settingsDidResetData(_ controller: CDKSettingsViewController)
    /// Настройка материала изменилась — карты надо пересобрать.
    func settingsDidChangeAppearance(_ controller: CDKSettingsViewController)
    /// Любая настройка изменилась — стопке нужно перечитать себя.
    ///
    /// Экран открывается листом поверх стопки, и `viewWillAppear` у неё
    /// при закрытии не вызывается: без этого уведомления смена порядка
    /// сортировки не доезжала бы до экрана.
    func settingsDidChange(_ controller: CDKSettingsViewController)
}

/// Экран настроек: секции-карточки вместо системного списка.
public final class CDKSettingsViewController: UIViewController {

    /// Приёмник событий экрана.
    public weak var delegate: CDKSettingsViewControllerDelegate?

    private let viewModel: CDKSettingsViewModel
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let versionLabel = UILabel()

    private var sortRows: [CDKSortOrder: CDKSettingsChoiceRow] = [:]
    private var toggleRows: [CDKSettingsToggleRow] = []

    /// Создаёт экран настроек.
    public init(viewModel: CDKSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CDKTheme.Color.background
        setUpChrome()
        contentStack.addArrangedSubview(makeSortSection())
        contentStack.addArrangedSubview(makeBehaviourSection())
        contentStack.addArrangedSubview(makeDataSection())
        contentStack.addArrangedSubview(versionLabel)
        viewModel.onChange = { [weak self] in
            guard let self else { return }
            self.refresh()
            self.delegate?.settingsDidChange(self)
        }
        refresh()
    }

    // MARK: - Секции

    private func makeSortSection() -> UIView {
        let section = CDKSettingsSectionView(title: "Stack order")
        for order in CDKSortOrder.allCases {
            let row = CDKSettingsChoiceRow(title: order.title)
            row.onSelect = { [weak self] in self?.viewModel.sortOrder = order }
            sortRows[order] = row
            section.addRow(row)
        }
        return section
    }

    private func makeBehaviourSection() -> UIView {
        let section = CDKSettingsSectionView(title: "Behaviour")

        let haptics = CDKSettingsToggleRow(title: "Haptics")
        haptics.onToggle = { [weak self] in self?.viewModel.hapticsEnabled = $0 }

        let brightness = CDKSettingsToggleRow(
            title: "Auto brightness",
            subtitle: "Raise screen brightness while a code is on screen"
        )
        brightness.onToggle = { [weak self] in self?.viewModel.autoBrightnessEnabled = $0 }

        let holographic = CDKSettingsToggleRow(
            title: "Holographic cards",
            subtitle: "Turn off on older devices to save power"
        )
        holographic.onToggle = { [weak self] isOn in
            guard let self else { return }
            self.viewModel.holographicEnabled = isOn
            self.delegate?.settingsDidChangeAppearance(self)
        }

        toggleRows = [haptics, brightness, holographic]
        for row in toggleRows {
            section.addRow(row)
        }
        return section
    }

    private func makeDataSection() -> UIView {
        let section = CDKSettingsSectionView(title: "Data")

        let privacy = CDKSettingsActionRow(title: "Privacy Policy")
        privacy.onTap = { [weak self] in
            self?.present(CDKPrivacyPolicyViewController(), animated: true)
        }

        let reset = CDKSettingsActionRow(
            title: "Reset all data", destructive: true, showsChevron: false
        )
        reset.onTap = { [weak self] in self?.confirmReset() }

        section.addRow(privacy)
        section.addRow(reset)
        return section
    }

    // MARK: - Сброс

    /// Сброс подтверждается в два шага: первое подтверждение объясняет
    /// последствия, второе требует осознанного повторного нажатия.
    private func confirmReset() {
        let first = UIAlertController(
            title: "Reset all data?",
            message: "Every card will be removed from this device.",
            preferredStyle: .alert
        )
        first.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        first.addAction(UIAlertAction(title: "Continue", style: .destructive) { [weak self] _ in
            self?.confirmResetFinally()
        })
        present(first, animated: true)
    }

    private func confirmResetFinally() {
        let second = UIAlertController(
            title: "This cannot be undone",
            message: "Delete every card?",
            preferredStyle: .alert
        )
        second.addAction(UIAlertAction(title: "Keep my cards", style: .cancel))
        second.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.viewModel.resetData()
            self.delegate?.settingsDidResetData(self)
        })
        present(second, animated: true)
    }

    // MARK: - Вёрстка

    private func refresh() {
        for (order, row) in sortRows {
            row.setSelected(order == viewModel.sortOrder)
        }
        toggleRows[0].setOn(viewModel.hapticsEnabled)
        toggleRows[1].setOn(viewModel.autoBrightnessEnabled)
        toggleRows[2].setOn(viewModel.holographicEnabled)
        versionLabel.text = viewModel.versionText
    }

    private func setUpChrome() {
        headerLabel.text = "Settings"
        headerLabel.font = CDKTheme.Font.title
        headerLabel.textColor = CDKTheme.Color.textPrimary
        headerLabel.adjustsFontForContentSizeCategory = true
        headerLabel.accessibilityTraits = .header

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "xmark")
        configuration.baseForegroundColor = CDKTheme.Color.textSecondary
        closeButton.configuration = configuration
        closeButton.accessibilityLabel = "Close"
        closeButton.addAction(
            UIAction { [weak self] _ in self?.dismiss(animated: true) },
            for: .touchUpInside
        )

        versionLabel.font = CDKTheme.Font.caption
        versionLabel.textColor = CDKTheme.Color.textSecondary
        versionLabel.textAlignment = .center
        versionLabel.adjustsFontForContentSizeCategory = true

        contentStack.axis = .vertical
        contentStack.spacing = CDKTheme.Spacing.l
        scrollView.showsVerticalScrollIndicator = false

        view.cdkAddSubview(headerLabel)
        view.cdkAddSubview(closeButton)
        view.cdkAddSubview(scrollView)
        scrollView.cdkAddSubview(contentStack)

        let inset = CDKTheme.Card.detailHorizontalInset
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: CDKTheme.Spacing.s
            ),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            closeButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -CDKTheme.Spacing.s
            ),

            scrollView.topAnchor.constraint(
                equalTo: headerLabel.bottomAnchor, constant: CDKTheme.Spacing.l
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -CDKTheme.Spacing.xl
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: inset
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -inset
            )
        ])
    }
}
