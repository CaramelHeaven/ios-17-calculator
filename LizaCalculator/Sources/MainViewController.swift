import Foundation
import SnapKit
import UIKit

extension MainViewController: UIEditMenuInteractionDelegate {
    func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        var actions = suggestedActions

        let customMenu = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "Copy") { _ in
                print("menuItem1")
            },
            UIAction(title: "Paste") { _ in
                print("menuItem2")
            },

        ])

        actions.append(customMenu)

//        return UIMenu(children: actions) // For Custom and Suggested Menu

        return UIMenu(children: customMenu.children) // For Custom Menu Only
    }
}

final class MainViewController: UIViewController {
    // MARK: - Properties

    private let numbersLabel = UILabel()

    private let ACButton = NumberButton(.instrument)
    private let posNegButton = NumberButton(.instrument)
    private let modularButton = NumberButton(.instrument)

    private let divideButton = NumberButton(.operation)
    private let multiplyButton = NumberButton(.operation)
    private let subtractButton = NumberButton(.operation)
    private let addbutton = NumberButton(.operation)
    private let resultbutton = NumberButton(.operation)

    private let buttonDot = NumberButton(.number)
    private let button0 = NumberButton(.number)
    private let button1 = NumberButton(.number)
    private let button2 = NumberButton(.number)
    private let button3 = NumberButton(.number)
    private let button4 = NumberButton(.number)
    private let button5 = NumberButton(.number)
    private let button6 = NumberButton(.number)
    private let button7 = NumberButton(.number)
    private let button8 = NumberButton(.number)
    private let button9 = NumberButton(.number)

    private lazy var numberButtons = [
        button1, button2, button3, button4, button5, button6, button7, button8, button9
    ]

    private lazy var operationButtons = [
        divideButton, multiplyButton, subtractButton, addbutton
    ]

    private let stackView0DotResult = UIStackView()
    private let stackView123 = UIStackView()
    private let stackView456 = UIStackView()
    private let stackView789 = UIStackView()
    private let stackViewAC = UIStackView()

    private var editMenuInteraction: UIEditMenuInteraction?

    private let spacingHorizontalButtons = 8

    override func viewDidLoad() {
        view.backgroundColor = .black

        drawSelf()
        setupEditMenuInteraction()
        makeConstraints()
    }

    private func setupEditMenuInteraction() {
        // Addding Menu Interaction to TextView
        editMenuInteraction = UIEditMenuInteraction(delegate: self)
        numbersLabel.addInteraction(editMenuInteraction!)

        // Addding Long Press Gesture

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.25
        numbersLabel.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .possible:
            print("possible")
        case .began:
            print("began")
        case .changed:
            print("changed")
        case .ended:
            print("ended")
        case .cancelled:
            print("calceleld")
        case .failed:
            print("failed")
        case .recognized:
            print("recognized")
        default:
            break
        }
        guard gestureRecognizer.state == .began else { return }

        let configuration = UIEditMenuConfiguration(
            identifier: "numbersLabel",
            sourcePoint: gestureRecognizer.location(in: numbersLabel)
        )

        editMenuInteraction?.presentEditMenu(with: configuration)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        button0.backgroundColor = .hex("#3a3a3c")
        button0.layer.cornerRadius = 40
        buttonDot.backgroundColor = .hex("#3a3a3c")
        buttonDot.layer.cornerRadius = buttonDot.bounds.width / 2
        resultbutton.backgroundColor = .hex("#f2a33a")
        resultbutton.layer.cornerRadius = resultbutton.bounds.width / 2

