import Foundation

final class CalculatorEngine {
    private enum State {
        case enteringFirst
        case operatorPending
        case enteringSecond
        case trailingOperatorPending
        case enteringTrailing
        case showingResult
        case error
    }

    private enum Operator: Equatable {
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

        var isHighPrecedence: Bool {
            self == .multiply || self == .divide
        }

        func apply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal? {
            switch self {
            case .add:
                return lhs + rhs
            case .subtract:
                return lhs - rhs
            case .multiply:
                return lhs * rhs
            case .divide:
                guard rhs != 0 else { return nil }
                return lhs / rhs
            }
        }
    }

    private struct PercentTemplate {
        let operation: Operator
        let percent: Decimal

        func resolvedOperand(for base: Decimal) -> Decimal {
            switch operation {
            case .add, .subtract:
                return base * percent / 100
            case .multiply, .divide:
                return percent / 100
            }
        }
    }

    private struct RepeatOperation {
        let operation: Operator
        let operand: Decimal
        let percentTemplate: PercentTemplate?
    }

    // MARK: - State

    private var state: State = .enteringFirst

    private var first: Decimal = 0
    private var second: Decimal?
    private var trailing: Decimal?

    private var currentOperator: Operator?
    private var trailingOperator: Operator?

    private var lastRepeat: RepeatOperation?
    private var secondPercentTemplate: PercentTemplate?
    private var trailingPercentTemplate: PercentTemplate?

    private var currentInput: String = "0"

    // MARK: - Public API

    func inputDigit(_ digit: String) -> String {
        guard state != .error else {
            clearAll()
            return inputDigit(digit)
        }

        switch state {
        case .showingResult:
            startNewFirstEntry()
        case .operatorPending:
            startSecondEntry()
        case .trailingOperatorPending:
            startTrailingEntry()
        case .enteringFirst, .enteringSecond, .enteringTrailing:
            break
        case .error:
            break
        }

        appendDigit(digit)
        updateActiveOperandFromInput()
        clearActivePercentTemplate()
        return currentInput
    }

    func inputDot() -> String {
        guard state != .error else {
            clearAll()
            return inputDot()
        }

        switch state {
        case .showingResult:
            startNewFirstEntry()
        case .operatorPending:
            startSecondEntry()
        case .trailingOperatorPending:
            startTrailingEntry()
        case .enteringFirst, .enteringSecond, .enteringTrailing:
            break
        case .error:
            break
        }

        if !currentInput.contains(".") {
            currentInput += "."
        }
        updateActiveOperandFromInput()
        clearActivePercentTemplate()
        return currentInput
    }

    func inputOperator(_ symbol: String) -> String? {
        guard let op = Operator(symbol: symbol) else { return nil }
        guard state != .error else { return currentInput }

        switch state {
        case .enteringFirst:
            currentOperator = op
            state = .operatorPending
            currentInput = formatted(first)
            return nil

        case .operatorPending:
            currentOperator = op
            return nil

        case .enteringSecond:
            return handleOperatorAfterSecond(op)

        case .trailingOperatorPending:
            return handleOperatorFromTrailingPending(op)

        case .enteringTrailing:
            return handleOperatorAfterTrailing(op)

        case .showingResult:
            currentOperator = op
            second = nil
            trailing = nil
            trailingOperator = nil
            secondPercentTemplate = nil
            trailingPercentTemplate = nil
            state = .operatorPending
            currentInput = formatted(first)
            return nil

        case .error:
            return currentInput
        }
    }

    func inputEquals() -> String {
        guard state != .error else { return currentInput }

        switch state {
        case .enteringFirst:
            guard let lastRepeat else { return formatted(first) }
            return applyRepeatToNewFirst(lastRepeat)

        case .operatorPending:
            guard let currentOperator else { return formatted(first) }
            second = first
            return finishExpression(repeatOperation: RepeatOperation(
                operation: currentOperator,
                operand: first,
                percentTemplate: nil
            ))

        case .enteringSecond:
            guard let currentOperator else { return formatted(first) }
            let operand = second ?? 0
            return finishExpression(repeatOperation: RepeatOperation(
                operation: currentOperator,
                operand: operand,
                percentTemplate: secondPercentTemplate
            ))

        case .trailingOperatorPending:
            guard let trailingOperator else { return formatted(first) }
            let operand = second ?? first
            trailing = operand
            return finishExpression(repeatOperation: RepeatOperation(
                operation: trailingOperator,
                operand: operand,
                percentTemplate: nil
            ))

        case .enteringTrailing:
            guard let trailingOperator else { return formatted(first) }
            let operand = trailing ?? 0
            return finishExpression(repeatOperation: RepeatOperation(
                operation: trailingOperator,
                operand: operand,
                percentTemplate: trailingPercentTemplate
            ))

        case .showingResult:
            guard let lastRepeat else { return formatted(first) }
            return applyRepeatToCurrentResult(lastRepeat)

        case .error:
            return currentInput
        }
    }

