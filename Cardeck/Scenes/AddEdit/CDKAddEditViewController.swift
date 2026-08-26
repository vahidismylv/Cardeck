//
//  CDKAddEditViewController.swift
//  Cardeck
//

import UIKit

/// События формы карты.
public protocol CDKAddEditViewControllerDelegate: AnyObject {
    /// Карта сохранена.
    func addEdit(_ controller: CDKAddEditViewController, didSave card: CDKCardSnapshot)
    /// Пользователь закрыл форму без сохранения.
    func addEditDidCancel(_ controller: CDKAddEditViewController)
}

/// Форма добавления и редактирования карты.
///
/// Один контроллер на оба режима: он отличает их только заголовком, подписью
/// кнопки и тем, что отдаёт хранилищу — `add` или `update`.
public final class CDKAddEditViewController: UIViewController {

    /// Приёмник событий формы.
    public weak var delegate: CDKAddEditViewControllerDelegate?

    private let viewModel: CDKAddEditViewModel
    private let haptics: CDKHapticsServiceProtocol
    private var material: CDKCardMaterialView?

    private var contentView: CDKAddEditView {
        // swiftlint:disable:next force_cast
        view as! CDKAddEditView
    }

    /// Создаёт форму.
    public init(viewModel: CDKAddEditViewModel, haptics: CDKHapticsServiceProtocol) {
        self.viewModel = viewModel
        self.haptics = haptics
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public override func loadView() {
        view = CDKAddEditView(haptics: haptics)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        attachPreviewMaterial()
        bind()
        contentView.fill(from: viewModel)
        contentView.setCategoryMenu(makeCategoryMenu())
        contentView.apply(viewModel)
        observeKeyboard()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        material?.startMotionUpdates()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        material?.stopMotionUpdates()
    }

    // MARK: - Приватное

    /// Превью — та же живая карта, что и в стопке, а не статичная картинка.
    private func attachPreviewMaterial() {
        let material = CDKCardMaterialView(gradient: viewModel.draft.gradient)
        contentView.previewCard.attach(material)
        self.material = material
    }

    private func bind() {
        contentView.onTitleChange = { [weak self] in self?.viewModel.title = $0 }
        contentView.onCodeChange = { [weak self] in self?.viewModel.code = $0 }
        contentView.onNoteChange = { [weak self] in self?.viewModel.note = $0 }
        contentView.onCodeTypeChange = { [weak self] in self?.viewModel.codeType = $0 }
        contentView.onCategoryChange = { [weak self] in self?.viewModel.category = $0 }
        contentView.onGradientChange = { [weak self] in self?.viewModel.gradientIndex = $0 }
        contentView.onSave = { [weak self] in self?.save() }
        contentView.onCancel = { [weak self] in
            guard let self else { return }
            self.delegate?.addEditDidCancel(self)
        }
        viewModel.onChange = { [weak self] in
            guard let self else { return }
            self.contentView.apply(self.viewModel)
        }
    }

    private func makeCategoryMenu() -> UIMenu {
        let actions = CDKCategory.allCases.map { category in
            UIAction(
                title: category.title,
                image: UIImage(systemName: category.symbolName),
                state: category == viewModel.category ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                self.viewModel.category = category
                self.contentView.setCategoryMenu(self.makeCategoryMenu())
                self.haptics.playSelection()
            }
        }
        return UIMenu(title: "Category", children: actions)
    }

    private func save() {
        guard viewModel.isValid else { return }
        do {
            let card = try viewModel.save()
            haptics.playSnap()
            delegate?.addEdit(self, didSave: card)
        } catch {
            presentSaveFailure()
        }
    }

    /// Сообщает о неудачной записи — чаще всего это переполненный диск.
    private func presentSaveFailure() {
        let alert = UIAlertController(
            title: "Could not save",
            message: "There may not be enough free space on your device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// Превью уезжает вверх и уменьшается, пока поднята клавиатура.
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.setPreviewCompact(true)
        }
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.setPreviewCompact(false)
        }
    }

    private func setPreviewCompact(_ compact: Bool) {
        let animator = CDKTheme.Motion.snappy()
        animator.addAnimations { self.contentView.setPreviewCompact(compact) }
        animator.startAnimation()
    }
}
