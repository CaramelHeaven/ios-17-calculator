final class CalculatorService {
    static let shared = CalculatorService()
    private let engine = CalculatorEngine()

    private init() {}

    func didTapNumber(_ value: String) -> String {
        switch value {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            return engine.inputDigit(value)

        case "+", "-", "−", "x", "×", "/", "÷":
            return engine.inputOperator(value) ?? engine.currentValue()

        case "=":
            return engine.inputEquals()

        case "%":
            return engine.inputPercent()

        case "+/-":
            return engine.toggleSign()

        case ".":
            return engine.inputDot()

        case "AC":
            return engine.clearAll()
        case "C":
            return engine.clearEntry()

        default:
            return engine.currentValue()
        }
    }

    func didTapOperator(_ value: String) -> String? {
        engine.inputOperator(value)
    }

    func didTapEquals() -> String {
        engine.inputEquals()
    }

    func didTapPercent() -> String {
        engine.inputPercent()
    }

    func didTapToggleSign() -> String {
        engine.toggleSign()
    }

    func didTapDot() -> String {
        engine.inputDot()
    }

    func didTapClear() -> String {
        engine.shouldShowAllClear ? engine.clearAll() : engine.clearEntry()
    }

    func didSwipe() -> String {
        engine.backspace()
    }

    var shouldShowAllClear: Bool {
        engine.shouldShowAllClear
    }

    func currentValue() -> String {
        engine.currentValue()
    }

    func load(_ raw: String) -> String {
        engine.load(raw)
    }
}
