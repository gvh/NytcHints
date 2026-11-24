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
        colorLabel.font = .scaled(.caption1, weight: .bold)
        // 75% black keeps at least 5:1 contrast on all four tile colors (60% was 3.7:1 on purple).
        colorLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        colorLabel.adjustsFontForContentSizeCategory = true

        hintLabel.text = hint.text
        hintLabel.font = .scaled(.title2, weight: .semibold)
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
    /// A system font at the text style's default size and the given weight, scaled with Dynamic Type.
    static func scaled(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let defaultSize = preferredFont(forTextStyle: style, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize
        return UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: defaultSize, weight: weight))
    }
}
