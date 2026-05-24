import SwiftUI

public struct WorkSectionHeader: View {
    private let title: String
    private let count: Int?

    public init(_ title: String, count: Int? = nil) {
        self.title = title
        self.count = count
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text(title).workUppercaseLabel(10, color: Theme.textMuted)
            if let count {
                Text("\(count)")
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Theme.surface1, in: Capsule())
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 12, leading: 18, bottom: 4, trailing: 18))
    }
}
