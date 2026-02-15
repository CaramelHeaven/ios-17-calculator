import Foundation

final class CalculatorEngine {
    private enum State {
        case enteringFirst
        case enteringSecond
        case showingResult
    }

    private enum Operator {
        case add, subtract, multiply, divide

        init?(symbol: String) {
            switch symbol {
            case "+": self = .add
            case "-": self = .subtract
            case "x": self = .multiply
            case "/": self = .divide
            default: return nil
            }
        }

        func apply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {
            switch self {
            case .add: return lhs + rhs
            case .subtract: return lhs - rhs
            case .multiply: return lhs * rhs
            case .divide: return rhs == 0 ? 0 : lhs / rhs
            }
        }
    }

    // MARK: - Properties
    private var state: State = .enteringFirst

    private var first: Decimal = 0
    private var second: Decimal = 0

    private var currentOperator: Operator?
    private var lastOperator: Operator?
    private var lastOperand: Decimal?

    private var currentInput: String = "0"

    // MARK: - Public API

    func inputDigit(_ digit: String) -> String {
        switch state {
        case .enteringFirst:
            if currentInput == "0" {
                currentInput = digit
            } else {
                currentInput += digit
            }
            first = Decimal(string: currentInput) ?? 0
            return currentInput

        case .enteringSecond:
            if currentInput == "0" {
                currentInput = digit
            } else {
                currentInput += digit
            }
            second = Decimal(string: currentInput) ?? 0
            return currentInput

        case .showingResult:
            // Если точка есть, не сбрасываем, добавляем к текущему числу
            if currentInput.contains(".") {
                currentInput += digit
                first = Decimal(string: currentInput) ?? first
                return currentInput
            } else {
                // Иначе начинаем новое число
                resetForNewInput()
                currentInput = digit
                first = Decimal(string: currentInput) ?? 0
                state = .enteringFirst
                return currentInput
            }
        }
    }

    func inputDot() -> String {
        if !currentInput.contains(".") {
            currentInput += "."
        }
        return currentInput
    }

    func inputOperator(_ symbol: String) -> String? {
        guard let op = Operator(symbol: symbol) else { return nil }

        switch state {
        case .enteringSecond:
            let result = calculate()
            first = result
            currentInput = formatted(result)
            second = 0
            currentOperator = op
            return currentInput

        case .enteringFirst, .showingResult:
            currentOperator = op
            state = .enteringSecond
            currentInput = "0"
            return nil
        }
    }

    func inputEquals() -> String {
        switch state {
        case .enteringSecond:
            if second == 0, let last = lastOperand {
                second = last
            }
            let result = calculate()
            state = .showingResult
            currentInput = formatted(result)
            return currentInput

        case .showingResult:
            guard let op = lastOperator,
                  let operand = lastOperand else {
                return formatted(first)
            }

            first = op.apply(first, operand)
            currentInput = formatted(first)
            return currentInput

        case .enteringFirst:
            return formatted(first)
        }
    }

    func inputPercent() -> String {
        switch state {
        case .enteringFirst:
            first /= 100
            currentInput = formatted(first)
            return currentInput
        case .enteringSecond:
            second = (second / 100) * first
            currentInput = formatted(second)
            return currentInput
        case .showingResult:
            first /= 100
            currentInput = formatted(first)
            return currentInput
        }
    }

    func toggleSign() -> String {
        switch state {
        case .enteringFirst, .showingResult:
            first *= -1
            currentInput = formatted(first)
            return currentInput
        case .enteringSecond:
            second *= -1
            currentInput = formatted(second)
            return currentInput
        }
    }

    func clear() -> String {
        state = .enteringFirst
        first = 0
        second = 0
        currentOperator = nil
        lastOperator = nil
        lastOperand = nil
        currentInput = "0"
        return "0"
    }

    func backspace() -> String {
        guard currentInput.count > 1 else {
            currentInput = "0"
            updateDecimalFromInput()
            return currentInput
        }
        currentInput.removeLast()
        updateDecimalFromInput()
        return currentInput
    }

    func currentValue() -> String {
        return currentInput
    }
}

// MARK: - Private

private extension CalculatorEngine {
    func calculate() -> Decimal {
        guard let op = currentOperator else { return first }
        let result = op.apply(first, second)
        lastOperator = op
        lastOperand = second
        first = result
        second = 0
        return result
    }

    func formatted(_ value: Decimal) -> String {
        (value as NSDecimalNumber).stringValue
    }

    func updateDecimalFromInput() {
        let value = Decimal(string: currentInput) ?? 0
        switch state {
        case .enteringFirst, .showingResult: first = value
        case .enteringSecond: second = value
        }
    }

    func resetForNewInput() {
        currentOperator = nil
        lastOperator = nil
        lastOperand = nil
        first = 0
        second = 0
        currentInput = "0"
    }
}
