import Foundation

struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let totalPages: Int
    let totalElements: Int
    let size: Int
    let number: Int 
}
