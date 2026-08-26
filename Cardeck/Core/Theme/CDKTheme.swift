//
//  CDKTheme.swift
//  Cardeck
//

import UIKit

/// Единственный источник правды по внешнему виду приложения.
///
/// Любое значение цвета, шрифта, отступа, радиуса, тени или параметра анимации
/// берётся отсюда. Магических чисел в коде экранов быть не должно.
public enum CDKTheme {

    // MARK: - Цвета

    /// Палитра поверхностей и текста тёмной темы.
    public enum Color {
        /// Фон приложения, #0E0E12.
        public static let background = UIColor(cdkHex: 0x0E0E12)
        /// Поверхность карточки/панели, #17171F.
        public static let surface = UIColor(cdkHex: 0x17171F)
        /// Приподнятая поверхность, #1F1F29.
        public static let surfaceElevated = UIColor(cdkHex: 0x1F1F29)
        /// Основной текст, #F2F2F7.
        public static let textPrimary = UIColor(cdkHex: 0xF2F2F7)
        /// Вторичный текст, #8E8E9A.
        public static let textSecondary = UIColor(cdkHex: 0x8E8E9A)
        /// Акцент, #6E5BFF.
        public static let accent = UIColor(cdkHex: 0x6E5BFF)
        /// Деструктивное действие, #FF4D5E.
        public static let destructive = UIColor(cdkHex: 0xFF4D5E)
        /// Разделитель на поверхности.
        public static let separator = UIColor(cdkHex: 0xF2F2F7, alpha: 0.08)
    }

    // MARK: - Типографика

    /// Шрифтовая шкала на SF Pro Rounded, масштабируется через `UIFontMetrics`.
    public enum Font {
        /// 34 bold — заголовок экрана.
        public static var largeTitle: UIFont { rounded(34, .bold, .largeTitle) }
        /// 22 semibold — заголовок секции, название карты.
        public static var title: UIFont { rounded(22, .semibold, .title2) }
        /// 17 regular — основной текст.
        public static var body: UIFont { rounded(17, .regular, .body) }
        /// 15 medium — подписи кнопок и полей.
        public static var callout: UIFont { rounded(15, .medium, .callout) }
        /// 13 regular — второстепенные подписи.
        public static var caption: UIFont { rounded(13, .regular, .caption1) }

        /// Моноширинный шрифт для номера карты — читаемый fallback вместо штрихкода.
        public static func mono(_ size: CGFloat, _ weight: UIFont.Weight = .medium) -> UIFont {
            UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: .monospacedSystemFont(ofSize: size, weight: weight))
        }

        /// Скруглённый системный шрифт заданного размера с поддержкой Dynamic Type.
        public static func rounded(
            _ size: CGFloat,
            _ weight: UIFont.Weight,
            _ style: UIFont.TextStyle
        ) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let font = base.fontDescriptor.withDesign(.rounded).map {
                UIFont(descriptor: $0, size: size)
            } ?? base
            return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        }
    }

    // MARK: - Метрика

    /// Отступы, кратные 4. Чистые константы, доступны вне главного актора.
    public nonisolated enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    /// Радиусы скругления.
    public nonisolated enum Radius {
        /// Радиус карты лояльности.
        public static let card: CGFloat = 22
        /// Радиус карты на детальном экране.
        public static let cardExpanded: CGFloat = 28
        /// Радиус кнопки.
        public static let button: CGFloat = 14
        /// Радиус панели/секции.
        public static let surface: CGFloat = 18
    }

    /// Параметры тени карты. Всегда применяются вместе с `shadowPath`.
    public enum Shadow {
        public static let offset = CGSize(width: 0, height: 8)
        public static let blur: CGFloat = 24
        public static let opacity: Float = 0.35
        public static let color = UIColor.black.cgColor

        /// Усиленная тень для карты, поднятой пальцем при переупорядочивании.
        public static let liftedOffset = CGSize(width: 0, height: 18)
        public static let liftedBlur: CGFloat = 36
        public static let liftedOpacity: Float = 0.5
    }

    // MARK: - Геометрия карты

    /// Пропорции и размеры карты лояльности.
    public nonisolated enum Card {
        /// Соотношение сторон ISO/IEC 7810 ID-1.
        public static let aspectRatio: CGFloat = 1.586
        /// Горизонтальный отступ карты в стопке от краёв экрана.
        public static let stackHorizontalInset: CGFloat = 20
        /// Горизонтальный отступ карты на детальном экране.
        public static let detailHorizontalInset: CGFloat = 16
        /// Базовый шаг между картами в стопке.
        public static let stackStep: CGFloat = 62
        /// Минимальный шаг между прижатыми сверху картами.
        public static let pinnedStep: CGFloat = 14
        /// Максимум видимых прижатых карт, остальные скрываются.
        public static let maxPinnedCards: Int = 4
        /// Отступ линии прижатия от `safeArea.top`.
        public static let pinInset: CGFloat = 12
        /// Перспектива для 3D-трансформа стопки.
        public static let perspective: CGFloat = -1.0 / 700.0
        /// Сдвиг по оси Z на одну ступень глубины.
        public static let depthZStep: CGFloat = 8
        /// Масштаб самой глубокой видимой карты.
        public static let deepestScale: CGFloat = 0.92
        /// Прозрачность карты, уходящей за пределы видимой части стопки.
        public static let fadedAlpha: CGFloat = 0.55
        /// Масштаб карты, поднятой для переупорядочивания.
        public static let liftedScale: CGFloat = 1.04
        /// Отступ контента от краёв карты.
        public static let contentInset: CGFloat = 16
        /// Верхний отступ контента: название и категория обязаны уместиться
        /// в видимую полосу высотой ``stackStep``, иначе их накроет соседняя карта.
        public static let contentTopInset: CGFloat = 12

        /// Высота карты по её ширине.
        public static func height(forWidth width: CGFloat) -> CGFloat {
            (width / aspectRatio).rounded()
        }
    }

    // MARK: - Анимация

    /// Пружины. Линейных кривых и «duration 0.3 по умолчанию» в проекте нет.
    public enum Motion {
        /// Пружина перехода карты в детальный экран.
        public static let transitionDuration: TimeInterval = 0.55
        public static let transitionMass: CGFloat = 1.0
        public static let transitionStiffness: CGFloat = 220
        public static let transitionDamping: CGFloat = 26

        /// Задержка появления контента детального экрана.
        public static let contentDelay: TimeInterval = 0.12
        /// Задержка между соседними картами, разъезжающимися при переходе.
        public static let stagger: TimeInterval = 0.03

        /// Пружина мелких интерактивных реакций (нажатие, подъём карты).
        public static func snappy(_ duration: TimeInterval = 0.35) -> UIViewPropertyAnimator {
            UIViewPropertyAnimator(
                duration: duration,
                timingParameters: UISpringTimingParameters(
                    mass: 1.0, stiffness: 320, damping: 26, initialVelocity: .zero
                )
            )
        }

        /// Пружина перехода карты, опционально с начальной скоростью жеста.
        public static func transition(
            initialVelocity: CGVector = .zero
        ) -> UIViewPropertyAnimator {
            UIViewPropertyAnimator(
                duration: transitionDuration,
                timingParameters: UISpringTimingParameters(
                    mass: transitionMass,
                    stiffness: transitionStiffness,
                    damping: transitionDamping,
                    initialVelocity: initialVelocity
                )
            )
        }
    }
}
