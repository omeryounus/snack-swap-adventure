import Foundation

enum APIError: LocalizedError {
    case badURL
    case http(Int)
    case decoding
    case network(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid API URL"
        case .http(let code): return "Server error (\(code))"
        case .decoding: return "Could not read server response"
        case .network(let msg): return msg
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func health() async throws -> Bool {
        let data = try await get(path: "/api/health")
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["ok"] as? Bool == true
    }

    func leaderboard(sort: LeaderboardSort = .highScore, limit: Int = 50) async throws -> [LeaderboardEntryDTO] {
        let data = try await get(path: "/api/leaderboard", query: [
            "sort": sort.rawValue,
            "limit": "\(limit)"
        ])
        return try decoder.decode(LeaderboardResponse.self, from: data).entries
    }

    func registerPlayer(id: String, displayName: String, avatarEmoji: String) async throws -> PlayerDTO {
        let body: [String: String] = [
            "playerId": id,
            "displayName": displayName,
            "avatarEmoji": avatarEmoji
        ]
        let data = try await post(path: "/api/players", body: body)
        return try decoder.decode(PlayerResponse.self, from: data).player
    }

    func fetchPlayer(id: String) async throws -> PlayerDTO {
        let data = try await get(path: "/api/players/\(id)")
        return try decoder.decode(PlayerResponse.self, from: data).player
    }

    func updatePlayer(id: String, displayName: String?, avatarEmoji: String?) async throws -> PlayerDTO {
        var body: [String: String] = [:]
        if let displayName { body["displayName"] = displayName }
        if let avatarEmoji { body["avatarEmoji"] = avatarEmoji }
        let data = try await patch(path: "/api/players/\(id)", body: body)
        return try decoder.decode(PlayerResponse.self, from: data).player
    }

    func submitScore(_ request: ScoreSubmitRequest) async throws -> ScoreSubmitResponse {
        let data = try await post(path: "/api/scores", encodable: request)
        return try decoder.decode(ScoreSubmitResponse.self, from: data)
    }

    func globalStats() async throws -> GlobalStatsResponse {
        let data = try await get(path: "/api/stats/global")
        return try decoder.decode(GlobalStatsResponse.self, from: data)
    }

    func playerStats(id: String) async throws -> PlayerStatsResponse {
        let data = try await get(path: "/api/stats/\(id)")
        return try decoder.decode(PlayerStatsResponse.self, from: data)
    }

    // MARK: - HTTP

    private func makeURL(path: String, query: [String: String] = [:]) throws -> URL {
        let base = APIConfig.resolvedBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        guard var components = URLComponents(string: base + cleanPath) else {
            throw APIError.badURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.badURL }
        return url
    }

    private func get(path: String, query: [String: String] = [:]) async throws -> Data {
        let url = try makeURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        return try await send(request)
    }

    private func post(path: String, body: [String: String]) async throws -> Data {
        try await post(path: path, encodable: body)
    }

    private func post<T: Encodable>(path: String, encodable: T) async throws -> Data {
        let url = try makeURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(encodable)
        request.timeoutInterval = 15
        return try await send(request)
    }

    private func patch(path: String, body: [String: String]) async throws -> Data {
        let url = try makeURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        request.timeoutInterval = 15
        return try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.network("No response")
            }
            guard (200...299).contains(http.statusCode) else {
                throw APIError.http(http.statusCode)
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }
}
