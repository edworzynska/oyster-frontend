import Foundation

struct Station: Codable {
    let id: Int
    let name: String
    let zone: Int
}

struct TransactionDTO: Codable {
    let id: Int64
    let cardId: Int64
    let cardNumber: Int64
    let transactionType: String
    let startStation: Station?
    let endStation: Station?
    let fare: Double?
    let topUpAmount: Double?
    let startAt: String
    let endAt: String?
    
    var startAtDate: Date? {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            return dateFormatter.date(from: startAt)
        }
}
