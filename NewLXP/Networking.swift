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

    /// Эта ошибка — отмена задачи (выход с экрана), а не сетевая проблема.
    /// Такие ошибки НЕ показываем юзеру через ErrorBanner.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let url = error as? URLError, url.code == .cancelled { return true }
        // LXPError.server со строкой Apollo-а про cancelled
        let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let lower = msg.lowercased()
        return lower.contains("cancelled") || lower.contains("canceled") || lower.contains("отменен")
    }
}

extension ApolloClient {
    func fetchData<Q: GraphQLQuery>(_ query: Q) async throws -> Q.Data
    where Q.ResponseFormat == SingleResponseFormat {
        try await fetchData(query, allowRefresh: true)
    }

    /// Внутренний фетч с поддержкой автообновления токена. При ответе сервера
    /// «Сессия истекла» один раз пробуем `refreshToken`, обновляем
    /// `TokenStore.accessToken` и повторяем запрос. Бесконечной рекурсии нет —
    /// `allowRefresh = false` на повторном вызове.
    private func fetchData<Q: GraphQLQuery>(_ query: Q, allowRefresh: Bool) async throws -> Q.Data
    where Q.ResponseFormat == SingleResponseFormat {
        do {
            let response: GraphQLResponse<Q> = try await self.fetch(
                query: query,
                cachePolicy: .networkOnly
            )
            if let errors = response.errors, !errors.isEmpty {
                let msg = errors.compactMap { $0.message }.joined(separator: "; ")
                if allowRefresh, isExpiredSessionMessage(msg) {
                    if try await refreshAccessToken() {
                        return try await fetchData(query, allowRefresh: false)
                    }
                }
                throw LXPError.server(msg.isEmpty ? "GraphQL error" : msg)
            }
            guard let data = response.data else { throw LXPError.decoding }
            return data
        } catch let urlError as URLError {
            LXPLog.debug("[LXP] URLError code=\(urlError.code.rawValue) desc=\(urlError.localizedDescription) host=\(urlError.failingURL?.host ?? "?")")
            throw LXPError.server("\(urlError.localizedDescription) (code \(urlError.code.rawValue))")
        } catch let error as LXPError {
            LXPLog.debug("[LXP] LXPError: \(error.localizedDescription)")
            throw error
        } catch {
            LXPLog.debug("[LXP] Other error: \(error)")
            throw error
        }
    }

    private func isExpiredSessionMessage(_ msg: String) -> Bool {
        let lower = msg.lowercased()
        return lower.contains("сессия истекла")
            || lower.contains("session expired")
            || lower.contains("unauthorized")
            || lower.contains("token expired")
            || lower.contains("jwt expired")
    }

    // MARK: - Mutations

    func performData<M: GraphQLMutation>(_ mutation: M) async throws -> M.Data
    where M.ResponseFormat == SingleResponseFormat {
        try await performData(mutation, allowRefresh: true)
    }

    private func performData<M: GraphQLMutation>(_ mutation: M, allowRefresh: Bool) async throws -> M.Data
    where M.ResponseFormat == SingleResponseFormat {
        do {
            let response: GraphQLResponse<M> = try await self.perform(mutation: mutation)
            if let errors = response.errors, !errors.isEmpty {
                let msg = errors.compactMap { $0.message }.joined(separator: "; ")
                if allowRefresh, isExpiredSessionMessage(msg) {
                    if try await refreshAccessToken() {
                        return try await performData(mutation, allowRefresh: false)
                    }
                }
                throw LXPError.server(msg.isEmpty ? "GraphQL error" : msg)
            }
            guard let data = response.data else { throw LXPError.decoding }
            return data
        } catch let urlError as URLError {
            LXPLog.debug("[LXP] mutation URLError code=\(urlError.code.rawValue) desc=\(urlError.localizedDescription)")
            throw LXPError.server("\(urlError.localizedDescription) (code \(urlError.code.rawValue))")
        }
    }
}

/// Состояние автообновления — чтобы при параллельных запросах рефреш дёргался один раз.
private actor TokenRefreshCoordinator {
    static let shared = TokenRefreshCoordinator()
    private var inflight: Task<Bool, Error>?

    func refresh() async throws -> Bool {
        if let t = inflight { return try await t.value }
        let task = Task<Bool, Error> {
            defer { Task { await self.clear() } }
            return try await AuthRepository.refresh()
        }
        inflight = task
        return try await task.value
    }

    private func clear() { inflight = nil }
}

private func refreshAccessToken() async throws -> Bool {
    do {
        let ok = try await TokenRefreshCoordinator.shared.refresh()
        LXPLog.debug("[LXP] token refresh \(ok ? "OK" : "skipped")")
        if !ok {
            // refreshToken отсутствует или пуст — токены протухли окончательно.
            await MainActor.run {
                TokenStore.clear()
                AppStore.shared.isAuthenticated = false
            }
        }
        return ok
    } catch {
        LXPLog.debug("[LXP] token refresh FAIL: \(error.localizedDescription)")
        // refreshToken тоже отвергнут сервером — выкидываем юзера на логин.
        await MainActor.run {
            TokenStore.clear()
            AppStore.shared.isAuthenticated = false
        }
        return false
    }
}
