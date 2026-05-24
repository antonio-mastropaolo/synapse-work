import SwiftUI
import Models
import DesignSystem
public struct AskView: View {
    @State private var viewModel: AskViewModel
    @FocusState private var composerFocused: Bool

    public init(viewModel: AskViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                modelBar
                Divider().background(Theme.border)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.thread.messages) { msg in
                                AskBubble(message: msg)
                                    .id(msg.id)
                            }
                            if viewModel.isSending {
                                HStack(spacing: 8) {
                                    ProgressView().scaleEffect(0.6)
                                    Text("thinking…")
                                        .workUppercaseLabel(9, color: Theme.textFaint)
                                }
                                .padding(.horizontal, 14)
                            }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(16)
                    }
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: viewModel.thread.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Ask AI")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { viewModel.start() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
    }

    private var modelBar: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(viewModel.availableModels, id: \.self) { m in
                    Button(m) { viewModel.model = m }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cpu").font(.system(size: 11))
                    Text(viewModel.model).workUppercaseLabel(10, color: Theme.accent)
                    Image(systemName: "chevron.down").font(.system(size: 9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.surface1, in: Capsule())
                .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
            }
            .foregroundStyle(Theme.accent)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.warning)
                Text(viewModel.spendFormatted)
                    .font(.workMono(11))
                    .foregroundStyle(Theme.textMuted)
                    .monospacedDigit()
                Text("·")
                    .foregroundStyle(Theme.textFaint)
                Text("\(viewModel.thread.totalInputTokens + viewModel.thread.totalOutputTokens) tok")
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.border)
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask anything…", text: $viewModel.composer, axis: .vertical)
                    .lineLimit(1...6)
                    .focused($composerFocused)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.border, lineWidth: 0.5)
                    )
                    .foregroundStyle(Theme.textPrimary)
                    .onSubmit { Task { await viewModel.send() } }
                Button {
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 36, height: 36)
                        .background(viewModel.composer.isEmpty ? Theme.textMuted : Theme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.composer.isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }
}

struct AskBubble: View {
    let message: AskMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if message.role == .assistant {
                        Image(systemName: "sparkle")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(message.role == .user ? "YOU" : message.model ?? "AI")
                        .workUppercaseLabel(9, color: message.role == .user ? Theme.textMuted : Theme.accent)
                }
                Text(.init(message.content))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(
                        message.role == .user ? Theme.accent.opacity(0.18) : Theme.surface1,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                message.role == .user ? Theme.accent.opacity(0.4) : Theme.border,
                                lineWidth: 0.5
                            )
                    )
                    .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                if let out = message.outputTokens, out > 0 {
                    Text("\(out) tok")
                        .font(.workMono(9))
                        .foregroundStyle(Theme.textFaint)
                }
            }
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack {
        AskView(viewModel: AskViewModel(repository: PreviewAskRepository()))
    }
}
