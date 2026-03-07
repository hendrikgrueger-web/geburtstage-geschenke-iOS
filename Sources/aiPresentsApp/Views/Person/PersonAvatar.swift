import SwiftUI

struct PersonAvatar: View {
    let person: PersonRef
    var size: CGFloat = 60

    nonisolated static func initials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }

    private var contactPhoto: UIImage? {
        ContactPhotoService.shared.photo(for: person.contactIdentifier)
    }

    var body: some View {
        Group {
            if let photo = contactPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppColor.gradientForRelation(person.relation))
                    .frame(width: size, height: size)
                    .overlay {
                        Text(PersonAvatar.initials(from: person.displayName))
                            .font(.system(size: size * 0.4))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Avatar für \(person.displayName)")
        .accessibilityHint("\(person.relation)")
    }
}

struct CompactPersonAvatar: View {
    let person: PersonRef
    var size: CGFloat = 40

    private var contactPhoto: UIImage? {
        ContactPhotoService.shared.photo(for: person.contactIdentifier)
    }

    var body: some View {
        Group {
            if let photo = contactPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(AppColor.gradientForRelation(person.relation))
                    .frame(width: size, height: size)
                    .overlay {
                        Text(PersonAvatar.initials(from: person.displayName))
                            .font(.system(size: size * 0.35))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Avatar für \(person.displayName)")
        .accessibilityHidden(true)
    }
}
