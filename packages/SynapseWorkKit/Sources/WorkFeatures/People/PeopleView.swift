import SwiftUI
import WorkCore
import WorkUI

public struct PeopleView: View {
    @State private var viewModel: PeopleViewModel

    public init(viewModel: PeopleViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                affiliationBar
                Divider().background(Theme.border)
                list
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText)
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
    }

    private var affiliationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectablePill(label: "All", isSelected: viewModel.affiliationFilter == nil) {
                    viewModel.affiliationFilter = nil
                }
                ForEach([Person.Affiliation.faculty, .phdStudent, .msStudent, .postdoc, .industry, .editor, .programChair], id: \.self) { aff in
                    SelectablePill(
                        label: aff.label,
                        isSelected: viewModel.affiliationFilter == aff
                    ) {
                        viewModel.affiliationFilter = (viewModel.affiliationFilter == aff) ? nil : aff
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.visiblePeople) { person in
                NavigationLink(value: person.id) {
                    PersonRow(person: person)
                }
                .listRowBackground(Theme.surface1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: Person.ID.self) { id in
            if let person = viewModel.people.first(where: { $0.id == id }) {
                PersonDetailView(person: person)
            }
        }
    }
}

struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [Theme.signalGlow, Theme.accent.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initials)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    Text(person.affiliation.label)
                        .workUppercaseLabel(9, color: Theme.textFaint)
                    if let inst = person.institution {
                        Text("· \(inst)")
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(person.connectionCount)")
                        .font(.workMono(11))
                }
                .foregroundStyle(Theme.accent)
                if let last = person.lastInteraction {
                    Text(last.formatted(.relative(presentation: .named)))
                        .font(.workMono(9))
                        .foregroundStyle(Theme.textFaint)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var initials: String {
        let parts = person.name.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? ""
        let last = parts.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
}

struct PersonDetailView: View {
    let person: Person

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Theme.signalGlow, Theme.accent.opacity(0.4)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(initials)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.white)
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(person.affiliation.label)
                                        .workUppercaseLabel(10, color: Theme.textMuted)
                                }
                                Spacer()
                            }
                            if let inst = person.institution {
                                infoRow(icon: "building.2", label: "Institution", value: inst)
                            }
                            if let email = person.email {
                                infoRow(icon: "envelope", label: "Email", value: email)
                            }
                            if let last = person.lastInteraction {
                                infoRow(icon: "clock.arrow.circlepath", label: "Last seen", value: last.formatted(.relative(presentation: .named)))
                            }
                            infoRow(icon: "link", label: "Connections", value: "\(person.connectionCount)")
                        }
                    }

                    if !person.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags").workUppercaseLabel(10, color: Theme.textMuted)
                            FlowLayout(spacing: 6) {
                                ForEach(person.tags, id: \.self) { tag in
                                    StatusPill(label: tag, tint: Theme.cyan)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("Force-directed graph view ships in M4.")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 12)
                }
                .padding(16)
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var initials: String {
        let parts = person.name.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? ""
        let last = parts.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 18)
            Text(label).workUppercaseLabel(9, color: Theme.textFaint).frame(width: 80, alignment: .leading)
            Text(value)
                .font(.workMono(11))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxWidth {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowH + spacing
                rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

#Preview {
    NavigationStack {
        PeopleView(viewModel: PeopleViewModel(repository: PreviewPeopleRepository()))
    }
}
