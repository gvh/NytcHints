import NytcHintsCore
import UIKit

/// Pick a source and a date; shows that day's four hints.
final class HintsViewController: UIViewController {
    private let sourceControl = UISegmentedControl(items: SourceName.allCases.map(\.source.name))
    private let datePicker = UIDatePicker()
    private let cardsStack = UIStackView()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)

    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connections Hints"
        view.backgroundColor = .systemBackground

        sourceControl.selectedSegmentIndex = 0
        sourceControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        datePicker.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        let controls = UIStackView(arrangedSubviews: [sourceControl, UIView(), datePicker])
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 16

        cardsStack.axis = .vertical
        cardsStack.spacing = 12

        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.adjustsFontForContentSizeCategory = true

        spinner.hidesWhenStopped = true

        let content = UIStackView(arrangedSubviews: [controls, cardsStack, statusLabel, spinner])
        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        let readable = scrollView.readableContentGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: readable.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: readable.trailingAnchor),
        ])

        loadHints()
    }

    @objc private func selectionChanged() {
        loadHints()
    }

    private func loadHints() {
        let source = SourceName.allCases[sourceControl.selectedSegmentIndex].source
        let date = PuzzleDate(date: datePicker.date)

        loadTask?.cancel()
        show(status: nil)
        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        spinner.startAnimating()

        loadTask = Task {
            let result = await Fetcher().fetch(source, for: date)
            guard !Task.isCancelled else { return }
            spinner.stopAnimating()
            switch result {
            case .success(let hints):
                hints.forEach { cardsStack.addArrangedSubview(HintCardView(hint: $0)) }
            case .failure(let error):
                show(status: "\(source.name) hints unavailable for \(date).\n\(error)")
            }
        }
    }

    private func show(status: String?) {
        statusLabel.text = status
        statusLabel.isHidden = status == nil
    }
}
