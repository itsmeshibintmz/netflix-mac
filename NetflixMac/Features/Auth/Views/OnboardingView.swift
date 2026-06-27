// MARK: - OnboardingView.swift
// Netflix-style animated onboarding + sign-in screen.

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignIn: Bool = false
    @State private var gradientAngle: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // MARK: Animated Gradient Background
            animatedBackground

            // MARK: Content
            VStack(spacing: 0) {
                if !showSignIn {
                    heroContent
                } else {
                    signInForm
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                gradientAngle = 360
            }
        }
    }

    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            Color.netflixBlack.ignoresSafeArea()

            // Animated blobs
            Circle()
                .fill(Color.netflixRed.opacity(0.25))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: -200, y: -150)
                .rotationEffect(.degrees(gradientAngle * 0.1))

            Circle()
                .fill(Color(red: 0.6, green: 0.0, blue: 0.2).opacity(0.2))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: 200, y: 200)
                .rotationEffect(.degrees(-gradientAngle * 0.05))

            // Glass overlay
            Color.black.opacity(0.35).ignoresSafeArea()
        }
    }

    // MARK: - Hero / Landing Content
    private var heroContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Netflix "N" Logo
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.netflixRed)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.netflixRed.opacity(0.5), radius: 24, y: 8)
                Text("N")
                    .font(.system(size: 52, weight: .black, design: .default))
                    .foregroundStyle(.white)
                    .italic()
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            // Title
            VStack(spacing: 12) {
                Text("Netflix for macOS")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 8)

                Text("Stream everything. Right on your Mac.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .opacity(logoOpacity)

            // Feature Pills
            HStack(spacing: 12) {
                FeaturePill(icon: "tv.fill",             label: "4K Content")
                FeaturePill(icon: "pip.fill",            label: "Picture in Picture")
                FeaturePill(icon: "arrow.down.circle",   label: "Downloads")
            }
            .opacity(logoOpacity)

            // CTA Buttons
            VStack(spacing: 12) {
                NetflixPrimaryButton("Get Started") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSignIn = true
                    }
                }
                .frame(width: 280)

                Button("Sign In") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSignIn = true
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .buttonStyle(.plain)
            }
            .opacity(logoOpacity)

            Spacer()

            // Footer
            Text("This is a personal-use app. Content powered by TMDB.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sign-In Form
    private var signInForm: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Logo small
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.netflixRed)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("N").font(.system(size: 22, weight: .black)).foregroundStyle(.white).italic()
                        )
                    Text("Netflix")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }

                // Form card
                VStack(spacing: 20) {
                    Text("Sign In")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)

                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email or phone").font(.caption).foregroundStyle(Color.netflixLightGray)
                        TextField("", text: $email)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding(12)
                            .liquidGlass(cornerRadius: 10)
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password").font(.caption).foregroundStyle(Color.netflixLightGray)
                        SecureField("", text: $password)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding(12)
                            .liquidGlass(cornerRadius: 10)
                    }

                    // Error
                    if let err = authVM.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Color.netflixRed)
                            .multilineTextAlignment(.center)
                    }

                    // Sign In Button
                    if authVM.isLoading {
                        ProgressView().tint(Color.netflixRed)
                    } else {
                        NetflixPrimaryButton("Sign In") {
                            authVM.signIn(email: email, password: password)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Back
                    Button("← Back") {
                        withAnimation { showSignIn = false }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.netflixLightGray)
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.08)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
                }
                .frame(maxWidth: 420)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}

// MARK: - Feature Pill
struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .medium))
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: 20)
    }
}
