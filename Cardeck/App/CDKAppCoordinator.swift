//
//  CDKAppCoordinator.swift
//  Cardeck
//

import UIKit

/// Корневой координатор приложения.
///
/// Собирает зависимости и владеет навигацией. Экраны не создают друг друга
/// и не знают, что открывается следом.
public final class CDKAppCoordinator {

    private let window: UIWindow
    private let preferences: CDKPreferencesProtocol
    private let haptics: CDKHapticsServiceProtocol
    private let store: CDKCardStore
    private let barcodeService: CDKBarcodeServicing
    private let brightnessService: CDKBrightnessServicing

    /// Хранилище на SwiftData, если координатор создал его сам.
    private let persistentStore: CDKSwiftDataCardStore?

    private var walletViewController: CDKWalletViewController?
    /// Контроллер перехода живёт столько же, сколько открытый детальный экран.
    private var cardTransition: CDKCardTransitionController?

    /// Создаёт координатор для окна сцены.
    public init(
        window: UIWindow,
        preferences: CDKPreferencesProtocol = CDKPreferences.shared,
        haptics: CDKHapticsServiceProtocol = CDKHapticsService.shared,
        store: CDKCardStore? = nil,
        barcodeService: CDKBarcodeServicing = CDKBarcodeService.shared,
        brightnessService: CDKBrightnessServicing = CDKBrightnessService.shared
    ) {
        self.window = window
        self.preferences = preferences
        self.haptics = haptics
        self.persistentStore = store == nil
            ? CDKSwiftDataCardStore(result: CDKModelContainerFactory.make())
            : nil
        self.store = store ?? persistentStore!
        self.barcodeService = barcodeService
        self.brightnessService = brightnessService
    }

    /// Засевает демонстрационный набор при первом запуске.
    ///
    /// Совсем пустое приложение на первом запуске выглядит сломанным, а пустое
    /// состояние всё равно достижимо через сброс данных в настройках.
    private func seedDemoDataIfNeeded() {
        guard let persistentStore, !preferences.didSeedDemoData else { return }
        preferences.didSeedDemoData = true
        guard (try? persistentStore.count()) == 0 else { return }
        try? persistentStore.insert(CDKMockData.cards)
    }

    /// Открывает форму добавления или редактирования карты.
    private func presentForm(mode: CDKAddEditViewModel.Mode, from presenter: UIViewController) {
        let viewModel = CDKAddEditViewModel(mode: mode, store: store)
        let form = CDKAddEditViewController(viewModel: viewModel, haptics: haptics)
        form.delegate = self
        presenter.present(form, animated: true)
    }

    /// Показывает стартовый экран.
    public func start() {
        seedDemoDataIfNeeded()
        let viewModel = CDKWalletViewModel(store: store, preferences: preferences)
        let wallet = CDKWalletViewController(viewModel: viewModel, haptics: haptics)
        wallet.delegate = self
        walletViewController = wallet
        window.rootViewController = wallet
    }
}

// MARK: - CDKWalletViewControllerDelegate

extension CDKAppCoordinator: CDKWalletViewControllerDelegate {

    public func walletViewController(
        _ controller: CDKWalletViewController,
        didSelect card: CDKCardSnapshot,
        from cell: CDKCardCell
    ) {
        let viewModel = CDKCardDetailViewModel(card: card, store: store)
        let detail = CDKCardDetailViewController(
            viewModel: viewModel,
            barcodeService: barcodeService,
            brightnessService: brightnessService
        )
        detail.delegate = self

        let transition = CDKCardTransitionController(
            card: card, wallet: controller, haptics: haptics
        )
        detail.transitioningDelegate = transition
        transition.attach(to: detail)
        cardTransition = transition

        controller.present(detail, animated: true)
    }

    public func walletViewControllerDidRequestAdd(_ controller: CDKWalletViewController) {
        presentForm(mode: .create, from: controller)
    }

    public func walletViewControllerDidRequestSettings(_ controller: CDKWalletViewController) {
        let viewModel = CDKSettingsViewModel(preferences: preferences, store: store)
        let settings = CDKSettingsViewController(viewModel: viewModel)
        settings.delegate = self
        controller.present(settings, animated: true)
    }
}

// MARK: - CDKCardDetailViewControllerDelegate

extension CDKAppCoordinator: CDKCardDetailViewControllerDelegate {

    public func cardDetailDidRequestEdit(_ controller: CDKCardDetailViewController) {
        let card = controller.card
        controller.dismiss(animated: true) { [weak self] in
            guard let self, let wallet = self.walletViewController else { return }
            self.presentForm(mode: .edit(card), from: wallet)
        }
    }

    public func cardDetailDidRequestDelete(_ controller: CDKCardDetailViewController) {
        let card = controller.card
        controller.dismiss(animated: true) { [weak self] in
            self?.walletViewController?.model.delete(id: card.id)
        }
    }

    public func cardDetailDidDismiss(_ controller: CDKCardDetailViewController) {
        walletViewController?.resetNeighbours()
        walletViewController?.model.reload()
        cardTransition = nil
    }
}

// MARK: - CDKAddEditViewControllerDelegate

extension CDKAppCoordinator: CDKAddEditViewControllerDelegate {

    public func addEdit(_ controller: CDKAddEditViewController, didSave card: CDKCardSnapshot) {
        controller.dismiss(animated: true) { [weak self] in
            self?.walletViewController?.model.reload()
        }
    }

    public func addEditDidCancel(_ controller: CDKAddEditViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - CDKSettingsViewControllerDelegate

extension CDKAppCoordinator: CDKSettingsViewControllerDelegate {

    public func settingsDidResetData(_ controller: CDKSettingsViewController) {
        // Пустое состояние появляется сразу, без перезапуска приложения.
        walletViewController?.model.reload()
    }

    public func settingsDidChange(_ controller: CDKSettingsViewController) {
        walletViewController?.model.reload()
    }

    public func settingsDidChangeAppearance(_ controller: CDKSettingsViewController) {
        // Материал выбирается при создании ячейки, поэтому карты надо пересобрать.
        walletViewController?.rebuildCards()
    }
}
