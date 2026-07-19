import Foundation

enum APIConfig {
    /// Production Vercel backend (CLI deploy: backend-deploy project).
    static var baseURL = URL(string: "https://backend-deploy-sepia.vercel.app")!

    /// Override for local backend testing: set `true` and run `npm run dev` in `/backend`.
    static let useLocalhost = false

    static var resolvedBaseURL: URL {
        if useLocalhost {
            return URL(string: "http://127.0.0.1:3000")!
        }
        return baseURL
    }
}
