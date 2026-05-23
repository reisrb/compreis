import AuthenticationServices
import SwiftUI
import UIKit

private final class AuthAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

@MainActor
final class GoogleAuth: ObservableObject {
    static let shared = GoogleAuth()

    @Published var isConnected = false
    @Published var email: String?
    @Published var errorMessage: String?

    @AppStorage("google_client_id") var clientId: String = ""

    private let anchor = AuthAnchor()
    private var activeSession: ASWebAuthenticationSession?

    private init() {
        isConnected = Keychain.read(key: "g_refresh") != nil
        email = UserDefaults.standard.string(forKey: "g_email")
    }

    func signIn() async {
        guard !clientId.isEmpty else {
            errorMessage = "Informe o Client ID antes de conectar."
            return
        }
        errorMessage = nil

        let suffix = clientId.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        let scheme = "com.googleusercontent.apps.\(suffix)"
        let redirectUri = "\(scheme):/oauth2callback"

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id",     value: clientId),
            .init(name: "redirect_uri",  value: redirectUri),
            .init(name: "response_type", value: "code"),
            .init(name: "scope",         value: "email profile https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive.file"),
            .init(name: "access_type",   value: "offline"),
            .init(name: "prompt",        value: "consent"),
        ]

        do {
            let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                let session = ASWebAuthenticationSession(
                    url: comps.url!,
                    callbackURLScheme: scheme
                ) { [weak self] url, error in
                    self?.activeSession = nil
                    if let error { continuation.resume(throwing: error); return }
                    guard let url,
                          let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                              .queryItems?.first(where: { $0.name == "code" })?.value else {
                        continuation.resume(throwing: AuthError.noCode); return
                    }
                    continuation.resume(returning: code)
                }
                session.presentationContextProvider = anchor
                session.prefersEphemeralWebBrowserSession = false
                activeSession = session
                session.start()
            }

            try await exchangeCode(code, redirectUri: redirectUri)
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // user cancelled — silent
        } catch {
            errorMessage = "Erro ao conectar: \(error.localizedDescription)"
        }
    }

    func getToken() async throws -> String {
        if let token = Keychain.read(key: "g_access") { return token }
        guard let refresh = Keychain.read(key: "g_refresh") else { throw AuthError.notSignedIn }
        return try await refreshToken(refresh)
    }

    func signOut() {
        Keychain.delete(key: "g_access")
        Keychain.delete(key: "g_refresh")
        UserDefaults.standard.removeObject(forKey: "g_email")
        isConnected = false
        email = nil
    }

    // MARK: - Private

    private func exchangeCode(_ code: String, redirectUri: String) async throws {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = [
            "code=\(code)",
            "client_id=\(clientId)",
            "redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "grant_type=authorization_code"
        ].joined(separator: "&").data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let access = json["access_token"] as? String else {
            throw AuthError.tokenExchange(json["error_description"] as? String ?? "unknown")
        }
        Keychain.save(key: "g_access", value: access)
        if let refresh = json["refresh_token"] as? String {
            Keychain.save(key: "g_refresh", value: refresh)
        }
        decodeEmail(from: json["id_token"] as? String)
        isConnected = true
    }

    private func refreshToken(_ refreshToken: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "refresh_token=\(refreshToken)&client_id=\(clientId)&grant_type=refresh_token"
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let access = json["access_token"] as? String else {
            // Refresh token invalid — sign out
            signOut()
            throw AuthError.notSignedIn
        }
        Keychain.save(key: "g_access", value: access)
        return access
    }

    private func decodeEmail(from idToken: String?) {
        guard let idToken,
              let payload = idToken.split(separator: ".").dropFirst().first else { return }
        var padded = String(payload)
        while padded.count % 4 != 0 { padded += "=" }
        guard let data = Data(base64Encoded: padded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mail = json["email"] as? String else { return }
        UserDefaults.standard.set(mail, forKey: "g_email")
        email = mail
    }

    enum AuthError: Error, LocalizedError {
        case noCode, notSignedIn, tokenExchange(String)
        var errorDescription: String? {
            switch self {
            case .noCode: "Código OAuth não recebido."
            case .notSignedIn: "Usuário não conectado."
            case .tokenExchange(let msg): "Falha na troca de token: \(msg)"
            }
        }
    }
}
