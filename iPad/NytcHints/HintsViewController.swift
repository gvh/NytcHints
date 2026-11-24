import NytcHintsCore
import UIKit

/// Pick a source and a date; shows that day's four hints.
final class HintsViewController: UIViewController {
    private let sourceControl = UISegmentedControl(items: SourceName.allCases.map(\.source.name))
    private let datePicker = UIDatePicker()
    private let controls = UIStackView()
    private let controlsSpacer = UIView()
    private let cardsStack = UIStackView()
    private let contentStack = UIStackView()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()

    private var loadTask: Task<Void, Never>?

    /// Successful results for this session, so flipping between sources doesn't refetch whole articles.
    /// Failures aren't stored, so pulling down always retries them.
    private var cache: [String: [Hint]] = [:]

    /// The day the date limits were last computed for.
    private var lastToday = PuzzleDate.today

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connections Hints"
        view.backgroundColor = .systemBackground

        sourceControl.selectedSegmentIndex = 0
        sourceControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        updateDateLimits()

        controls.addArrangedSubview(sourceControl)
        controls.addArrangedSubview(controlsSpacer)
        controls.addArrangedSubview(datePicker)
        controls.spacing = 16
        updateControlsLayout()
        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.updateControlsLayout()
        }

        cardsStack.axis = .vertical
        cardsStack.spacing = 12

        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.adjustsFontForContentSizeCategory = true

        spinner.hidesWhenStopped = true

        let content = contentStack
        [controls, cardsStack, statusLabel, spinner].forEach(content.addArrangedSubview)
        content.axis = .vertical
        content.spacing = 24
        content.isLayoutMarginsRelativeArrangement = true
        content.translatesAutoresizingMaskIntoConstraints = false

        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        // The content is exactly as wide as the scroll view, so it scrolls vertically only.
        // Readable-width insets are applied as layout margins in viewDidLayoutSubviews.
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        NotificationCenter.default.addObserver(
            self, selector: #selector(dayMayHaveChanged),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(dayMayHaveChanged),
            name: UIApplication.significantTimeChangeNotification, object: nil)

        loadHints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let readable = view.readableContentGuide.layoutFrame
        let margins = NSDirectionalEdgeInsets(
            top: 24, leading: readable.minX, bottom: 24, trailing: view.bounds.width - readable.maxX)
        if contentStack.directionalLayoutMargins != margins {
            contentStack.directionalLayoutMargins = margins
        }
    }

    /// Source and date sit side by side when there's room, and stack when the width is compact
    /// or the text size is large enough that they'd be cramped.
    private func updateControlsLayout() {
        let stacked = traitCollection.horizontalSizeClass == .compact
            || traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        controls.axis = stacked ? .vertical : .horizontal
        controls.alignment = stacked ? .leading : .center
        controls.spacing = stacked ? 12 : 16
        controlsSpacer.isHidden = stacked
    }

    /// Puzzles exist from the first Connections day through tomorrow's (posted the evening before).
    private func updateDateLimits() {
        let calendar = Calendar.current
        datePicker.minimumDate = PuzzleDate.firstPuzzle.startOfDay
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) {
            datePicker.maximumDate = calendar.date(byAdding: .day, value: 1, to: tomorrow)?.addingTimeInterval(-1)
        }
    }

    /// If the app was left open past midnight, roll the limits forward, and the picker too if it was showing "today".
    @objc private func dayMayHaveChanged() {
        let today = PuzzleDate.today
        guard today != lastToday else { return }
        let wasShowingToday = PuzzleDate(date: datePicker.date) == lastToday
        lastToday = today
        updateDateLimits()
        if wasShowingToday {
            datePicker.setDate(Date(), animated: false)
            loadHints()
        }
    }

    @objc private func selectionChanged() {
        loadHints()
    }

    @objc private func refreshPulled() {
        loadHints(useCache: false)
    }

    private func loadHints(useCache: Bool = true) {
        let source = SourceName.allCases[sourceControl.selectedSegmentIndex].source
        let date = PuzzleDate(date: datePicker.date)
        let cacheKey = "\(source.name)|\(date)"

        loadTask?.cancel()
        show(status: nil)
        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if useCache, let hints = cache[cacheKey] {
            refreshControl.endRefreshing()
            spinner.stopAnimating()
            show(hints)
            return
        }

        // The refresh control is its own progress indicator while it's pulled down.
        if !refreshControl.isRefreshing {
            spinner.startAnimating()
        }

        loadTask = Task { [weak self] in
            let result = await Fetcher().fetch(source, for: date)
            guard !Task.isCancelled, let self else { return }
            spinner.stopAnimating()
            refreshControl.endRefreshing()
            switch result {
            case .success(let hints):
                cache[cacheKey] = hints
                show(hints)
            case .failure(let error):
                let message = "\(source.name) hints unavailable for \(date).\n\(error.userMessage)"
                show(status: message)
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    private func show(_ hints: [Hint]) {
        hints.forEach { cardsStack.addArrangedSubview(HintCardView(hint: $0)) }
        UIAccessibility.post(notification: .announcement, argument: "Hints loaded")
    }

    private func show(status: String?) {
        statusLabel.text = status
        statusLabel.isHidden = status == nil
    }
}

private extension HintError {
    /// Plain-language text for the status label. The technical `description` stays for the command-line tool.
    var userMessage: String {
        switch self {
        case .network:
            "Couldn't reach the site. Check your connection, then pull down to try again."
        case .badStatus(404):
            "No hints have been posted for this date yet. Pull down to try again."
        case .badStatus:
            "The site had a problem. Pull down to try again later."
        case .answersDetected:
            "This page looked like it gave away the answers, so no hints are shown. Try another source."
        case .parse, .invalidDate:
            "Couldn't read the hints from this page. The site may have changed its layout. Try another source."
        }
    }
}
