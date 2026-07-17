import Foundation
import XCTest
@testable import LizaCalculator

final class CalculationHistoryServiceTests: XCTestCase {
    private let suiteName = "test.calc.history"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeService() -> CalculationHistoryService {
        CalculationHistoryService(defaults: defaults)
    }

    func test_simpleExpression_recordsExpressionAndResult() {
        let service = makeService()

        service.noteOperandInput() // 1
        service.noteOperandInput() // 2
        service.noteOperandInput() // 3
        service.noteOperator("+", currentDisplay: "123")
        service.noteOperandInput() // 7
        service.commit(lastOperandDisplay: "7", result: "130")

        XCTAssertEqual(service.entries.count, 1)
        XCTAssertEqual(service.entries.first?.expression, "123 + 7")
        XCTAssertEqual(service.entries.first?.result, "130")
    }

    func test_continuationAfterEquals_usesResultAsFirstOperand() {
        let service = makeService()

        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "123")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "7", result: "130")

        // Продолжаем от результата: 130 + 2 =
        service.noteOperator("+", currentDisplay: "130")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "2", result: "132")

        XCTAssertEqual(service.entries.count, 2)
        XCTAssertEqual(service.entries.first?.expression, "130 + 2")
        XCTAssertEqual(service.entries.first?.result, "132")
    }

    func test_operatorReplacement_keepsOnlyLastOperator() {
        let service = makeService()

        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "5")
        service.noteOperator("×", currentDisplay: "5")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "3", result: "15")

        XCTAssertEqual(service.entries.first?.expression, "5 × 3")
    }

    func test_chainedExpression_keepsAllTypedOperands() {
        let service = makeService()

        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "5")
        service.noteOperandInput()
        service.noteOperator("×", currentDisplay: "3")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "2", result: "16")

        XCTAssertEqual(service.entries.first?.expression, "5 + 3 × 2")
        XCTAssertEqual(service.entries.first?.result, "16")
    }

    func test_bareNumberEquals_doesNotRecord() {
        let service = makeService()

        service.noteOperandInput()
        service.commit(lastOperandDisplay: "5", result: "5")

        XCTAssertTrue(service.entries.isEmpty)
    }

    func test_reset_dropsPendingExpression() {
        let service = makeService()

        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "5")
        service.reset()
        service.commit(lastOperandDisplay: "0", result: "0")

        XCTAssertTrue(service.entries.isEmpty)
    }

    func test_expression_groupsThousands() {
        let service = makeService()

        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "1234")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "7", result: "1241")

        XCTAssertEqual(service.entries.first?.expression, "1 234 + 7")
    }

    func test_delete_removesEntry() {
        let service = makeService()
        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "1")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "1", result: "2")

        let entry = service.entries[0]
        service.delete(entry)

        XCTAssertTrue(service.entries.isEmpty)
    }

    func test_persistence_survivesNewInstance() {
        let first = makeService()
        first.noteOperandInput()
        first.noteOperator("+", currentDisplay: "1")
        first.noteOperandInput()
        first.commit(lastOperandDisplay: "1", result: "2")

        let second = CalculationHistoryService(defaults: defaults)

        XCTAssertEqual(second.entries.count, 1)
        XCTAssertEqual(second.entries.first?.expression, "1 + 1")
    }

    func test_committedEntry_landsInTodaySection() {
        let service = makeService()
        service.noteOperandInput()
        service.noteOperator("+", currentDisplay: "1")
        service.noteOperandInput()
        service.commit(lastOperandDisplay: "1", result: "2")

        let sections = service.groupedByDate()

        XCTAssertEqual(sections.first?.title, "Сегодня")
        XCTAssertEqual(sections.first?.items.count, 1)
    }
}

final class CalculatorEngineLoadTests: XCTestCase {
    func test_load_thenOperator_continuesFromLoadedValue() {
        let engine = CalculatorEngine()

        XCTAssertEqual(engine.load("130"), "130")
        _ = engine.inputOperator("+")
        _ = engine.inputDigit("5")
        XCTAssertEqual(engine.inputEquals(), "135")
    }

    func test_load_thenDigit_startsFreshEntry() {
        let engine = CalculatorEngine()

        XCTAssertEqual(engine.load("130"), "130")
        XCTAssertEqual(engine.inputDigit("5"), "5")
    }
}
