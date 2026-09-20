import NytcHintsCore
import UIKit

/// One colored card showing a group's color name and its hint.
final class HintCardView: UIView {
    private let colorLabel = UILabel()
    private let hintLabel = UILabel()

    init(hint: Hint) {
        super.init(frame: .zero)

        backgroundColor = hint.color.fillColor
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous

        colorLabel.text = hint.color.label.uppercased()
        colorLabel.font = .preferredFont(forTextStyle: .caption1).withWeight(.bold)
        colorLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        colorLabel.adjustsFontForContentSizeCategory = true

        hintLabel.text = hint.text
        hintLabel.font = .preferredFont(forTextStyle: .title2).withWeight(.semibold)
        hintLabel.textColor = .black
        hintLabel.numberOfLines = 0
        hintLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [colorLabel, hintLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "\(hint.color.label) hint: \(hint.text)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension HintColor {
    /// The tile colors used in the NYT game.
    var fillColor: UIColor {
        switch self {
        case .yellow: UIColor(red: 0.976, green: 0.875, blue: 0.427, alpha: 1)
        case .green: UIColor(red: 0.627, green: 0.765, blue: 0.353, alpha: 1)
        case .blue: UIColor(red: 0.690, green: 0.769, blue: 0.937, alpha: 1)
        case .purple: UIColor(red: 0.729, green: 0.506, blue: 0.773, alpha: 1)
        }
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
