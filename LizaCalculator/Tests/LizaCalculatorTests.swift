import Foundation
import XCTest
@testable import LizaCalculator

final class LizaCalculatorTests: XCTestCase {
    func test_percentRepeatEquals_usesResolvedPercentOperand() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["1", "0", "0", "0", "-", "5", "%", "="], on: engine), "950")
        XCTAssertEqual(tap(["="], on: engine), "900")
    }

    func test_percentRepeatWithNewNumber_reusesPercentTemplate() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["1", "0", "0", "+", "1", "5", "%", "="], on: engine), "115")
        XCTAssertEqual(tap(["1", "5", "0", "="], on: engine), "172.5")
    }

    func test_repeatedEquals_reusesLastBinaryOperation() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["5", "+", "5", "="], on: engine), "10")
        XCTAssertEqual(tap(["="], on: engine), "15")
        XCTAssertEqual(tap(["="], on: engine), "20")
    }

    func test_continuousMode_usesLeftToRightForChainedOperators() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["2", "+", "3", "x", "4", "="], on: engine), "20")
    }

    func test_subtractThenMultiply_showsIntermediateResultOnMultiplyTap() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["1", "0", "0", "-", "5", "x"], on: engine), "95")
        XCTAssertEqual(tap(["2", "="], on: engine), "190")
    }

    func test_operatorReplacement_keepsOnlyLastPendingOperator() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["5", "+", "x", "3", "="], on: engine), "15")
    }

    func test_equalsWithoutSecondOperand_usesCurrentDisplayAsSecondOperand() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["5", "+", "="], on: engine), "10")
        engine.clear()
        XCTAssertEqual(tap(["5", "x", "="], on: engine), "25")
        engine.clear()
        XCTAssertEqual(tap(["5", "-", "="], on: engine), "0")
    }

    func test_multiplicationPercent_usesPercentAsFraction() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["5", "0", "0", "x", "5", "%", "="], on: engine), "25")
    }

    func test_divisionByZero_entersErrorUntilClear() {
        let engine = CalculatorEngine()

        XCTAssertEqual(tap(["5", "/", "0", "="], on: engine), "Error")
        XCTAssertEqual(engine.clear(), "0")
    }
}

private extension LizaCalculatorTests {
    func tap(_ inputs: [String], on engine: CalculatorEngine) -> String {
        var output = engine.currentValue()

        for input in inputs {
            switch input {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                output = engine.inputDigit(input)
            case ".":
                output = engine.inputDot()
            case "+", "-", "x", "/":
                output = engine.inputOperator(input) ?? engine.currentValue()
            case "=":
                output = engine.inputEquals()
            case "%":
                output = engine.inputPercent()
            case "+/-":
                output = engine.toggleSign()
            case "AC", "C":
                output = engine.clear()
            default:
                XCTFail("Unsupported input: \(input)")
            }
        }

        return output
    }
}