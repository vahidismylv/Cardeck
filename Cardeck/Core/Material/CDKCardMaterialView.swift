//
//  CDKCardMaterialView.swift
//  Cardeck
//

import UIKit

/// Материал карты: голографическая поверхность, реагирующая на наклон устройства.
///
/// Внутри — либо `CAMetalLayer` с шейдером, либо ``CDKMaterialFallbackView``.
/// Выбор делается один раз при создании по доступности Metal и настройке
/// «голографический эффект». Наружу вью выглядит одинаково в обоих случаях,
/// поэтому переход в детальный экран может переносить её целиком в `containerView`,
/// не подменяя снимком: снимок заморозил бы голограмму на время анимации.
public final class CDKCardMaterialView: UIView, CDKMotionObserver {

    private let metalSurface: CDKMetalCardSurface?
    private let fallbackSurface: CDKMaterialFallbackView?
    private let motionService: CDKMotionServiceProtocol

    private var isObservingMotion = false

    private var gradient: CDKGradientPreset
    private var cornerRadiusLink: CADisplayLink?
    private var cornerRadiusStart: CGFloat = 0
    private var cornerRadiusTarget: CGFloat = 0
    private var cornerRadiusBeganAt: CFTimeInterval = 0

    /// Работает ли материал на Metal.
    public var isHardwareAccelerated: Bool { metalSurface != nil }

    /// Радиус скругления материала.
    public var cornerRadius: CGFloat = CDKTheme.Radius.card {
        didSet {
            metalSurface?.cornerRadius = cornerRadius
            fallbackSurface?.cornerRadius = cornerRadius
        }
    }

    /// Создаёт материал для карты.
    ///
    /// - Parameters:
    ///   - gradient: градиентный пресет карты.
    ///   - preferences: настройки; выключенный голографический эффект уводит на fallback.
    ///   - motionService: источник наклона.
    public init(
        gradient: CDKGradientPreset,
        preferences: CDKPreferencesProtocol = CDKPreferences.shared,
        motionService: CDKMotionServiceProtocol = CDKMotionService.shared
    ) {
        self.motionService = motionService
        self.gradient = gradient
        let flat = UIAccessibility.isDarkerSystemColorsEnabled
        if preferences.holographicEnabled, let renderer = CDKMetalCardRenderer.shared {
            metalSurface = CDKMetalCardSurface(renderer: renderer, gradient: gradient, flat: flat)
            fallbackSurface = nil
        } else {
            metalSurface = nil
            fallbackSurface = CDKMaterialFallbackView(gradient: gradient, flat: flat)
        }
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        let surface: UIView = metalSurface ?? fallbackSurface!
        cdkAddSubview(surface)
        surface.cdkPin(to: self)
        // Increase Contrast можно включить, не выходя из приложения: без подписки
        // карты остались бы градиентными до пересоздания ячейки.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleContrastChange),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleContrastChange() {
        update(gradient: gradient)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    deinit {
        cornerRadiusLink?.invalidate()
        motionService.removeObserver(self)
    }

    /// Меняет градиент карты — вызывается при переиспользовании ячейки.
    public func update(gradient: CDKGradientPreset) {
        self.gradient = gradient
        let flat = UIAccessibility.isDarkerSystemColorsEnabled
        metalSurface?.update(gradient: gradient, flat: flat)
        fallbackSurface?.update(gradient: gradient, flat: flat)
    }

    /// Подписывается на наклон устройства.
    ///
    /// Вызывается из `viewWillAppear` экрана или при показе ячейки. При включённом
    /// Reduce Motion сервис не стартует, материал остаётся статичным.
    public func startMotionUpdates() {
        guard !isObservingMotion else { return }
        isObservingMotion = true
        motionService.addObserver(self)
    }

    /// Отписывается от наклона: датчик гасится, как только подписчиков не осталось.
    public func stopMotionUpdates() {
        guard isObservingMotion else { return }
        isObservingMotion = false
        motionService.removeObserver(self)
    }

    /// Принудительно перерисовывает материал — например, после смены размера.
    public func refresh() {
        metalSurface?.setNeedsRender(force: true)
        fallbackSurface?.setNeedsLayout()
    }

    // MARK: - Скругление во время перехода

    /// Анимирует радиус скругления пружиной перехода.
    ///
    /// Радиус нельзя просто отдать Core Animation: у Metal-материала его считает
    /// шейдер. Поэтому для fallback ставится `CASpringAnimation` на слои,
    /// а для Metal значение каждый кадр пересчитывается вручную той же пружиной.
    /// Компенсация на масштаб presentation-слоя обязательна: пока CA растягивает
    /// уже отрисованную текстуру, углы поехали бы вместе с ней.
    public func animateCornerRadius(from start: CGFloat, to target: CGFloat) {
        stopCornerRadiusAnimation()
        cornerRadius = target
        if let fallbackSurface {
            fallbackSurface.animateCornerRadius(from: start, to: target)
            return
        }
        guard metalSurface != nil else { return }
        cornerRadiusStart = start
        cornerRadiusTarget = target
        cornerRadiusBeganAt = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(stepCornerRadius))
        link.add(to: .main, forMode: .common)
        cornerRadiusLink = link
    }

    /// Останавливает покадровый пересчёт радиуса.
    public func stopCornerRadiusAnimation() {
        cornerRadiusLink?.invalidate()
        cornerRadiusLink = nil
        metalSurface?.cornerRadius = cornerRadius
    }

    @objc private func stepCornerRadius() {
        let elapsed = CACurrentMediaTime() - cornerRadiusBeganAt
        let radius = CDKSpring.cardTransition.value(
            from: cornerRadiusStart,
            to: cornerRadiusTarget,
            at: elapsed
        )
        let presented = layer.presentation()?.bounds.width ?? bounds.width
        let compensation = bounds.width / max(presented, 1)
        metalSurface?.cornerRadius = radius * compensation
        guard elapsed >= CDKTheme.Motion.transitionDuration else { return }
        stopCornerRadiusAnimation()
    }

    // MARK: - CDKMotionObserver

    public func motionService(_ service: CDKMotionServiceProtocol, didUpdate tilt: CDKTilt) {
        metalSurface?.update(tilt: tilt)
        fallbackSurface?.update(tilt: tilt)
    }
}
