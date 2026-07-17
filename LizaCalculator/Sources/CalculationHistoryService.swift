import Foundation

/// Собирает историю вычислений «как в Калькуляторе iOS 18».
///
/// Логика намеренно вынесена сюда: `CalculatorEngine`/`CalculatorService` почти не
/// трогаем. Сервис слушает те же события, что уже проходят через экшн-методы
/// `MainViewController` (единая воронка пользовательского ввода), и на каждом `=`
/// фиксирует запись «выражение = результат».
final class CalculationHistoryService {
    static let shared = CalculationHistoryService()

    private let defaults: UserDefaults
    private let storageKey = "calc.history.v1"

    private(set) var entries: [HistoryEntry] = []

    // MARK: - Состояние сборщика выражения

    /// Токены выражения: [операнд, оператор, операнд, оператор, …]
    private var parts: [String] = []
    private var enteredDigitSinceLastOp = false
    private var lastWasEquals = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromStore()
    }

    // MARK: - События ввода (вызываются из VC)

    /// Ввод цифры / точки / `%` / `+/-` — начали (или продолжили) операнд.
    func noteOperandInput() {
        if lastWasEquals {
            parts = []
            lastWasEquals = false
        }
        enteredDigitSinceLastOp = true
    }

    /// Нажат оператор. `currentDisplay` — сырой операнд ДО обработки движком.
    func noteOperator(_ symbol: String, currentDisplay: String) {
        let operand = currentDisplay.format()

        if lastWasEquals {
            // Результат предыдущего вычисления становится первым операндом.
            parts = [operand, symbol]
            lastWasEquals = false
            enteredDigitSinceLastOp = false
            return
        }

        if !enteredDigitSinceLastOp, !parts.isEmpty {
            // Два оператора подряд без цифры — заменяем последний.
            parts[parts.count - 1] = symbol
            return
        }

        parts.append(operand)
        parts.append(symbol)
        enteredDigitSinceLastOp = false
    }

    /// Нажат `=`. `lastOperandDisplay` — сырой последний операнд ДО вычисления.
    func commit(lastOperandDisplay: String, result: String) {
        // Нет оператора в выражении (голое число или повторный `=`) — не пишем.
        guard !parts.isEmpty else {
            lastWasEquals = true
            return
        }

        let expression = (parts + [lastOperandDisplay.format()])
            .joined(separator: " ")
        let entry = HistoryEntry(expression: expression, result: result)
        entries.insert(entry, at: 0)
        saveToStore()

        parts = []
        enteredDigitSinceLastOp = false
        lastWasEquals = true
    }

    /// AC / C — сброс текущего собираемого выражения (историю не трогает).
    func reset() {
        parts = []
        enteredDigitSinceLastOp = false
        lastWasEquals = false
    }

    // MARK: - Управление историей

    func delete(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveToStore()
    }

    func clearAll() {
        entries.removeAll()
        saveToStore()
    }

    // MARK: - Группировка по датам

    struct Section {
        let title: String
        let items: [HistoryEntry]
    }

    func groupedByDate(now: Date = Date()) -> [Section] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)

        var today: [HistoryEntry] = []
        var last7: [HistoryEntry] = []
        var last30: [HistoryEntry] = []
        var earlier: [HistoryEntry] = []

        for entry in entries {
            let days = calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: entry.date), to: startOfToday
            ).day ?? 0

            if days <= 0 {
                today.append(entry)
            } else if days <= 7 {
                last7.append(entry)
            } else if days <= 30 {
                last30.append(entry)
            } else {
                earlier.append(entry)
            }
        }

        return [
            Section(title: "Сегодня", items: today),
            Section(title: "Последние 7 дней", items: last7),
            Section(title: "Последние 30 дней", items: last30),
            Section(title: "Ранее", items: earlier),
        ].filter { !$0.items.isEmpty }
    }

    // MARK: - Персистентность

    private func loadFromStore() {
        guard
            let data = defaults.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else {
            return
        }
        entries = decoded
    }

    private func saveToStore() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
