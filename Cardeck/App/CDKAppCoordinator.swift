import UIKit

public final class CDKAppCoordinator {

    private let window: UIWindow
    private let preferences: CDKPreferencesProtocol
    private let haptics: CDKHapticsServiceProtocol
    private let store: CDKCardStore
    private let barcodeService: CDKBarcodeServicing
    private let brightnessService: CDKBrightnessServicing

    private let persistentStore: CDKSwiftDataCardStore?

    private var walletViewController: CDKWalletViewController?

    private var cardTransition: CDKCardTransitionController?

    private var openCardID: UUID?

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

    private func seedDemoDataIfNeeded() {
        guard let persistentStore, !preferences.didSeedDemoData else { return }
        preferences.didSeedDemoData = true
        guard (try? persistentStore.count()) == 0 else { return }
        try? persistentStore.insert(CDKMockData.cards)
    }

    private func presentForm(mode: CDKAddEditViewModel.Mode, from presenter: UIViewController) {
        let viewModel = CDKAddEditViewModel(mode: mode, store: store)
        let form = CDKAddEditViewController(viewModel: viewModel, haptics: haptics)
        form.delegate = self
        presenter.present(form, animated: true)
    }

    public var restorationActivity: NSUserActivity? {
        openCardID.map(CDKUserActivity.openCard)
    }

    public func restore(from activity: NSUserActivity?) {
        guard let id = CDKUserActivity.cardID(from: activity),
              let wallet = walletViewController,
              let card = wallet.model.cards.first(where: { $0.id == id }),
              let cell = wallet.cell(for: card) else { return }
        wallet.open(card, from: cell)
    }

    public func start() {
        seedDemoDataIfNeeded()
        let viewModel = CDKWalletViewModel(store: store, preferences: preferences)
        let wallet = CDKWalletViewController(viewModel: viewModel, haptics: haptics)
        wallet.delegate = self
        walletViewController = wallet
        window.rootViewController = wallet
    }
}

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
        openCardID = card.id

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
        openCardID = nil
        walletViewController?.resetNeighbours()
        walletViewController?.model.reload()
        cardTransition = nil
    }
}

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

extension CDKAppCoordinator: CDKSettingsViewControllerDelegate {

    public func settingsDidResetData(_ controller: CDKSettingsViewController) {

        walletViewController?.model.reload()
    }

    public func settingsDidChange(_ controller: CDKSettingsViewController) {
        walletViewController?.model.reload()
    }

    public func settingsDidChangeAppearance(_ controller: CDKSettingsViewController) {

        walletViewController?.rebuildCards()
    }
}
