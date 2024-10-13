import Foundation
import UIKit

enum NumberButtonType {
    case one, two, three, four, five, six, seven, eight, nine
}

final class CalculatorService {
    static let shared = CalculatorService()
    private init() {}

    private let numbers = Numbers()

    func didTapNumberButton(sender: UIButton, labelText: String) -> String {
        let stringValue = sender.currentTitle!
        switch stringValue {
        case "+/-": numbers.applyPositiveNegative(stringValue)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": numbers.enter(stringValue)
        case "%": numbers.applyMod()
        case "AC", "C": numbers.reset()
        case ",": numbers.applyDot()
        default: break
        }

        switch numbers.state {
        case let .enteringFirst(value):
            print("[newDidTapNumberButton] EnteringFirst -> \(value!)")
            return String(describing: value!)
        case let .enteringSecond(value):
            print("[newDidTapNumberButton] EnteringSecond -> \(value!)")
            return String(describing: value!)
        }
    }

    func didTapOperatorButton(sender: UIButton) {
        numbers.applyOperator(sender.currentTitle!)
    }

    func didTapResultButton() -> String {
        numbers.makeResult()
    }

    func didSwipeLabel() -> String {
        numbers.removeSymbol()
    }
}

// MARK: - Numbers
final class Numbers {
    enum FocusState {
        case enteringFirst(Decimal!), enteringSecond(Decimal!)
    }

    enum Operator {
        case plus, minus, multiply, divide
    }

    private var operatorType: Operator?

    private var first: Decimal = 0
    private var second: Decimal = 0
    private var isNewEnteringFirst = true
    private var isNewEnteringSecond = true

    var state = FocusState.enteringFirst(0) {
        didSet {
            switch state {
            case let .enteringFirst(value): first = value!
            case let .enteringSecond(value): second = value!
            }
        }
    }

    func enter(_ value: String) {
        switch state {
        case .enteringFirst:
            var previous = String(describing: first)
            if isNewEnteringFirst {
                previous = "0"
                isNewEnteringFirst = false
            }

            let result = previous == "0" ? value : previous + value

            state = .enteringFirst(Decimal(string: result)!)

        case .enteringSecond:
            var previous = String(describing: second)

            // Это нужно когда: press 8 -> + -> = -> - -> 5 -> =
            if isNewEnteringSecond {
                previous = "0"
                isNewEnteringSecond = false
            }
            let result = previous == "0" ? value : previous + value

            state = .enteringSecond(Decimal(string: result)!)
        }

        print("[enter] -> \(first), | \(second)")
    }

    // 1000 - 5 %  = -> 50 (показывает со 1000) = -> 950
    func applyMod() {
        switch state {
        case let .enteringFirst(value):
            let value = value! / 100
            state = .enteringFirst(value)

        case let .enteringSecond(value):
            let value = (value! / 100) * first
            state = .enteringSecond(value)
        }
    }

    func applyPositiveNegative(_ value: String) {
        switch state {
        case let .enteringFirst(value):
            let value = value! * -1
            state = .enteringFirst(value)
        case let .enteringSecond(value):
            let value = value! * -1
            state = .enteringSecond(value)
        }
    }

    func reset() {
        switch state {
        case .enteringSecond:
            second = 0

        case .enteringFirst:
            first = 0
            second = 0
            state = .enteringFirst(0)

            operatorType = nil
        }
    }

    func applyDot() {}

    func applyOperator(_ value: String) {
        switch value {
        case "+": operatorType = .plus
        case "-": operatorType = .minus
        case "/": operatorType = .divide
        case "x": operatorType = .multiply
        default: break
        }

        // Press 5 -> + -> =
        state = .enteringSecond(first)
        isNewEnteringSecond = true
    }

    func makeResult() -> String {
        let preResult = switch operatorType {
        case .plus: first + second
        case .minus: first - second
        case .multiply: first * second
        case .divide: first / second
        default: first
        }

        state = .enteringFirst(preResult)
        isNewEnteringFirst = true

        return (preResult as NSDecimalNumber).stringValue
    }

    func removeSymbol() -> String {
        var result: String
        switch state {
        case let .enteringFirst(value):
            result = String(describing: value!)
            result.removeLast()
            result = result.isEmpty ? "0" : result

            state = .enteringFirst(Decimal(string: result)!)

        case let .enteringSecond(value):
            result = String(describing: value!)
            result.removeLast()
            result = result.isEmpty ? "0" : result

            state = .enteringSecond(Decimal(string: result)!)
        }

        return result
    }
}
