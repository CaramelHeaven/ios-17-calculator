import Foundation

/// Централизованное форматирование чисел калькулятора «как у Apple».
///
/// - `typing` — для ввода/операндов: показывает ровно то, что набрал пользователь
///   (хвостовая точка, нули дроби), группирует только целую часть. Ввод ограничен
///   `maxDigits` цифрами, поэтому строка не переполняется.
/// - `result` — для результатов: округляет до `maxDigits` значащих, группирует, а если
///   число не влезает в бюджет символов — уходит в научную нотацию.
enum NumberDisplay {
    static let maxDigits = 9
    static let scientificDigits = 7
    static let budgetChars = 12

    private static let groupingSeparator = " "

    // MARK: - Ввод

    static func typing(_ raw: String) -> String {
        if raw == "Error" { return "Error" }
        if raw == "-0" { return "-0" }

        let negative = raw.hasPrefix("-")
        let body = negative ? String(raw.dropFirst()) : raw

        let dotIndex = body.firstIndex(of: ".")
        let intPart = dotIndex.map { String(body[body.startIndex..<$0]) } ?? body
        let fracPart = dotIndex.map { String(body[body.index(after: $0)...]) }

        var out = groupInteger(intPart)
        if let fracPart {
            out += "." + fracPart
        }
        return negative ? "-" + out : out
    }

    // MARK: - Результат

    static func result(_ raw: String) -> String {
        if raw == "Error" { return "Error" }
        guard let value = Decimal(string: raw), value != 0 else {
            return raw == "Error" ? "Error" : "0"
        }

        let fixed = fixedSignificant(value)
        if fixed.count <= budgetChars {
            return fixed
        }
        return scientific(value)
    }

    // MARK: - Private

    private static func groupInteger(_ intPart: String) -> String {
        guard let number = Decimal(string: intPart.isEmpty ? "0" : intPart) else {
            return intPart
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = groupingSeparator
        formatter.maximumFractionDigits = 0
        return formatter.string(from: number as NSNumber) ?? intPart
    }

    private static func fixedSignificant(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = groupingSeparator
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 1
        formatter.maximumSignificantDigits = maxDigits
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }

    private static func scientific(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 1
        formatter.maximumSignificantDigits = scientificDigits
        formatter.exponentSymbol = "e"
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }
}
