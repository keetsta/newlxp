import Foundation
import Apollo
import ApolloAPI

// MARK: - Token storage

enum TokenStore {
    private static let accessKey = "lxp.accessToken"
    private static let refreshKey = "lxp.refreshToken"
    private static let userIdKey = "lxp.userId"
    private static let studentIdKey = "lxp.studentId"

    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessKey) }
    }

    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshKey) }
    }

    static var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    static var studentId: String? {
        get { UserDefaults.standard.string(forKey: studentIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: studentIdKey) }
    }

    static func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        studentId = nil
    }
}

// MARK: - Auth interceptor

private struct AuthHeadersInterceptor: GraphQLInterceptor {
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        var mutable = request
        mutable.addHeader(name: "apollo-require-preflight", value: "true")
        if let token = TokenStore.accessToken, !token.isEmpty {
            mutable.addHeader(name: "Authorization", value: "Bearer \(token)")
        }
        return await next(mutable)
    }
}

private struct CustomInterceptorProvider: InterceptorProvider {
    func graphQLInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any GraphQLInterceptor] {
        return [
            AuthHeadersInterceptor(),
            MaxRetryInterceptor(),
            AutomaticPersistedQueryInterceptor()
        ]
    }
}

// MARK: - Apollo client

enum LXP {
    static let endpoint = URL(string: "https://api.newlxp.ru/graphql")!

    static let apollo: ApolloClient = {
        let store = ApolloStore()
        let provider = CustomInterceptorProvider()
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: provider,
            store: store,
            endpointURL: endpoint
        )
        return ApolloClient(networkTransport: transport, store: store)
    }()
}

// MARK: - Errors

enum LXPError: LocalizedError {
    case server(String)
    case decoding
    case notAuthenticated
    case unknown

    var errorDescription: String? {
        switch self {
        case .server(let m): m
        case .decoding: "Не удалось разобрать ответ сервера"
        case .notAuthenticated: "Требуется вход"
        case .unknown: "Неизвестная ошибка"
        }
    }
}

extension ApolloClient {
    func fetchData<Q: GraphQLQuery>(_ query: Q) async throws -> Q.Data
    where Q.ResponseFormat == SingleResponseFormat {
        do {
            let response: GraphQLResponse<Q> = try await self.fetch(
                query: query,
                cachePolicy: .networkOnly
            )
            if let errors = response.errors, !errors.isEmpty {
                let msg = errors.compactMap { $0.message }.joined(separator: "; ")
                throw LXPError.server(msg.isEmpty ? "GraphQL error" : msg)
            }
            guard let data = response.data else { throw LXPError.decoding }
            return data
        } catch let urlError as URLError {
            print("[LXP] URLError code=\(urlError.code.rawValue) desc=\(urlError.localizedDescription) host=\(urlError.failingURL?.host ?? "?")")
            throw LXPError.server("\(urlError.localizedDescription) (code \(urlError.code.rawValue))")
        } catch let error as LXPError {
            print("[LXP] LXPError: \(error.localizedDescription)")
            throw error
        } catch {
            print("[LXP] Other error: \(error)")
            throw error
        }
    }
}
