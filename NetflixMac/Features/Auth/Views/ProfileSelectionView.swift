// MARK: - ProfileSelectionView.swift
// Netflix-style profile picker with animated avatar grid.

import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddProfile = false
    @State private var selectedForAnimation: UUID? = nil

    var body: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            VStack(spacing: 48) {
                // Header
                VStack(spacing: 8) {
                    Text("Who's watching?")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)
                    Text("Select your profile to continue.")
                        .font(.system(size: 16))
                        .foregroundStyle(.netflixLightGray)
                }
                .padding(.top, 60)

                // Profile Grid
                HStack(spacing: 20) {
                    ForEach(authVM.profiles) { profile in
                        ProfileAvatarView(
                            profile: profile,
                            isAnimating: selectedForAnimation == profile.id
                        ) {
                            selectedForAnimation = profile.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                authVM.selectProfile(profile)
                            }
                        }
                    }

                    // Add Profile Button (up to 5)
                    if authVM.profiles.count < 5 {
                        AddProfileButton { showAddProfile = true }
                    }
                }

                // Sign Out
                Button("Sign out") { authVM.signOut() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.netflixLightGray)
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                Spacer()
            }
        }
        .sheet(isPresented: $showAddProfile) {
            AddProfileSheet { name, icon, color, isKids in
                authVM.addProfile(name: name, avatarIcon: icon, colorName: color, isKids: isKids)
                showAddProfile = false
            }
        }
    }
}

// MARK: - Profile Avatar
struct ProfileAvatarView: View {
    let profile: UserProfile
    var isAnimating: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(profile.avatarColor.opacity(0.25))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isHovered || isAnimating ? profile.avatarColor : Color.clear,
                                    lineWidth: 3
                                )
                        )

                    Image(systemName: profile.avatarIcon)
                        .font(.system(size: 46))
                        .foregroundStyle(profile.avatarColor)
                }
                .shadow(color: profile.avatarColor.opacity(isHovered ? 0.4 : 0), radius: 16)
                .scaleEffect(isHovered ? 1.08 : isAnimating ? 0.92 : 1.0)

                Text(profile.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                if profile.isKidsProfile {
                    Text("KIDS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.netflixLightGray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.netflixMidGray))
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovered = h }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isAnimating)
    }
}

// MARK: - Add Profile Button
struct AddProfileButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.netflixDarkGray)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.netflixLightGray)
                    )
                    .overlay(
                        Circle().strokeBorder(
                            isHovered ? Color.white.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                    )
                    .scaleEffect(isHovered ? 1.06 : 1.0)

                Text("Add Profile")
                    .font(.system(size: 15))
                    .foregroundStyle(.netflixLightGray)
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovered = h }
        }
    }
}

// MARK: - Add Profile Sheet
struct AddProfileSheet: View {
    let onAdd: (String, String, String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedIcon: String = "person.circle.fill"
    @State private var selectedColor: String = "red"
    @State private var isKids: Bool = false

    private let icons = [
        "person.circle.fill", "star.circle.fill", "heart.circle.fill",
        "bolt.circle.fill", "moon.circle.fill", "sun.max.circle.fill",
        "figure.child.circle.fill", "cat.circle.fill"
    ]
    private let colors = ["red", "blue", "green", "purple", "yellow", "orange"]

    var body: some View {
        VStack(spacing: 24) {
            Text("Create Profile")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // Name
            TextField("Profile name…", text: $name)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .liquidGlass(cornerRadius: 10)

            // Icon picker
            Text("Choose Avatar").font(.subheadline).foregroundStyle(.netflixLightGray)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundStyle(selectedIcon == icon ? .netflixRed : .netflixLightGray)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle().fill(selectedIcon == icon ? Color.netflixRed.opacity(0.15) : Color.netflixDarkGray)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Color picker
            Text("Color").font(.subheadline).foregroundStyle(.netflixLightGray)
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button { selectedColor = color } label: {
                        Circle()
                            .fill(colorFor(color))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().strokeBorder(.white, lineWidth: selectedColor == color ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Kids toggle
            Toggle("Kids Profile", isOn: $isKids)
                .tint(Color.netflixRed)
                .foregroundStyle(.white)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.netflixLightGray)
                    .buttonStyle(.plain)

                Spacer()

                NetflixPrimaryButton("Create") {
                    guard !name.isEmpty else { return }
                    onAdd(name, selectedIcon, selectedColor, isKids)
                }
            }
        }
        .padding(32)
        .frame(width: 380)
        .floatingGlass()
        .background(Color.netflixDarkBG)
        .preferredColorScheme(.dark)
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "red":    return .netflixRed
        case "blue":   return Color(red: 0.2, green: 0.5, blue: 1.0)
        case "green":  return Color(red: 0.1, green: 0.8, blue: 0.4)
        case "purple": return Color(red: 0.6, green: 0.2, blue: 0.9)
        case "yellow": return Color(red: 1.0, green: 0.75, blue: 0.0)
        case "orange": return Color(red: 1.0, green: 0.5, blue: 0.1)
        default: return .netflixRed
        }
    }
}
