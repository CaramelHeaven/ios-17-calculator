import Foundation
import UIKit

enum NumberButtonType {
    case one, two, three, four, five, six, seven, eight, nine
}

final class NewCalculatorService {
    static let shared = NewCalculatorService()
    private let test = NewNumbers()

    func didTapNumber(_ number: String) -> String {
        var value = number

        var someValue = ""
        switch value {
        case "AC", "C":
            test.didAC()
            someValue = "0"
        case "%":
            someValue = test.didMod()
        case ".":
            someValue = test.didNumber(value)
        case "+/-":
            someValue = test.applyPositiveNegative()
        default:
            someValue = test.didNumber(value)
        }
        print("didTapNumber: someValue: \(someValue), first: \(test.first), second: \(test.second)")

        return someValue
    }

    func didTapOperator(_ operation: String) -> String? {
        let result = test.didOperator(operation)
        print("didTapOperator: \(operation) first: \(test.first), second: \(test.second)")
        return result
    }

    func didTapResultButton() -> String {
        if test.second.isEmpty {
            test.second = test.first
        }
        let result = test.makeResult()
        test.first = result
        print("test.first: \(test.first), test.second \(test.second)")

        return result
    }

    func didSwipeLabel() -> String {
        test.removeSymbolBySwipe()
    }
}

final class NewNumbers {
    enum InputState {
        case first, second, result
    }

    enum Operator {
        case plus, minus, multiply, divide

        init(_ value: String) {
            switch value {
            case "+": self = .plus
            case "-": self = .minus
            case "/": self = .divide
            case "x": self = .multiply
            default: self = .plus
            }
        }
    }

    var first = ""
    var second = ""
    var result = ""

    var numberOperator = Operator.plus
    var inputState = InputState.first

    func didNumber(_ value: String) -> String {
        print("im here")
        switch inputState {
        case .first:
            if value == ".", first.filter({ $0 == "." }).count == 1 {
                return first
            }
            first += value
            return first
        case .second:
            if value == ".", second.filter({ $0 == "." }).count == 1 {
                return first
            }
            second += value
            return second
        case .result:
            if value == ".", first.filter({ $0 == "." }).count == 1 {
                return first
            }
            inputState = .first
            first += value
            return first
        }
    }

    func didOperator(_ value: String) -> String? {
        var fastResult: String?
        if inputState == .second, !first.isEmpty, !second.isEmpty {
            fastResult = makeResult()
            first = fastResult ?? ""
        }

        inputState = .second
        second.removeAll()
        numberOperator = Operator(value)

        // Когда нажал сразу на оператор
        if first.isEmpty {
            first = "0"
        }

        return fastResult
    }

    func didAC() {
        switch inputState {
        case .first: first = ""
        case .second: second = ""
        case .result: first = ""; second = ""
        }
        numberOperator = .plus
        inputState = .first
    }

    // 1000 - 5 % = [X] = [X]
    func didMod() -> String {
        switch inputState {
        case .first:
            let value = Decimal(string: first)! / 100
            first = (value as NSDecimalNumber).stringValue
            return first
        case .second:
            let value = (Decimal(string: second)! / 100) * Decimal(string: first)!
            second = (value as NSDecimalNumber).stringValue
            return second
        case .result:
            let value = Decimal(string: result)! / 100
            result = (value as NSDecimalNumber).stringValue
            return result
        }
    }

    func makeResult() -> String {
        inputState = .result

        let result = switch numberOperator {
        case .plus: Decimal(string: first)! + Decimal(string: second)!
        case .minus: Decimal(string: first)! - Decimal(string: second)!
        case .multiply: Decimal(string: first)! * Decimal(string: second)!
        case .divide: Decimal(string: first)! / Decimal(string: second)!
        }

        return (result as NSDecimalNumber).stringValue
    }

    func removeSymbolBySwipe() -> String {
        var result: String = ""
        switch inputState {
        case .first:
            result = first
            result.removeLast()

            first = result.isEmpty ? "" : result
            result = first

        case .second:
            result = second
            result.removeLast()

            second = result.isEmpty ? "" : result
            result = second

        case .result:
            result = first
            result.removeLast()

            first = result.isEmpty ? "" : result
            result = first
        }

        return result.isEmpty ? "0" : result
    }

    func applyPositiveNegative() -> String {
        var result: String
        switch inputState {
        case .first:
            if first.isEmpty {
                result = "0"
            } else {
                first = (Decimal(string: first)! * -1 as NSDecimalNumber).stringValue
                result = first
            }
        case .second:
            if second.isEmpty {
                result = "0"
            } else {
                second = (Decimal(string: second)! * -1 as NSDecimalNumber).stringValue
                result = second
            }
        case .result:
            if first.isEmpty {
                result = "0"
            } else {
                first = (Decimal(string: first)! * -1 as NSDecimalNumber).stringValue
                result = first
            }
        }
        return result
    }
}