    func inputPercent() -> String {
        guard state != .error else { return currentInput }

        switch state {
        case .enteringFirst:
            first /= 100
            currentInput = formatted(first)
            return currentInput

        case .operatorPending:
            startSecondEntry(with: first)
            return inputPercent()

        case .enteringSecond:
            guard let currentOperator else { return currentInput }
            let rawPercent = second ?? 0
            let template = PercentTemplate(operation: currentOperator, percent: rawPercent)
            let resolvedOperand = template.resolvedOperand(for: first)
            second = resolvedOperand
            secondPercentTemplate = template
            currentInput = formatted(resolvedOperand)
            return currentInput

        case .trailingOperatorPending:
            startTrailingEntry(with: second ?? first)
            return inputPercent()

        case .enteringTrailing:
            guard let trailingOperator else { return currentInput }
            let rawPercent = trailing ?? 0
            let template = PercentTemplate(operation: trailingOperator, percent: rawPercent)
            let base = second ?? first
            let resolvedOperand = template.resolvedOperand(for: base)
            trailing = resolvedOperand
            trailingPercentTemplate = template
            currentInput = formatted(resolvedOperand)
            return currentInput

        case .showingResult:
            first /= 100
            currentInput = formatted(first)
            return currentInput

        case .error:
            return currentInput
        }
    }

    func toggleSign() -> String {
        guard state != .error else { return currentInput }

        switch state {
        case .showingResult:
            state = .enteringFirst
        case .operatorPending:
            startSecondEntry()
        case .trailingOperatorPending:
            startTrailingEntry()
        case .enteringFirst, .enteringSecond, .enteringTrailing:
            break
        case .error:
            break
        }

        if currentInput.hasPrefix("-") {
            currentInput.removeFirst()
        } else if currentInput != "0" {
            currentInput = "-" + currentInput
        } else {
            currentInput = "-0"
        }
        updateActiveOperandFromInput()
        clearActivePercentTemplate()
        return currentInput
    }

    func clear() -> String {
        clearAll()
        return currentInput
    }

    func backspace() -> String {
        guard state != .error else {
            clearAll()
            return currentInput
        }

        switch state {
        case .showingResult:
            state = .enteringFirst
        case .operatorPending:
            state = .enteringFirst
        case .trailingOperatorPending:
            state = .enteringSecond
            trailing = nil
            trailingOperator = nil
            trailingPercentTemplate = nil
        case .enteringFirst, .enteringSecond, .enteringTrailing:
            break
        case .error:
            break
        }

        guard currentInput.count > 1 else {
            currentInput = "0"
            updateActiveOperandFromInput()
            clearActivePercentTemplate()
            return currentInput
        }

        currentInput.removeLast()
        if currentInput == "-" {
            currentInput = "0"
        }
        updateActiveOperandFromInput()
        clearActivePercentTemplate()
        return currentInput
    }

    func currentValue() -> String {
        currentInput
    }
}

// MARK: - Private

private extension CalculatorEngine {
    func formatted(_ value: Decimal) -> String {
        guard value != 0 else { return "0" }
        return (value as NSDecimalNumber).stringValue
    }

    func updateActiveOperandFromInput() {
        let value = Decimal(string: currentInput) ?? 0
        switch state {
        case .enteringFirst, .showingResult:
            first = value
        case .enteringSecond, .operatorPending:
            second = value
        case .enteringTrailing, .trailingOperatorPending:
            trailing = value
        case .error:
            break
        }
    }

    func appendDigit(_ digit: String) {
        if currentInput == "0" {
            currentInput = digit
        } else if currentInput == "-0" {
            currentInput = "-" + digit
        } else {
            currentInput += digit
        }
    }

    func startNewFirstEntry() {
        first = 0
        second = nil
        trailing = nil
        currentOperator = nil
        trailingOperator = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        currentInput = "0"
        state = .enteringFirst
    }

