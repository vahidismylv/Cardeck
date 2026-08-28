import UIKit

public final class CDKLaunchView: UIView {

    public static let markSide: CGFloat = 220

    private let markView = UIImageView(image: UIImage(named: "LaunchMark"))
    private let titleLabel = UILabel()
    private let progressTrack = UIView()
    private let progressBar = UIView()
    private var progressWidth: NSLayoutConstraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    public func start() {
        let breathe = CABasicAnimation(keyPath: "transform.scale")
        breathe.fromValue = 1.0
        breathe.toValue = 1.05
        breathe.duration = 0.9
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        markView.layer.add(breathe, forKey: "cdkBreathe")

        let reveal = CDKTheme.Motion.snappy(0.5)
        reveal.addAnimations {
            self.titleLabel.alpha = 1
            self.progressTrack.alpha = 1
        }
        reveal.startAnimation(afterDelay: 0.1)

        layoutIfNeeded()
        progressWidth?.constant = progressTrack.bounds.width
        let fill = UIViewPropertyAnimator(duration: 0.85, curve: .easeInOut) {
            self.layoutIfNeeded()
        }
        fill.startAnimation(afterDelay: 0.1)
    }

    public func finish(completion: @escaping () -> Void) {
        markView.layer.removeAnimation(forKey: "cdkBreathe")
        let animator = CDKTheme.Motion.transition()
        animator.addAnimations {
            self.markView.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.markView.alpha = 0
            self.titleLabel.alpha = 0
            self.progressTrack.alpha = 0
        }
        animator.addAnimations({ self.alpha = 0 }, delayFactor: 0.25)
        animator.addCompletion { _ in
            self.removeFromSuperview()
            completion()
        }
        animator.startAnimation()
    }

    private func setUp() {
        backgroundColor = CDKTheme.Color.background
        isUserInteractionEnabled = false

        markView.contentMode = .scaleAspectFit

        titleLabel.text = "Cardeck"
        titleLabel.font = CDKTheme.Font.title
        titleLabel.textColor = CDKTheme.Color.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0

        progressTrack.backgroundColor = CDKTheme.Color.surfaceElevated
        progressTrack.layer.cornerRadius = 2
        progressTrack.alpha = 0
        progressBar.backgroundColor = CDKTheme.Color.accent
        progressBar.layer.cornerRadius = 2

        progressTrack.cdkAddSubview(progressBar)
        cdkAddSubview(markView)
        cdkAddSubview(titleLabel)
        cdkAddSubview(progressTrack)

        let width = progressBar.widthAnchor.constraint(equalToConstant: 0)
        progressWidth = width

        NSLayoutConstraint.activate([
            markView.centerXAnchor.constraint(equalTo: centerXAnchor),
            markView.centerYAnchor.constraint(equalTo: centerYAnchor),
            markView.widthAnchor.constraint(equalToConstant: Self.markSide),
            markView.heightAnchor.constraint(equalToConstant: Self.markSide),

            titleLabel.topAnchor.constraint(
                equalTo: markView.bottomAnchor, constant: CDKTheme.Spacing.s
            ),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            progressTrack.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: CDKTheme.Spacing.l
            ),
            progressTrack.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressTrack.widthAnchor.constraint(equalToConstant: 120),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),

            progressBar.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            width
        ])
    }
}
