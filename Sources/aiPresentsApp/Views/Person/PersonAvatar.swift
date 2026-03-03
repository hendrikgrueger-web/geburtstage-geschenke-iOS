import SwiftUI

struct PersonAvatar: View {
    let person: PersonRef
    var size: CGFloat = 60

    static func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        Circle()
            .fill(AppColor.gradientForRelation(person.relation))
            .frame(width: size, height: size)
            .overlay {
                Text(String(person.displayName.prefix(1)))
                    .font(.system(size: size * 0.4))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .shadow(color: AppColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Avatar für \(person.displayName)")
            .accessibilityHint("\(person.relation)")
    }
}

struct CompactPersonAvatar: View {
    let person: PersonRef
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(AppColor.gradientForRelation(person.relation))
            .frame(width: size, height: size)
            .overlay {
                Text(String(person.displayName.prefix(1)))
                    .font(.system(size: size * 0.35))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Avatar für \(person.displayName)")
            .accessibilityHidden(true)
    }
}
