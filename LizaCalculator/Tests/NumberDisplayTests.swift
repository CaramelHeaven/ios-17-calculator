import Foundation
import XCTest
@testable import LizaCalculator

final class NumberDisplayTests: XCTestCase {
    // MARK: - typing

    func test_typing_preservesTrailingDot() {
        XCTAssertEqual(NumberDisplay.typing("5."), "5.")
    }

    func test_typing_groupsIntegerPart() {
        XCTAssertEqual(NumberDisplay.typing("1234"), "1 234")
        XCTAssertEqual(NumberDisplay.typing("123456789"), "123 456 789")
    }

    func test_typing_keepsNegativeZero() {
        XCTAssertEqual(NumberDisplay.typing("-0"), "-0")
    }

    func test_typing_keepsFractionLiteral() {
        XCTAssertEqual(NumberDisplay.typing("0.00500"), "0.00500")
        XCTAssertEqual(NumberDisplay.typing("-12.30"), "-12.30")
    }

    // MARK: - result

    func test_result_passesThroughShortNumber() {
        XCTAssertEqual(NumberDisplay.result("130"), "130")
        XCTAssertEqual(NumberDisplay.result("0"), "0")
    }

    func test_result_roundsToSignificantDigits() {
        XCTAssertEqual(NumberDisplay.result("0.66666666666666666666"), "0.666666667")
    }

    func test_result_bigNumberUsesScientific() {
        let out = NumberDisplay.result("1738658088")
        XCTAssertTrue(out.hasPrefix("1.738658"))
        XCTAssertTrue(out.contains("e9"))
    }

    func test_result_tinyNumberUsesScientific() {
        let out = NumberDisplay.result("0.0000000000004")
        XCTAssertTrue(out.contains("e"))
        XCTAssertTrue(out.contains("4"))
        XCTAssertLessThanOrEqual(out.count, NumberDisplay.budgetChars)
    }

    func test_result_error() {
        XCTAssertEqual(NumberDisplay.result("Error"), "Error")
    }
}

final class CalculatorEngineInputLimitTests: XCTestCase {
    func test_inputDigits_cappedAtNineDigits() {
        let engine = CalculatorEngine()

        var output = engine.currentValue()
        for _ in 0..<12 {
            output = engine.inputDigit("1")
        }

        XCTAssertEqual(output, "111111111")
        XCTAssertEqual(output.filter(\.isNumber).count, NumberDisplay.maxDigits)
    }
}