// MARK: - OLD -------------------------------------------------------------
// final class CalculatorService {
//    static let shared = CalculatorService()
//    private init() {}
//
//    private let numbers = Numbers()
//
//    func didTapNumberButton(sender: UIButton, labelText: String) -> String {
//        let stringValue = sender.currentTitle!
//        switch stringValue {
//        case "+/-": numbers.applyPositiveNegative(stringValue)
//        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": numbers.enter(stringValue)
//        case "%": numbers.applyMod()
//        case "AC", "C": numbers.reset()
//        case ",": return numbers.applyDot()
//        default: break
//        }
//
//        switch numbers.state {
//        case let .enteringFirst(value):
//            print("[newDidTapNumberButton] EnteringFirst -> \(value!)")
//            return String(describing: value!)
//        case let .enteringSecond(value):
//            print("[newDidTapNumberButton] EnteringSecond -> \(value!)")
//            return String(describing: value!)
//        }
//    }
//
//    func didTapOperatorButton(sender: UIButton) {
//        numbers.applyOperator(sender.currentTitle!)
//    }
//
//    func didTapResultButton() -> String {
//        numbers.makeResult()
//    }
//
//    func didSwipeLabel() -> String {
//        numbers.removeSymbol()
//    }
// }
//
// final class Numbers {
//    enum FocusState {
//        case enteringFirst(Decimal!), enteringSecond(Decimal!)
//    }
//
//    enum Operator {
//        case plus, minus, multiply, divide
//    }
//
//    private var operatorType: Operator?
//
//    private var first: Decimal = 0
//    private var second: Decimal = 0
//    private var isNewEnteringFirst = true
//    private var isNewEnteringSecond = true
//
//    private var isDotPressed = false
//
//    var state = FocusState.enteringFirst(0) {
//        didSet {
//            switch state {
//            case let .enteringFirst(value): first = value!
//            case let .enteringSecond(value): second = value!
//            }
//        }
//    }
//
//    func enter(_ value: String) {
//        switch state {
//        case .enteringFirst:
//            var previous = String(describing: first)
//            if isNewEnteringFirst {
//                previous = "0"
//                isNewEnteringFirst = false
//            }
//
//            let lol = if previous == "0" {
//                value
//            } else {
//                isDotPressed ? "\(previous).\(value)" : previous + value
//            }
//            let testingLol = Decimal(string: lol)!
//            let result = previous == "0" ? value : previous + value
//
//            state = .enteringFirst(testingLol)
//
//        case .enteringSecond:
//            var previous = String(describing: second)
//
//            // Это нужно когда: press 8 -> + -> = -> - -> 5 -> =
//            if isNewEnteringSecond {
//                previous = "0"
//                isNewEnteringSecond = false
//            }
//            let result = previous == "0" ? value : previous + value
//
//            state = .enteringSecond(Decimal(string: result)!)
//        }
//
//        print("[enter] -> \(first), | \(second)")
//    }
//
//    // 1000 - 5 %  = -> 50 (показывает со 1000) = -> 950
//    func applyMod() {
//        switch state {
//        case let .enteringFirst(value):
//            let value = value! / 100
//            state = .enteringFirst(value)
//
//        case let .enteringSecond(value):
//            let value = (value! / 100) * first
//            state = .enteringSecond(value)
//        }
//    }
//
//    func applyPositiveNegative(_ value: String) {
//        switch state {
//        case let .enteringFirst(value):
//            let value = value! * -1
//            state = .enteringFirst(value)
//        case let .enteringSecond(value):
//            let value = value! * -1
//            state = .enteringSecond(value)
//        }
//    }
//
//    func reset() {
//        switch state {
//        case .enteringSecond:
//            second = 0
//
//        case .enteringFirst:
//            first = 0
//            second = 0
//            state = .enteringFirst(0)
//
//            operatorType = nil
//        }
//    }
//
//    func applyDot() -> String {
//        isDotPressed = true
//        return switch state {
//        case let .enteringFirst(value):
//            "\(String(describing: value!)),"
//        case let .enteringSecond(value):
//            "\(String(describing: value!)),"
//        }
//    }
//
//    func applyOperator(_ value: String) {
//        switch value {
//        case "+": operatorType = .plus
//        case "-": operatorType = .minus
//        case "/": operatorType = .divide
//        case "x": operatorType = .multiply
//        default: break
//        }
//
//        // Press 5 -> + -> =
//        state = .enteringSecond(first)
//        isNewEnteringSecond = true
//    }
//
//    func makeResult() -> String {
//        let preResult = switch operatorType {
//        case .plus: first + second
//        case .minus: first - second
//        case .multiply: first * second
//        case .divide: first / second
//        default: first
//        }
//
//        state = .enteringFirst(preResult)
//        isNewEnteringFirst = true
//
//        return (preResult as NSDecimalNumber).stringValue
//    }
//
//    func removeSymbol() -> String {
//        var result: String
//        switch state {
//        case let .enteringFirst(value):
//            result = String(describing: value!)
//            result.removeLast()
//            result = result.isEmpty ? "0" : result
//
//            state = .enteringFirst(Decimal(string: result)!)
//
//        case let .enteringSecond(value):
//            result = String(describing: value!)
//            result.removeLast()
//            result = result.isEmpty ? "0" : result
//
//            state = .enteringSecond(Decimal(string: result)!)
//        }
//
//        return result
//    }
// }