    func startSecondEntry(with value: Decimal = 0) {
        second = value
        currentInput = formatted(value)
        state = .enteringSecond
        secondPercentTemplate = nil
    }

    func startTrailingEntry(with value: Decimal = 0) {
        trailing = value
        currentInput = formatted(value)
        state = .enteringTrailing
        trailingPercentTemplate = nil
    }

    private func handleOperatorAfterSecond(_ op: Operator) -> String? {
        guard let currentOperator else { return nil }

        if op.isHighPrecedence, !currentOperator.isHighPrecedence {
            trailingOperator = op
            trailing = nil
            trailingPercentTemplate = nil
            state = .trailingOperatorPending
            currentInput = formatted(second ?? 0)
            return nil
        }

        guard let result = evaluateExpression() else {
            return enterError()
        }

        first = result
        second = nil
        trailing = nil
        trailingOperator = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        self.currentOperator = op
        state = .operatorPending
        currentInput = formatted(result)
        return currentInput
    }

    private func handleOperatorFromTrailingPending(_ op: Operator) -> String? {
        if op.isHighPrecedence {
            trailingOperator = op
            return nil
        }

        trailing = second ?? first
        guard let result = evaluateExpression() else {
            return enterError()
        }

        first = result
        second = nil
        trailing = nil
        trailingOperator = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        currentOperator = op
        state = .operatorPending
        currentInput = formatted(result)
        return currentInput
    }

    private func handleOperatorAfterTrailing(_ op: Operator) -> String? {
        guard let trailingOperator else { return nil }

        if op.isHighPrecedence {
            guard let resolvedSecond = trailingOperator.apply(second ?? 0, trailing ?? 0) else {
                return enterError()
            }

            second = resolvedSecond
            trailing = nil
            trailingPercentTemplate = nil
            self.trailingOperator = op
            state = .trailingOperatorPending
            currentInput = formatted(resolvedSecond)
            return currentInput
        }

        guard let result = evaluateExpression() else {
            return enterError()
        }

        first = result
        second = nil
        trailing = nil
        self.trailingOperator = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        currentOperator = op
        state = .operatorPending
        currentInput = formatted(result)
        return currentInput
    }

    private func finishExpression(repeatOperation: RepeatOperation) -> String {
        guard let result = evaluateExpression() else {
            return enterError()
        }

        first = result
        second = nil
        trailing = nil
        currentOperator = nil
        trailingOperator = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        lastRepeat = repeatOperation
        state = .showingResult
        currentInput = formatted(result)
        return currentInput
    }

    func evaluateExpression() -> Decimal? {
        guard let currentOperator else { return first }
        let secondOperand = second ?? first

        guard let trailingOperator else {
            return currentOperator.apply(first, secondOperand)
        }

        let trailingOperand = trailing ?? secondOperand
        guard let resolvedSecond = trailingOperator.apply(secondOperand, trailingOperand) else {
            return nil
        }

        return currentOperator.apply(first, resolvedSecond)
    }

    private func applyRepeatToCurrentResult(_ repeatOperation: RepeatOperation) -> String {
        guard let result = repeatOperation.operation.apply(first, repeatOperation.operand) else {
            return enterError()
        }

        first = result
        currentInput = formatted(result)
        state = .showingResult
        return currentInput
    }

    private func applyRepeatToNewFirst(_ repeatOperation: RepeatOperation) -> String {
        let operand = repeatOperation.percentTemplate?.resolvedOperand(for: first)
            ?? repeatOperation.operand

        guard let result = repeatOperation.operation.apply(first, operand) else {
            return enterError()
        }

        first = result
        currentInput = formatted(result)
        lastRepeat = RepeatOperation(
            operation: repeatOperation.operation,
            operand: operand,
            percentTemplate: repeatOperation.percentTemplate
        )
        state = .showingResult
        return currentInput
    }

    func clearActivePercentTemplate() {
        switch state {
        case .enteringSecond:
            secondPercentTemplate = nil
        case .enteringTrailing:
            trailingPercentTemplate = nil
        case .enteringFirst, .operatorPending, .trailingOperatorPending, .showingResult, .error:
            break
        }
    }

    func clearAll() {
        state = .enteringFirst
        first = 0
        second = nil
        trailing = nil
        currentOperator = nil
        trailingOperator = nil
        lastRepeat = nil
        secondPercentTemplate = nil
        trailingPercentTemplate = nil
        currentInput = "0"
    }

    func enterError() -> String {
        clearAll()
        state = .error
        currentInput = "Error"
        return currentInput
    }
}
