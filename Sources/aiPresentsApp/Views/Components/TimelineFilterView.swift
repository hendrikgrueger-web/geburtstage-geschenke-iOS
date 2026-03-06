import SwiftUI

/// A reusable timeline filter for birthday views with period selection and search
struct TimelineFilterView: View {
    // MARK: - Types
    enum FilterPeriod: String, CaseIterable, Identifiable {
        case all = "Alle"
        case today = "Heute"
        case upcoming7 = "7 Tage"
        case upcoming30 = "30 Tage"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar"
            case .upcoming7: return "calendar.badge.clock"
            case .upcoming30: return "calendar.badge.plus"
            }
        }

        var accessibilityHint: String {
            switch self {
            case .all: return String(localized: "Zeigt alle Geburtstage")
            case .today: return String(localized: "Zeigt nur heutige Geburtstage")
            case .upcoming7: return String(localized: "Zeigt Geburtstage der nächsten 7 Tage")
            case .upcoming30: return String(localized: "Zeigt Geburtstage der nächsten 30 Tage")
            }
        }
    }

    // MARK: - Properties
    @Binding var selectedPeriod: FilterPeriod
    @Binding var searchText: String
    @Binding var showFavoritesOnly: Bool

    let totalCount: Int
    let filteredCount: Int

    @State private var isEditingSearch = false
    @FocusState private var searchFocus: Bool

    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        selectedPeriod != .all || !searchText.isEmpty || showFavoritesOnly
    }

    private var filterSummary: String {
        var parts: [String] = []

        if selectedPeriod != .all {
            parts.append(selectedPeriod.rawValue)
        }

        if !searchText.isEmpty {
            parts.append("'\(searchText)'")
        }

        if showFavoritesOnly {
            parts.append("Favoriten")
        }

        return parts.isEmpty ? "Alle \(totalCount) Geburtstage" : "\(filteredCount) von \(totalCount)"
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Period selector
            periodSelectorView

            Divider()
                .padding(.horizontal)

            // Search and filters
            HStack(spacing: 12) {
                // Search bar
                searchBarView

                // Favorites toggle
                favoritesToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Filter summary (when filters are active)
            if hasActiveFilters {
                filterSummaryView
            }

            Divider()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Subviews

    private var periodSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterPeriod.allCases) { period in
                    Button {
                        HapticFeedback.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: period.icon)
                                .font(.caption)

                            Text(period.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period
                                ? AppColor.primary
                                : Color(.systemBackground)
                        )
                        .foregroundColor(
                            selectedPeriod == period
                                ? .white
                                : .primary
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    selectedPeriod == period
                                        ? AppColor.primary
                                        : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedPeriod == period
                                ? AppColor.primary.opacity(0.3)
                                : .clear,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(period.rawValue)
                    .accessibilityHint(period.accessibilityHint)
                    .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.body)

            if isEditingSearch || !searchText.isEmpty {
                TextField("Suchen...", text: $searchText)
                    .focused($searchFocus)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        searchFocus = false
                    }
                    .onChange(of: searchText) { _, _ in
                        // Debounced search could be added here
                    }
            } else {
                Text("Suchen...")
                    .foregroundColor(.secondary)
            }

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            isEditingSearch = true
            searchFocus = true
        }
    }

    private var favoritesToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFavoritesOnly.toggle()
            }
            HapticFeedback.light()
        } label: {
            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                .font(.title3)
                .foregroundColor(showFavoritesOnly ? .yellow : .secondary)
                .frame(width: 44, height: 44)
                .background(showFavoritesOnly ? Color.yellow.opacity(0.15) : Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(showFavoritesOnly ? .yellow : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .accessibilityLabel(showFavoritesOnly ? "Nur Favoriten" : "Alle anzeigen")
        .accessibilityHint(showFavoritesOnly ? "Doppeltippen um alle anzuzeigen" : "Doppeltippen um nur Favoriten anzuzeigen")
    }

    private var filterSummaryView: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(filterSummary)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("Alle Filter zurücksetzen") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedPeriod = .all
                    searchText = ""
                    showFavoritesOnly = false
                }
                HapticFeedback.light()
            }
            .font(.caption)
            .foregroundColor(AppColor.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview

#Preview("Timeline Filter") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: TimelineFilterView.FilterPeriod = .all
        @State private var searchText: String = ""
        @State private var showFavoritesOnly: Bool = false

        var body: some View {
            VStack(spacing: 20) {
                TimelineFilterView(
                    selectedPeriod: $selectedPeriod,
                    searchText: $searchText,
                    showFavoritesOnly: $showFavoritesOnly,
                    totalCount: 24,
                    filteredCount: 24
                )

                Divider()

                Text("Period: \(selectedPeriod.rawValue)")
                Text("Search: '\(searchText)'")
                Text("Favorites: \(showFavoritesOnly ? "Yes" : "No")")
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Active Filters") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: TimelineFilterView.FilterPeriod = .upcoming7
        @State private var searchText: String = "Max"
        @State private var showFavoritesOnly: Bool = true

        var body: some View {
            TimelineFilterView(
                selectedPeriod: $selectedPeriod,
                searchText: $searchText,
                showFavoritesOnly: $showFavoritesOnly,
                totalCount: 24,
                filteredCount: 3
            )
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
