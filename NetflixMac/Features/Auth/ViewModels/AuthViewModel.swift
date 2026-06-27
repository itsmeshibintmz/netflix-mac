// MARK: - AuthViewModel.swift
// Local authentication & profile management (personal use, no real Netflix auth).

import Foundation
import SwiftUI

// MARK: - Profile Model
struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var avatarIcon: String      // SF Symbol name
    var colorName: String       // SwiftUI Color name key
    var isKidsProfile: Bool
    var pinHash: String?        // SHA-256 of PIN (simple local protection)

    var avatarColor: Color {
        switch colorName {
        case "red":    return .netflixRed
        case "blue":   return Color(red: 0.2, green: 0.5, blue: 1.0)
        case "green":  return Color(red: 0.1, green: 0.8, blue: 0.4)
        case "purple": return Color(red: 0.6, green: 0.2, blue: 0.9)
        case "yellow": return Color(red: 1.0, green: 0.75, blue: 0.0)
        case "orange": return Color(red: 1.0, green: 0.5, blue: 0.1)
        default:       return .netflixRed
        }
    }

    init(name: String, avatarIcon: String = "person.circle.fill",
         colorName: String = "red", isKidsProfile: Bool = false) {
        self.id = UUID()
        self.name = name
        self.avatarIcon = avatarIcon
        self.colorName = colorName
        self.isKidsProfile = isKidsProfile
    }
}

// MARK: - AuthViewModel
@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isSignedIn: Bool = false
    @Published var selectedProfile: UserProfile? = nil
    @Published var profiles: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let signedInKey  = "netflix_signed_in"
    private let profilesKey  = "netflix_profiles_v2"

    init() { loadState() }

    // MARK: - Auth Actions
    func signIn(email: String, password: String) {
        // Local-only auth for personal use
        guard !email.isEmpty, password.count >= 4 else {
            errorMessage = "Please enter a valid email and password (min. 4 chars)."
            return
        }
        isLoading = true
        errorMessage = nil

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)   // simulate 0.8 s
            isLoading = false
            isSignedIn = true
            UserDefaults.standard.set(true, forKey: signedInKey)
            if profiles.isEmpty { createDefaultProfiles() }
        }
    }

    func signOut() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isSignedIn = false
            selectedProfile = nil
        }
        UserDefaults.standard.set(false, forKey: signedInKey)
    }

    func selectProfile(_ profile: UserProfile) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selectedProfile = profile
        }
    }

    func deselectProfile() {
        withAnimation(.easeInOut) { selectedProfile = nil }
    }

    // MARK: - Profile Management
    func addProfile(name: String, avatarIcon: String, colorName: String, isKids: Bool = false) {
        guard profiles.count < 5 else { return }
        let profile = UserProfile(name: name, avatarIcon: avatarIcon,
                                  colorName: colorName, isKidsProfile: isKids)
        profiles.append(profile)
        saveProfiles()
    }

    func deleteProfile(_ profile: UserProfile) {
        profiles.removeAll { $0.id == profile.id }
        if selectedProfile?.id == profile.id { selectedProfile = nil }
        saveProfiles()
    }

    // MARK: - Defaults
    private func createDefaultProfiles() {
        profiles = [
            UserProfile(name: "Me",    avatarIcon: "person.circle.fill",  colorName: "red"),
            UserProfile(name: "Kids",  avatarIcon: "figure.child.circle.fill",  colorName: "yellow", isKidsProfile: true)
        ]
        saveProfiles()
    }

    // MARK: - Persistence
    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func loadState() {
        isSignedIn = UserDefaults.standard.bool(forKey: signedInKey)
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([UserProfile].self, from: data) {
            profiles = saved
        }
    }
}
