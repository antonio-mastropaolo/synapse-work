import SwiftUI
import DesignSystem

/// Cmd-K command palette. Cross-platform: invoked on macOS via the
/// "Open Quick Switcher" menu shortcut and on iOS via the sidebar
/// footer's magnifying-glass button. The match logic is a pure,
/// testable function (`CommandPaletteMatcher.matches`) so we can
/// unit-test it without spinning up SwiftUI.
public struct CommandPalette: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @FocusState private var fieldFocused: Bool

    private let onSelect: @MainActor (WorkSurface) -> Void

    public init(onSelect: @escaping @MainActor (WorkSurface) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                TextField("Jump to surface…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($fieldFocused)
                    .onSubmit(submitFirst)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textFaint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.surface1)
            .overlay(
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 0.5),
                alignment: .bottom
            )

            // Results
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filtered, id: \.self) { surface in
                        Button {
                            onSelect(surface)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: surface.systemImage)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 24, alignment: .center)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(surface.label)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(surface.group.rawValue)
                                        .workUppercaseLabel(9, color: Theme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "return")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Theme.textFaint)
                                    .opacity(0.0)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Theme.background)
                        Divider().background(Theme.border)
                    }

                    if filtered.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(Theme.textFaint)
                            Text("No surface matches “\(query)”")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
            }
            .background(Theme.background)
        }
        .frame(minWidth: 480, idealWidth: 560, minHeight: 360, idealHeight: 440)
        .background(Theme.background)
        .onAppear { fieldFocused = true }
        .preferredColorScheme(.dark)
    }

    private var filtered: [WorkSurface] {
        CommandPaletteMatcher.matches(query: query, surfaces: WorkSurface.allCases)
    }

    @MainActor
    private func submitFirst() {
        guard let first = filtered.first else { return }
        onSelect(first)
        dismiss()
    }
}

/// Pure matching logic for the palette. Lives outside the View so it
/// can be unit-tested without SwiftUI in the loop. Behavior:
/// 1. Empty query → return everything in declared order.
/// 2. Otherwise, score every surface against the query and return
///    those with a non-nil score, sorted by score (lower is better).
public enum CommandPaletteMatcher {

    public static func matches(query: String, surfaces: [WorkSurface]) -> [WorkSurface] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return surfaces }

        let scored: [(surface: WorkSurface, score: Int)] = surfaces.compactMap { surface in
            guard let score = score(surface: surface, needle: needle) else { return nil }
            return (surface, score)
        }
        return scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score < rhs.score }
                return lhs.surface.label < rhs.surface.label
            }
            .map(\.surface)
    }

    /// Scoring rubric (lower = better match):
    /// - 0:  label starts with needle
    /// - 5:  any word in the label starts with needle
    /// - 10: label contains needle as substring
    /// - 20: rawValue or group label contains needle
    /// - 40: subsequence match (fuzzy)
    static func score(surface: WorkSurface, needle: String) -> Int? {
        let label = surface.label.lowercased()
        let raw = surface.rawValue.lowercased()
        let group = surface.group.rawValue.lowercased()

        if label.hasPrefix(needle) { return 0 }

        let words = label.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        if words.contains(where: { $0.lowercased().hasPrefix(needle) }) { return 5 }

        if label.contains(needle) { return 10 }
        if raw.contains(needle) || group.contains(needle) { return 20 }

        if isSubsequence(needle: needle, in: label) { return 40 }
        return nil
    }

    /// "csm" matches "Cost AI" via subsequence? No — but "ash" matches
    /// "Ask AI". We treat the needle as an ordered set of characters
    /// that must appear in the haystack in order, not necessarily
    /// contiguously. Cheap and adequate for ~20 surfaces.
    static func isSubsequence(needle: String, in haystack: String) -> Bool {
        var hayIdx = haystack.startIndex
        for ch in needle {
            guard let found = haystack[hayIdx...].firstIndex(of: ch) else { return false }
            hayIdx = haystack.index(after: found)
            if hayIdx > haystack.endIndex { return false }
        }
        return true
    }
}