        numberButtons.forEach { view in
            view.backgroundColor = .hex("#3a3a3c")
            view.layer.cornerRadius = view.bounds.width / 2
        }
        [ACButton, posNegButton, modularButton].forEach { view in
            view.backgroundColor = .hex("#8f8f94")
            view.layer.cornerRadius = view.bounds.width / 2
        }
        [addbutton, subtractButton, multiplyButton, divideButton].forEach { view in
            view.layer.cornerRadius = view.bounds.width / 2
            view.backgroundColor = .hex("#f2a33a")
        }
    }

    // MARK: - Lifecycle

    private func drawSelf() {
        numbersLabel.text = "0"
        numbersLabel.textColor = .white
        numbersLabel.font = .systemFont(ofSize: 78)
        numbersLabel.textAlignment = .right
        numbersLabel.numberOfLines = 1

        numbersLabel.lineBreakMode = .byTruncatingMiddle
        numbersLabel.adjustsFontSizeToFitWidth = true
        numbersLabel.minimumScaleFactor = 0.5

        numbersLabel.isUserInteractionEnabled = true
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLabel(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLabel(_:)))
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        numbersLabel.addGestureRecognizer(leftSwipe)
        numbersLabel.addGestureRecognizer(rightSwipe)

        stackView0DotResult.axis = .horizontal
        stackView0DotResult.alignment = .center
        stackView0DotResult.distribution = .fill
        stackView0DotResult.spacing = CGFloat(spacingHorizontalButtons)

        [stackView123, stackView456, stackView789, stackViewAC].forEach { view in
            view.axis = .horizontal
            view.alignment = .center
            view.distribution = .fillEqually
            view.spacing = CGFloat(spacingHorizontalButtons)
        }

        button0.label.text = "0"
