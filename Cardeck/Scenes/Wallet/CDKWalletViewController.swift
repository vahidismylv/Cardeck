//
//  CDKWalletViewController.swift
//  Cardeck
//

import UIKit

/// События стопки, которые обрабатывает координатор.
public protocol CDKWalletViewControllerDelegate: AnyObject {
    /// Пользователь открыл карту.
    func walletViewController(
        _ controller: CDKWalletViewController,
        didSelect card: CDKCardSnapshot,
        from cell: CDKCardCell
    )
    /// Пользователь запросил добавление карты.
    func walletViewControllerDidRequestAdd(_ controller: CDKWalletViewController)
    /// Пользователь запросил настройки.
    func walletViewControllerDidRequestSettings(_ controller: CDKWalletViewController)
}

/// Главный экран: стопка карт.
public final class CDKWalletViewController: UIViewController {

    /// Приёмник событий экрана.
    public weak var delegate: CDKWalletViewControllerDelegate?

    private let viewModel: CDKWalletViewModel
    private let haptics: CDKHapticsServiceProtocol

    let stackLayout = CDKCardStackLayout()
    private(set) lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: stackLayout
    )
    private let headerView = CDKWalletHeaderView()
    /// Разводит стопку на время перехода карты.
    private(set) lazy var stackReveal = CDKStackRevealAnimator(
        collectionView: collectionView, layout: stackLayout
    )
    private let emptyStateView = CDKEmptyStateView()

    private var dataSource: UICollectionViewDiffableDataSource<Int, CDKCardSnapshot>?
    private var undoToast: CDKUndoToastView?

    /// Создаёт экран стопки.
    public init(viewModel: CDKWalletViewModel, haptics: CDKHapticsServiceProtocol) {
        self.viewModel = viewModel
        self.haptics = haptics
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CDKTheme.Color.background
        setUpCollectionView()
        setUpHeader()
        setUpEmptyState()
        bind()
        viewModel.reload()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Стопка снова главная на экране: страхуемся от следов прерванного перехода.
        resetNeighbours()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stackLayout.headerHeight = headerView.bounds.height
    }

    // MARK: - Настройка

    private func setUpCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        view.cdkAddSubview(collectionView)
        collectionView.cdkPin(to: view)

        let registration = UICollectionView.CellRegistration<CDKCardCell, CDKCardSnapshot> {
            [weak self] cell, _, card in
            cell.configure(with: card)
            cell.delegate = self
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            collectionView, indexPath, card in
            collectionView.dequeueConfiguredReusableCell(
                using: registration, for: indexPath, item: card
            )
        }
    }

    private func setUpHeader() {
        headerView.onAddTapped = { [weak self] in
            guard let self else { return }
            self.delegate?.walletViewControllerDidRequestAdd(self)
        }
        headerView.onSettingsTapped = { [weak self] in
            guard let self else { return }
            self.delegate?.walletViewControllerDidRequestSettings(self)
        }
        view.cdkAddSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setUpEmptyState() {
        emptyStateView.isHidden = true
        emptyStateView.onAddTapped = { [weak self] in
            guard let self else { return }
            self.delegate?.walletViewControllerDidRequestAdd(self)
        }
        view.cdkAddSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func bind() {
        viewModel.onChange = { [weak self] in self?.applySnapshot() }
        viewModel.onUndoAvailable = { [weak self] _ in self?.presentUndoToast() }
    }

    /// Показывает тост отмены; по истечении окна удаление становится необратимым.
    private func presentUndoToast() {
        undoToast?.dismiss(undo: false)
        let toast = CDKUndoToastView()
        toast.onUndo = { [weak self] in
            self?.undoToast = nil
            self?.viewModel.undoDelete()
        }
        toast.onExpire = { [weak self] in
            self?.undoToast = nil
            self?.viewModel.commitPendingDeletion()
        }
        undoToast = toast
        toast.present(in: view, above: view.safeAreaLayoutGuide)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CDKCardSnapshot>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.cards)
        dataSource?.apply(snapshot, animatingDifferences: !viewModel.cards.isEmpty)
        emptyStateView.isHidden = !viewModel.isEmpty
        collectionView.isHidden = viewModel.isEmpty
        headerView.setSubtitle(
            viewModel.isEmpty ? nil : "\(viewModel.cards.count) \(Self.cardsWord(viewModel.cards.count))"
        )
    }

    /// Подпись счётчика карт.
    private static func cardsWord(_ count: Int) -> String {
        count == 1 ? "card" : "cards"
    }

    /// Ячейка карты по идентификатору — нужна переходу и действиям доступности.
    func cell(for card: CDKCardSnapshot) -> CDKCardCell? {
        guard let indexPath = dataSource?.indexPath(for: card) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? CDKCardCell
    }

    /// Карта по ячейке.
    func card(for cell: CDKCardCell) -> CDKCardSnapshot? {
        guard let indexPath = collectionView.indexPath(for: cell) else { return nil }
        return dataSource?.itemIdentifier(for: indexPath)
    }

    /// Открывает карту, сообщая координатору исходную ячейку для перехода.
    func open(_ card: CDKCardSnapshot, from cell: CDKCardCell) {
        viewModel.markUsed(id: card.id)
        haptics.playSnap()
        delegate?.walletViewController(self, didSelect: card, from: cell)
    }

    /// Доступ к вью-модели для расширений экрана.
    var model: CDKWalletViewModel { viewModel }
    /// Доступ к тактильной отдаче для расширений экрана.
    var hapticsService: CDKHapticsServiceProtocol { haptics }
}

// MARK: - UICollectionViewDelegate

extension CDKWalletViewController: UICollectionViewDelegate {

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let card = dataSource?.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? CDKCardCell else { return }
        open(card, from: cell)
    }
}

// MARK: - CDKCardCellDelegate

extension CDKWalletViewController: CDKCardCellDelegate {

    public func cardCellDidRequestShowCode(_ cell: CDKCardCell) {
        guard let card = card(for: cell) else { return }
        open(card, from: cell)
    }

    public func cardCellDidRequestEdit(_ cell: CDKCardCell) {
        guard let card = card(for: cell) else { return }
        open(card, from: cell)
    }

    public func cardCellDidRequestDelete(_ cell: CDKCardCell) {
        guard let card = card(for: cell) else { return }
        viewModel.delete(id: card.id)
    }
}
