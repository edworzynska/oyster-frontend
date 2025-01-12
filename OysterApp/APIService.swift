import Foundation

class APIService {

    static let shared = APIService()

    private init() {}

    private let baseURL = "http://localhost:8080/api"

    private func getURL(for endpoint: String) -> URL? {
        return URL(string: "\(baseURL)\(endpoint)")
    }
    
    func getStations(completion: @escaping (Result<[Station], Error>) -> Void) {
        guard let url = getURL(for: "/stations/") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred")))
                return
            }

            completion(self.decodeResponse([Station].self, from: data))
        }
        task.resume()
    }
    
    func getCards(completion: @escaping (Result<[CardDTO], Error>) -> Void) {
        guard let url = getURL(for: "/cards/") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred")))
                return
            }

            completion(self.decodeResponse([CardDTO].self, from: data))
        }
        task.resume()
    }

    func selectCard(_ card: CardDTO) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(card) {
            UserDefaults.standard.set(encoded, forKey: "selectedCard")
        }
    }

    func getSelectedCard() -> CardDTO? {
        if let savedCardData = UserDefaults.standard.object(forKey: "selectedCard") as? Data {
            let decoder = JSONDecoder()
            if let loadedCard = try? decoder.decode(CardDTO.self, from: savedCardData) {
                return loadedCard
            }
        }
        return nil
    }
    
    func tapIn(cardNumber: Int64, station: Station, completion: @escaping (Result<TransactionDTO, Error>) -> Void) {
        guard let url = getURL(for: "/transactions/\(cardNumber)/tapIn") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "The URL is invalid.")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(station)
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server.")))
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                    completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
                    return
                }

                completion(self.decodeResponse(TransactionDTO.self, from: data))
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

    private func decodeAPIError(data: Data) -> NSError? {
        let decoder = JSONDecoder()
        do {
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            return NSError(domain: errorResponse.error, code: errorResponse.status, userInfo: [
                NSLocalizedDescriptionKey: errorResponse.message,
                "timestamp": errorResponse.timestamp
            ])
        } catch {
            return nil
        }
    }

    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) -> Result<T, Error> {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(type, from: data)
            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    private func makeError(domain: String, code: Int, message: String) -> NSError {
        return NSError(domain: domain, code: code, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }



    func tapOut(cardNumber: Int64, station: Station, completion: @escaping (Result<TransactionDTO, Error>) -> Void) {
        guard let url = getURL(for: "/transactions/\(cardNumber)/tapOut") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(station)
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                    completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
                    return
                }

                completion(self.decodeResponse(TransactionDTO.self, from: data))
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

    func registerCard(cardNumber: Int64, completion: @escaping (Result<CardDTO, Error>) -> Void) {
        guard let url = getURL(for: "/cards/number/\(cardNumber)") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred")))
                return
            }

            completion(self.decodeResponse(CardDTO.self, from: data))
        }
        task.resume()
    }
    
    func issueNewCard(completion: @escaping (Result<CardDTO, Error>) -> Void) {
        guard let url = getURL(for: "/cards/") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            

            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred")))
                return
            }

            completion(self.decodeResponse(CardDTO.self, from: data))
        }
        task.resume()
    }
    func blockCard(cardNumber: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = getURL(for: "/cards/block/\(cardNumber)") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server.")))
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
            }
            completion(.success(()))
        }
        task.resume()
    }
    
    func topUpCard(cardNumber: Int64, amount: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = getURL(for: "/cards/\(cardNumber)?amount=\(amount)") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server.")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
                return
            }

            completion(.success(()))
        }
        task.resume()
    }

    func registerUser(firstName: String, lastName: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "http://localhost:8080/api/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server.")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
                return
            }

            completion(.success(()))
        }
        task.resume()
    }
    
    func getPaginatedTransactions(
        cardNumber: Int64,
        page: Int,
        size: Int,
        startDate: Date? = nil,
        endDate: Date? = nil,
        completion: @escaping (Result<PaginatedResponse<TransactionDTO>, Error>) -> Void
    ) {
        var urlString = "/transactions/card/\(cardNumber)?page=\(page)&size=\(size)"
        
        if let startDate = startDate {
            let startDateString = formatDate(startDate)
            urlString += "&startDate=\(startDateString)"
        }
        if let endDate = endDate {
            let endDateString = formatDate(endDate)
            urlString += "&endDate=\(endDateString)"
        }
        
        guard let url = getURL(for: urlString) else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
     
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let paginatedResponse = try decoder.decode(PaginatedResponse<TransactionDTO>.self, from: data)
                completion(.success(paginatedResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }


    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" 
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date)
    }
    
    func getTransaction(
        transactionId: Int64,
        completion: @escaping (Result<TransactionDTO, Error>) -> Void
    ) {

        guard let url = getURL(for: "/transactions/\(transactionId)") else {
            completion(.failure(makeError(domain: "Invalid URL", code: 400, message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server")))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let transaction = try decoder.decode(TransactionDTO.self, from: data)
                completion(.success(transaction))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    


    func loginUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "http://localhost:8080/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "email=\(email)&password=\(password)"
        if let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            request.httpBody = encodedBody.data(using: .utf8)
        } else {
            let encodingError = NSError(domain: "URL Encoding Error", code: 1, userInfo: nil)
            completion(.failure(encodingError))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.makeError(domain: "No data", code: 404, message: "No data received from the server.")))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(self.decodeAPIError(data: data) ?? self.makeError(domain: "Unknown error", code: httpResponse.statusCode, message: "An unknown error occurred.")))
                return
            }
            
            UserDefaults.standard.removeObject(forKey: "selectedCard")

            completion(.success(()))
        }
        task.resume()
    }
}