//        button0.setTitleColor(.white, for: .normal)
//        button0.contentHorizontalAlignment = .left
//        button0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 27, bottom: 0, right: 0)
//        button0.titleLabel?.font = .systemFont(ofSize: 40)
        button0.addTarget(self, action: #selector(didTapNumberButton(_:)), for: .touchUpInside)

        ACButton.label.text = "AC"
        ACButton.label.font = .systemFont(ofSize: 32)

        posNegButton.label.text = "+/-"
        posNegButton.label.font = .systemFont(ofSize: 32)

        modularButton.label.text = "%"
        modularButton.label.font = .systemFont(ofSize: 32)

        // ------
        divideButton.label.text = "/"
//        divideButton.setTitle("/", for: .normal)
//        divideButton.setTitleColor(.white, for: .normal)
//        divideButton.titleLabel?.font = .systemFont(ofSize: 32)
        multiplyButton.label.text = "x"
        subtractButton.label.text = "-"
        addbutton.label.text = "+"

//        multiplyButton.setTitle("x", for: .normal)
//        multiplyButton.setTitleColor(.white, for: .normal)
//        multiplyButton.titleLabel?.font = .systemFont(ofSize: 40)
        // ------

        [ACButton, posNegButton, modularButton].forEach { button in
            button.addTarget(self, action: #selector(didTapNumberButton(_:)), for: .touchUpInside)
        }
        [divideButton, multiplyButton, subtractButton, addbutton].forEach { button in
            button.addTarget(self, action: #selector(didTapOperationButton(_:)), for: .touchUpInside)
        }

        resultbutton.label.text = "="
//        resultbutton.setTitle("=", for: .normal)
//        resultbutton.setTitleColor(.white, for: .normal)
//        resultbutton.titleLabel?.font = .systemFont(ofSize: 40)
        resultbutton.addTarget(self, action: #selector(didTapResultButton(_:)), for: .touchUpInside)

        buttonDot.label.text = "."
//        buttonDot.setTitleColor(.white, for: .normal)
//        buttonDot.titleLabel?.font = .systemFont(ofSize: 32)
        buttonDot.addTarget(self, action: #selector(didTapNumberButton(_:)), for: .touchUpInside)

        numberButtons.indices.forEach { index in
            (numberButtons[index] as? NumberButton)?.label.text = "\(index + 1)"
//            numberButtons[index].setTitle("\(index + 1)", for: .normal)
//            numberButtons[index].setTitleColor(.white, for: .normal)
//            numberButtons[index].titleLabel?.font = .systemFont(ofSize: 40)
            numberButtons[index].addTarget(self, action: #selector(didTapNumberButton(_:)), for: .touchUpInside)
        }

        view.addSubview(numbersLabel)
        view.addSubview(stackView0DotResult)
        view.addSubview(stackView123)
        view.addSubview(stackView456)
        view.addSubview(stackView789)
        view.addSubview(stackViewAC)
        [button0, buttonDot, resultbutton].forEach { stackView0DotResult.addArrangedSubview($0) }
        [button1, button2, button3, addbutton].forEach { stackView123.addArrangedSubview($0) }
        [button4, button5, button6, subtractButton].forEach { stackView456.addArrangedSubview($0) }
        [button7, button8, button9, multiplyButton].forEach { stackView789.addArrangedSubview($0) }
        [ACButton, posNegButton, modularButton, divideButton].forEach { stackViewAC.addArrangedSubview($0) }
    }

    private func makeConstraints() {
        let buttonsSize: Int = Int(UIScreen.main.bounds.width) - 16 - 16 -
            spacingHorizontalButtons - spacingHorizontalButtons - spacingHorizontalButtons
        let result = buttonsSize / 4

        numbersLabel.snp.makeConstraints { make in
            make.bottom.equalTo(stackViewAC.snp.top).offset(-30)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        stackView0DotResult.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(32)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        stackView123.snp.makeConstraints { make in
            make.bottom.equalTo(stackView0DotResult.snp.top).offset(-spacingHorizontalButtons)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        stackView456.snp.makeConstraints { make in
            make.bottom.equalTo(stackView123.snp.top).offset(-spacingHorizontalButtons)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        stackView789.snp.makeConstraints { make in
            make.bottom.equalTo(stackView456.snp.top).offset(-spacingHorizontalButtons)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        stackViewAC.snp.makeConstraints { make in
            make.bottom.equalTo(stackView789.snp.top).offset(-spacingHorizontalButtons)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        button0.snp.makeConstraints { $0.height.equalTo(result) }

        [buttonDot, resultbutton].forEach { view in
            view.snp.makeConstraints { $0.size.equalTo(result) }
        }
        numberButtons.forEach { view in
            view.snp.makeConstraints { $0.size.equalTo(result) }
        }
        [ACButton, posNegButton, modularButton].forEach { view in
            view.snp.makeConstraints { $0.size.equalTo(result) }
        }
        [addbutton, subtractButton, multiplyButton, divideButton].forEach { view in
            view.snp.makeConstraints { $0.size.equalTo(result) }
        }
    }
}

// MARK: - Actions
private extension MainViewController {
    @objc func didTapNumberButton(_ sender: NumberButton) {
        guard let number = sender.label.text else {
            return
        }
        operationButtons.forEach { $0.isSelected = false }

        numbersLabel.text = NewCalculatorService.shared.didTapNumber(number)
    }

    @objc func didTapOperationButton(_ sender: NumberButton) {
        guard let operation = sender.label.text else {
            return
        }
        guard let index = operationButtons.firstIndex(where: { $0.hashValue == sender.hashValue }) else {
            return
        }
        operationButtons.forEach { $0.isSelected = false }
        operationButtons[index].isSelected = true

        let prematureResultIfNeeded = NewCalculatorService.shared.didTapOperator(operation)
        guard let prematureResultIfNeeded else {
            return
        }
        numbersLabel.text = prematureResultIfNeeded.format()
    }

    @objc func didTapResultButton(_ sender: NumberButton) {
        numbersLabel.text = NewCalculatorService.shared
            .didTapResultButton()
            .format()
    }

    @objc func didSwipeLabel(_ sender: UISwipeGestureRecognizer) {
        guard sender.direction == .left || sender.direction == .right else {
            return
        }

        numbersLabel.text = NewCalculatorService.shared.didSwipeLabel().format()
    }
}

// MARK: - Common extensions

private extension String {
    func format() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "

        guard let decimal = Decimal(string: self) else { return "Error" }
        let doubleValue = (decimal as NSDecimalNumber).doubleValue

        if abs(doubleValue) >= 10000 {
            formatter.maximumFractionDigits = 2 // Keep decimals
        } else {
            formatter.maximumFractionDigits = 2 // Keep decimals always
        }

        return formatter.string(from: decimal as NSNumber) ?? "Error"
    }
}

extension UIColor {
    static func hex(_ hex: String) -> UIColor {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
