import SwiftUI

#if os(iOS)
@available(iOS 17, *)
struct IcebreakersView: View {
    let user: UserProfile
    @StateObject private var viewModel: IcebreakersViewModel

    @MainActor
    init(user: UserProfile, viewModel: IcebreakersViewModel? = nil) {
        self.user = user
        let resolvedViewModel = viewModel ?? IcebreakersViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if viewModel.state.items.isEmpty && !viewModel.state.isLoading {
                        emptyState
                    } else {
                        Section {
                            ForEach(viewModel.state.items) { item in
                                IcebreakerRowView(item: item,
                                                  isSaving: viewModel.state.savingIdentifiers.contains(item.id),
                                                  onSave: { answer in
                                                      Task { await viewModel.submit(answer: answer, for: item.id) }
                                                  },
                                                  onNext: {
                                                      moveToNext(after: item.id, proxy: proxy)
                                                  })
                                .id(item.id)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { viewModel.refresh() }
                .overlay(alignment: .bottom) { progressBanner }
                .overlay { loadingOverlay }
                .alert("Heads up", isPresented: Binding(
                    get: { viewModel.state.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented { viewModel.dismissError() }
                    }
                )) {
                    Button("OK", role: .cancel) { viewModel.dismissError() }
                } message: {
                    Text(viewModel.state.errorMessage ?? "")
                }
            }
            .navigationTitle("Icebreakers")
        }
        .task(id: user.id) {
            viewModel.load(for: user.id)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 48))
                .foregroundStyle(AroosiColors.primary)
            Text("No icebreakers available right now.")
                .font(AroosiTypography.heading(.h3))
            Text("Check back later for new questions to share on your profile.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
    }

    private var progressBanner: some View {
        Group {
            if viewModel.state.items.isEmpty { EmptyView() }
            else {
                let answeredCount = viewModel.state.items.filter { $0.isAnswered }.count
                let total = viewModel.state.items.count
                HStack(spacing: 12) {
                    ProgressView(value: viewModel.state.completionProgress)
                        .progressViewStyle(.linear)
                        .tint(AroosiColors.primary)
                    Text("\(answeredCount) / \(total) answered")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 24)
            }
        }
    }

    private var loadingOverlay: some View {
        Group {
            if viewModel.state.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    private func moveToNext(after currentID: String, proxy: ScrollViewProxy) {
        guard let index = viewModel.state.items.firstIndex(where: { $0.id == currentID }) else { return }
        let nextIndex = viewModel.state.items.index(after: index)
        guard nextIndex < viewModel.state.items.endIndex else { return }
        let nextID = viewModel.state.items[nextIndex].id
        withAnimation {
            proxy.scrollTo(nextID, anchor: .top)
        }
    }
}

@available(iOS 17, *)
private struct IcebreakerRowView: View {
    let item: IcebreakerItem
    let isSaving: Bool
    let onSave: (String) -> Void
    let onNext: () -> Void

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(item: IcebreakerItem,
         isSaving: Bool,
         onSave: @escaping (String) -> Void,
         onNext: @escaping () -> Void) {
        self.item = item
        self.isSaving = isSaving
        self.onSave = onSave
        self.onNext = onNext
        _text = State(initialValue: item.currentAnswer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.text)
                .font(AroosiTypography.heading(.h3))

            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: 140)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AroosiColors.surfaceSecondary, lineWidth: 1)
                )
                .onChange(of: item.currentAnswer) { newValue in
                    if !isFocused {
                        text = newValue
                    }
                }

            HStack {
                Text(characterStatus)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)

                Spacer()

                Button("Skip") {
                    isFocused = false
                    onNext()
                }
                .buttonStyle(.borderless)
                .font(AroosiTypography.caption(weight: .semibold))

                Button(action: save) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text(item.isAnswered ? "Update" : "Save")
                            .font(AroosiTypography.caption(weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AroosiColors.primary)
                .disabled(!canSave || isSaving)

                Button("Next →") {
                    isFocused = false
                    onNext()
                }
                .buttonStyle(.borderless)
                .font(AroosiTypography.caption(weight: .semibold))
            }
        }
        .padding(.vertical, 12)
    }

    private var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 && !isSaving
    }

    private var characterStatus: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let remaining = max(0, 10 - trimmed.count)
        return remaining > 0 ? "\(remaining) more characters to go" : "Looks good!"
    }

    private func save() {
        isFocused = false
        onSave(text)
    }
}
#endif
