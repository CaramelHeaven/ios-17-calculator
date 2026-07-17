import SnapKit
import UIKit

final class HistoryViewController: UIViewController {
    /// Вызывается при тапе по строке — прокидывает результат обратно в калькулятор.
    var onPick: ((HistoryEntry) -> Void)?

    private let service: CalculationHistoryService
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let titleLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    private var sections: [CalculationHistoryService.Section] = []

    init(service: CalculationHistoryService = .shared) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        drawSelf()
        makeConstraints()
        reload()
    }

    private func drawSelf() {
        titleLabel.text = "История"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        clearButton.setTitle("Очистить", for: .normal)
        clearButton.setTitleColor(.hex("#ff9f0a"), for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 17)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseID)
        tableView.contentInset = .init(top: 8, left: 0, bottom: 24, right: 0)

        emptyLabel.text = "Нет истории"
        emptyLabel.textColor = .hex("#8f8f94")
        emptyLabel.font = .systemFont(ofSize: 17)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(titleLabel)
        view.addSubview(clearButton)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
    }

    private func makeConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().inset(20)
        }
        clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(20)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
    }

    private func reload() {
        sections = service.groupedByDate()
        emptyLabel.isHidden = !sections.isEmpty
        clearButton.isHidden = sections.isEmpty
        tableView.reloadData()
    }

    @objc private func didTapClear() {
        service.clearAll()
        reload()
    }

    private func entry(at indexPath: IndexPath) -> HistoryEntry {
        sections[indexPath.section].items[indexPath.row]
    }
}

// MARK: - UITableViewDataSource

extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryCell.reuseID, for: indexPath
        )
        (cell as? HistoryCell)?.configure(with: entry(at: indexPath))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .hex("#8f8f94")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let picked = entry(at: indexPath)
        onPick?(picked)
        dismiss(animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let target = entry(at: indexPath)
        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, done in
            self?.service.delete(target)
            self?.reload()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let target = entry(at: indexPath)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let copyExpression = UIAction(
                title: "Скопировать выражение",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = target.expression
            }
            let copyResult = UIAction(
                title: "Скопировать результат",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = target.result.format()
            }
            let delete = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.service.delete(target)
                self?.reload()
            }
            return UIMenu(children: [copyExpression, copyResult, delete])
        }
    }
}

// MARK: - Cell

private final class HistoryCell: UITableViewCell {
    static let reuseID = "HistoryCell"

    private let expressionLabel = UILabel()
    private let resultLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        expressionLabel.textColor = .hex("#8f8f94")
        expressionLabel.font = .systemFont(ofSize: 15)
        expressionLabel.textAlignment = .right

        resultLabel.textColor = .white
        resultLabel.font = .systemFont(ofSize: 34, weight: .regular)
        resultLabel.textAlignment = .right
        resultLabel.adjustsFontSizeToFitWidth = true
        resultLabel.minimumScaleFactor = 0.5

        contentView.addSubview(expressionLabel)
        contentView.addSubview(resultLabel)

        expressionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(expressionLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with entry: HistoryEntry) {
        expressionLabel.text = entry.expression
        resultLabel.text = entry.result.format()
    }
}
