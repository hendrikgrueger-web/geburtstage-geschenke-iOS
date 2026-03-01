import SwiftUI

struct ContactsImportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRequestingPermission = false
    @State private var hasPermission = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                // Title
                Text("Kontakte importieren")
                    .font(.title2)
                    .fontWeight(.bold)

                // Description
                Text("Importiere Kontakte mit Geburtstagen aus deinem Adressbuch. Wir speichern nur die minimalen Informationen.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Permission Status
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: hasPermission ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(hasPermission ? .green : .gray)

                        Text("Zugriff auf Kontakte")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Nur Geburtstage & Namen")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Text("Lokal gespeichert")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Spacer()

                // Action Button
                Button(action: requestPermission) {
                    if isRequestingPermission {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(hasPermission ? "Fertig" : "Zugriff gewähren")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasPermission ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isRequestingPermission || hasPermission)
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func requestPermission() {
        isRequestingPermission = true

        // TODO: Implement actual Contacts permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRequestingPermission = false
            hasPermission = true
        }
    }
}
