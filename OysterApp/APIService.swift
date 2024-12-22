import Foundation

class APIService {
    static let shared = APIService() // Singleton instance
    
    private init() {} // Prevent instantiation outside
    
    func registerUser(name: String, email: String, password: String, completion: @escaping (UserDTO?) -> Void) {
        let url = URL(string: "http://localhost:8080/api/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = [
            "name": name,
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let user = try JSONDecoder().decode(UserDTO.self, from: data)
                    completion(user)
                } catch {
                    print("Error decoding response: \(error)")
                    completion(nil)
                }
            } else if let error = error {
                print("Network error: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}
