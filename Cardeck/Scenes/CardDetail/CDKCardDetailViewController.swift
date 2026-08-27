import UIKit

public protocol CDKCardDetailViewControllerDelegate: AnyObject {

    func cardDetailDidRequestEdit(_ controller: CDKCardDetailViewController)

    func cardDetailDidRequestDelete(_ controller: CDKCardDetailViewController)

    func cardDetailDidDismiss(_ controller: CDKCardDetailViewController)
}

public final class CDKCardDetailViewController: UIViewController {

    public weak var delegate: CDKCardDetailViewControllerDelegate?

    public var card: CDKCardSnapshot { viewModel.card }

    private let viewModel: CDKCardDetailViewModel
    private let barcodeService: CDKBarcodeServicing
    private let brightnessService: CDKBrightnessServicing

    private var codeTask: Task<Void, Never>?

    private var contentView: CDKCardDetailView {

        view as! CDKCardDetailView
    }

    var cardView: CDKDetailCardView { contentView.cardView }

    var animatableContent: [UIView] { contentView.animatableContent }

    public init(
        viewModel: CDKCardDetailViewModel,
        barcodeService: CDKBarcodeServicing,
        brightnessService: CDKBrightnessServicing
    ) {
        self.viewModel = viewModel
        self.barcodeService = barcodeService
        self.brightnessService = brightnessService
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    deinit {
        codeTask?.cancel()

        brightnessService.restoreImmediately()
    }

    public override func loadView() {
        view = CDKCardDetailView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        bindActions()
        cardView.configure(with: viewModel.card)
        bindViewModel()
        loadCode()
        configureAccessibility()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.markUsed()
        if let screen = view.window?.windowScene?.screen {
            brightnessService.boost(on: screen)
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: contentView.codePanel)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        brightnessService.restore()
        UIApplication.shared.isIdleTimerDisabled = false
        cardView.materialView?.stopMotionUpdates()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            delegate?.cardDetailDidDismiss(self)
        }
    }

    func restoreAfterCancelledDismissal() {
        contentView.restoreAfterCancelledDismissal()
    }

    private func bindActions() {
        contentView.onShowCode = { [weak self] in self?.showFullScreenCode() }
        contentView.onEdit = { [weak self] in
            guard let self else { return }
            self.delegate?.cardDetailDidRequestEdit(self)
        }
        contentView.onDelete = { [weak self] in
            guard let self else { return }
            self.delegate?.cardDetailDidRequestDelete(self)
        }
        contentView.onClose = { [weak self] in self?.dismiss(animated: true) }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .loading:
                self.contentView.codePanel.showLoading()
            case .ready:
                break
            case .failed(let error):
                self.contentView.codePanel.show(
                    error: error, number: self.viewModel.groupedCode
                )
            }
        }
    }

    private func loadCode() {
        contentView.codePanel.showLoading()
        let card = viewModel.card
        let size = CGSize(width: 600, height: 600 / max(card.codeType.preferredAspectRatio, 0.1))
        codeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await self.barcodeService.image(
                    payload: card.code, type: card.codeType, size: size
                )
                guard !Task.isCancelled else { return }
                self.contentView.codePanel.show(
                    image: image,
                    aspectRatio: self.viewModel.codeAspectRatio,
                    number: self.viewModel.groupedCode
                )
                self.viewModel.setState(.ready)
            } catch {
                guard !Task.isCancelled else { return }
                self.viewModel.setState(.failed(error as? CDKBarcodeError ?? .generationFailed))
            }
        }
    }

    private func configureAccessibility() {
        view.accessibilityViewIsModal = true
        view.accessibilityElements = animatableContent
    }

    private func showFullScreenCode() {
        let overlay = CDKFullScreenCodeView(
            number: viewModel.groupedCode,
            aspectRatio: viewModel.codeAspectRatio
        )
        overlay.present(over: view, image: contentView.codePanel.currentCodeImage)
    }
}
