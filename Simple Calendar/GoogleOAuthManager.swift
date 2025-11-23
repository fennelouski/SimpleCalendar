//
//  GoogleOAuthManager.swift
//  Simple Calendar
//
//  Created by Nathan Fennel on 11/23/25.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine

class GoogleOAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var authenticationError: String?

    // Replace these with your actual Google OAuth credentials
    private let clientID = "YOUR_GOOGLE_CLIENT_ID_HERE"
    private let clientSecret = "YOUR_GOOGLE_CLIENT_SECRET_HERE"
    private let redirectURI = "com.nathanfennel.simplecalendar:/oauth2redirect"

    private let scope = "https://www.googleapis.com/auth/calendar.readonly"
    private let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"

    private var currentSession: ASWebAuthenticationSession?

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "googleAccessToken"
    private let refreshTokenKey = "googleRefreshToken"
    private let tokenExpiryKey = "googleTokenExpiry"

    override init() {
        super.init()
        checkExistingAuthentication()
    }

    private func checkExistingAuthentication() {
        if let accessToken = userDefaults.string(forKey: accessTokenKey),
           let expiryDate = userDefaults.object(forKey: tokenExpiryKey) as? Date,
           expiryDate > Date() {
            isAuthenticated = true
            userEmail = userDefaults.string(forKey: "googleUserEmail")
        }
    }

    func signIn() {
        authenticationError = nil

        let authURL = buildAuthorizationURL()

        currentSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "com.nathanfennel.simplecalendar") { [weak self] callbackURL, error in
            guard let self = self else { return }

            if let error = error {
                self.authenticationError = "Authentication failed: \(error.localizedDescription)"
                return
            }

            guard let callbackURL = callbackURL else {
                self.authenticationError = "No callback URL received"
                return
            }

            self.handleCallback(callbackURL)
        }

        currentSession?.presentationContextProvider = self
        currentSession?.start()
    }

    func signOut() {
        // Clear stored tokens
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        userDefaults.removeObject(forKey: "googleUserEmail")

        isAuthenticated = false
        userEmail = nil
        authenticationError = nil
    }

    private func buildAuthorizationURL() -> URL {
        var components = URLComponents(string: authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url!
    }

    private func handleCallback(_ callbackURL: URL) {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            authenticationError = "Failed to extract authorization code"
            return
        }

        exchangeCodeForTokens(code)
    }

    private func exchangeCodeForTokens(_ code: String) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.authenticationError = "Token exchange failed: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.authenticationError = "Invalid token response"
                }
                return
            }

            if let accessToken = json["access_token"] as? String,
               let expiresIn = json["expires_in"] as? TimeInterval {
                let expiryDate = Date().addingTimeInterval(expiresIn)
                let refreshToken = json["refresh_token"] as? String

                DispatchQueue.main.async {
                    self.storeTokens(accessToken: accessToken, refreshToken: refreshToken, expiryDate: expiryDate)
                    self.isAuthenticated = true
                    self.fetchUserProfile()
                }
            } else if let errorDescription = json["error_description"] as? String {
                DispatchQueue.main.async {
                    self.authenticationError = errorDescription
                }
            }
        }.resume()
    }

    private func storeTokens(accessToken: String, refreshToken: String?, expiryDate: Date) {
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(expiryDate, forKey: tokenExpiryKey)
        if let refreshToken = refreshToken {
            userDefaults.set(refreshToken, forKey: refreshTokenKey)
        }
    }

    private func fetchUserProfile() {
        getValidAccessToken { [weak self] accessToken in
            guard let self = self, let accessToken = accessToken else { return }

            var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let email = json["email"] as? String else {
                    return
                }

                DispatchQueue.main.async {
                    self.userEmail = email
                    self.userDefaults.set(email, forKey: "googleUserEmail")
                }
            }.resume()
        }
    }

    func getValidAccessToken(completion: @escaping (String?) -> Void) {
        guard let accessToken = userDefaults.string(forKey: accessTokenKey),
              let expiryDate = userDefaults.object(forKey: tokenExpiryKey) as? Date else {
            completion(nil)
            return
        }

        if expiryDate > Date() {
            completion(accessToken)
        } else if let refreshToken = userDefaults.string(forKey: refreshTokenKey) {
            refreshAccessToken(refreshToken: refreshToken, completion: completion)
        } else {
            completion(nil)
        }
    }


    private func refreshAccessToken(refreshToken: String, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newAccessToken = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? TimeInterval else {
                completion(nil)
                return
            }

            let expiryDate = Date().addingTimeInterval(expiresIn)
            self.storeTokens(accessToken: newAccessToken, refreshToken: refreshToken, expiryDate: expiryDate)

            completion(newAccessToken)
        }.resume()
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
