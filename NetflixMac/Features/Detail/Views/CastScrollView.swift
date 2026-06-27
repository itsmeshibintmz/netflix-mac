// MARK: - CastScrollView.swift
// Horizontal cast & crew carousel.

import SwiftUI

struct CastScrollView: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cast")
                .font(.title3.bold())
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(cast) { member in
                        CastCard(member: member)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Cast Card
struct CastCard: View {
    let member: CastMember
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.netflixDarkGray)
                    .frame(width: 72, height: 72)

                if let url = member.profileURL {
                    AsyncPosterImage(url: url, cornerRadius: 36, contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.netflixLightGray)
                }
            }
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .scaleEffect(isHovered ? 1.08 : 1.0)

            // Name
            Text(member.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 80)

            // Character
            if let char = member.character, !char.isEmpty {
                Text(char)
                    .font(.system(size: 11))
                    .foregroundStyle(.netflixLightGray)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .frame(width: 80)
        .onHover { h in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovered = h }
        }
    }
}
