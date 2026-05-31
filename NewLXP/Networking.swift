import Foundation
import Apollo
import ApolloAPI

// MARK: - Token storage

enum TokenStore {
    private static let accessKey = "lxp.accessToken"
    private static let refreshKey = "lxp.refreshToken"
    private static let userIdKey = "lxp.userId"

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

    static func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
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
        let urlSession = URLSession(configuration: .default)
        let provider = CustomInterceptorProvider()
        let transport = RequestChainNetworkTransport(
            urlSession: urlSession,
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
    }
}
