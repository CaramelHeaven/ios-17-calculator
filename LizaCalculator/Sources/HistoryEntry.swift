import Foundation

struct HistoryEntry: Codable, Equatable {
    let id: UUID
    let expression: String
    let result: String
    let date: Date

    init(id: UUID = UUID(), expression: String, result: String, date: Date = Date()) {
        self.id = id
        self.expression = expression
        self.result = result
        self.date = date
    }
}
