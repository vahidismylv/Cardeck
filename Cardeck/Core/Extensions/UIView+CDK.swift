import UIKit

public extension UIView {

    func cdkAddSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
    }

    func cdkPin(to guide: UILayoutGuide, inset: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: guide.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -inset)
        ])
    }

    func cdkPin(to view: UIView, inset: CGFloat = 0) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            topAnchor.constraint(equalTo: view.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -inset)
        ])
    }
}

public extension CALayer {

    func cdkApplyCardShadow(cornerRadius: CGFloat, lifted: Bool = false) {
        shadowColor = CDKTheme.Shadow.color
        shadowOffset = lifted ? CDKTheme.Shadow.liftedOffset : CDKTheme.Shadow.offset
        shadowRadius = (lifted ? CDKTheme.Shadow.liftedBlur : CDKTheme.Shadow.blur) / 2
        shadowOpacity = lifted ? CDKTheme.Shadow.liftedOpacity : CDKTheme.Shadow.opacity
        shouldRasterize = false
        shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
}

public extension CGFloat {

    func cdkClamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, lower), upper)
    }
}
