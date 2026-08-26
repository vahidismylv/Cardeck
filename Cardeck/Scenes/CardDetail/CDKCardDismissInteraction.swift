//
//  CDKCardDismissInteraction.swift
//  Cardeck
//

import UIKit

/// Интерактивное закрытие детального экрана протягиванием вниз.
///
/// Жест живёт на всей вью и работает одновременно со скроллом панели кода.
/// Буквальное `require(toFail:)` здесь не годится: скролл — непрерывный
/// распознаватель, он не «проваливается», и закрытие не начиналось бы никогда.
/// Поэтому приоритет решается по состоянию панели: пока она прокручена наверх,
/// протягивание вниз забирает жест себе и удерживает панель на месте.
///
/// Прерываемость даёт `interruptibleAnimator` аниматора: новое касание во время
/// инерционного возврата ставит его на паузу и продолжает с текущего
/// `fractionComplete`, поэтому карта ни разу не прыгает в стартовую позицию.
///
/// Перехватывать можно только то закрытие, которое начал этот же жест. Закрытие
/// по крестику идёт мимо `UIPercentDrivenInteractiveTransition`, и попытка
/// вмешаться в него оставляла переход навсегда незавершённым: карта зависала
/// поверх стопки, ячейка-источник — с нулевой прозрачностью.
public final class CDKCardDismissInteraction: UIPercentDrivenInteractiveTransition,
                                              UIGestureRecognizerDelegate {

    /// Порог завершения по пройденному пути.
    private static let completionThreshold: CGFloat = 0.4
    /// Порог завершения по скорости, pt/с.
    private static let completionVelocity: CGFloat = 800
    /// Доля высоты экрана, соответствующая полному прогрессу.
    private static let travelFraction: CGFloat = 0.6

    /// Идёт ли сейчас интерактивное закрытие.
    public private(set) var isActive = false

    /// Даёт доступ к аниматору текущего перехода для паузы при перехвате.
    var animatorProvider: (() -> UIViewPropertyAnimator?)?

    private let haptics: CDKHapticsServiceProtocol
    private weak var detail: CDKCardDetailViewController?
    private weak var scrollView: UIScrollView?
    private var isDriving = false
    /// Ведёт ли этот контроллер текущее закрытие. Только его можно перехватывать.
    private var ownsRunningDismissal = false

    /// Создаёт контроллер жеста.
    public init(haptics: CDKHapticsServiceProtocol) {
        self.haptics = haptics
        super.init()
        // Жест начинает переход сам, поэтому старт именно интерактивный:
        // карта обязана идти за пальцем, а не проигрывать анимацию целиком.
        wantsInteractiveStart = true
    }

    /// Вешает жест на всю вью детального экрана.
    public func attach(to detail: CDKCardDetailViewController) {
        self.detail = detail
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self
        detail.view.addGestureRecognizer(pan)
        scrollView = detail.view.cdkFirstScrollView
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let detail else { return }
        let translation = gesture.translation(in: detail.view)
        let velocity = gesture.velocity(in: detail.view)
        let distance = max(detail.view.bounds.height * Self.travelFraction, 1)

        switch gesture.state {
        case .began:
            interceptRunningAnimator()
        case .changed:
            guard isDriving else {
                startDrivingIfPossible(gesture, translation: translation, in: detail)
                return
            }
            let progress = (max(0, translation.y) / distance).cdkClamped(0, 1)
            update(progress)
            haptics.updateDrag(progress: Double(progress))
        case .ended, .cancelled, .failed:
            guard isDriving else { return }
            let progress = (max(0, translation.y) / distance).cdkClamped(0, 1)
            complete(progress: progress, velocity: velocity, distance: distance)
        default:
            break
        }
    }

    /// Сообщает, что закрытие завершилось — успешно или отменой.
    func dismissalDidEnd() {
        ownsRunningDismissal = false
        isDriving = false
        isActive = false
        scrollView?.isScrollEnabled = true
    }

    /// Перехватывает уже идущую анимацию закрытия: пауза, дальше ведём пальцем.
    ///
    /// Паузу ставит сам интерактивный контроллер, а не `UIViewPropertyAnimator`:
    /// иначе `finish()`/`cancel()` уже не относились бы к этому переходу
    /// и `completeTransition` никогда бы не вызвался.
    private func interceptRunningAnimator() {
        guard ownsRunningDismissal,
              let animator = animatorProvider?(), animator.isRunning else { return }
        pause()
        isDriving = true
        isActive = true
    }

    /// Забирает жест себе, если панель кода прокручена наверх и палец идёт вниз.
    private func startDrivingIfPossible(
        _ gesture: UIPanGestureRecognizer,
        translation: CGPoint,
        in detail: CDKCardDetailViewController
    ) {
        guard translation.y > 0, translation.y > abs(translation.x), isScrollAtTop else { return }
        // Второе закрытие поверх уже идущего перехода — прямой путь в застревание.
        guard !ownsRunningDismissal,
              detail.transitionCoordinator == nil,
              !detail.isBeingPresented,
              !detail.isBeingDismissed,
              detail.presentingViewController != nil else { return }
        ownsRunningDismissal = true
        isDriving = true
        isActive = true
        haptics.beginDrag()
        // Скролл панели отменяется и замирает: иначе он продолжал бы уезжать
        // под тем же пальцем, который уже тащит карту вниз.
        scrollView?.panGestureRecognizer.isEnabled = false
        scrollView?.panGestureRecognizer.isEnabled = true
        scrollView?.isScrollEnabled = false
        // Отсчёт прогресса начинается с текущей точки, а не с места касания:
        // иначе карта скакнула бы на уже накопленное смещение.
        gesture.setTranslation(.zero, in: detail.view)
        detail.dismiss(animated: true)
    }

    private func complete(progress: CGFloat, velocity: CGPoint, distance: CGFloat) {
        haptics.endDrag()
        // `ownsRunningDismissal` держится до фактического конца перехода: до этого
        // момента жест ещё может его перехватить.
        isDriving = false
        isActive = false
        scrollView?.isScrollEnabled = true
        let shouldFinish = progress > Self.completionThreshold
            || velocity.y > Self.completionVelocity
        // Скорость жеста передаётся пружине: карта продолжает движение так же,
        // как её вёл палец, а не стартует заново с нуля.
        let remaining = max(distance * (shouldFinish ? (1 - progress) : progress), 1)
        timingCurve = UISpringTimingParameters(
            mass: CDKTheme.Motion.transitionMass,
            stiffness: CDKTheme.Motion.transitionStiffness,
            damping: CDKTheme.Motion.transitionDamping,
            initialVelocity: CGVector(dx: 0, dy: abs(velocity.y) / remaining)
        )
        if shouldFinish {
            finish()
        } else {
            cancel()
        }
    }

    private var isScrollAtTop: Bool {
        guard let scrollView else { return true }
        return scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(
        _ gesture: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        // Работаем вместе со скроллом: кто ведёт — решает `startDrivingIfPossible`.
        other === scrollView?.panGestureRecognizer
    }
}

extension UIView {

    /// Первый `UIScrollView` в иерархии — панель кода на детальном экране.
    var cdkFirstScrollView: UIScrollView? {
        if let scrollView = self as? UIScrollView { return scrollView }
        for subview in subviews {
            if let found = subview.cdkFirstScrollView { return found }
        }
        return nil
    }
}
