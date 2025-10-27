#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ShortlistView: View {
    @StateObject private var viewModel: ShortlistViewModel
    @State private var editingNoteContext: EditingNoteContext?
    @State private var draftNote: String = ""

    @MainActor
    init(viewModel: ShortlistViewModel? = nil) {
        let resolvedViewModel = viewModel ?? ShortlistViewModel()
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Shortlist")
                .toolbar { refreshToolbar }
        }
        .tint(AroosiColors.primary)
        .task { viewModel.loadIfNeeded() }
        .sheet(item: $editingNoteContext) { context in
            NoteEditor(title: "Edit Note", initialText: draftNote) { action in
                switch action {
                case .cancel:
                    editingNoteContext = nil
                case .save(let text):
                    Task {
                        let success = await viewModel.updateNote(for: context.id, note: text)
                        if !success {
                            // restore draft state when write fails
                            draftNote = text
                            editingNoteContext = EditingNoteContext(id: context.id)
                        } else {
                            editingNoteContext = nil
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.entries.isEmpty {
            ProgressView("Loading shortlist…")
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
        } else if let error = viewModel.state.errorMessage, viewModel.state.entries.isEmpty {
            VStack(spacing: 12) {
                Text(error)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.text)
                    .multilineTextAlignment(.center)
                Button("Retry") { viewModel.refresh() }
                    .buttonStyle(.borderedProminent)
                    .tint(AroosiColors.primary)
            }
            .padding()
        } else if viewModel.state.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(AroosiColors.muted)
                Text("No profiles in your shortlist yet.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
            }
            .padding()
        } else {
            List {
                ForEach(viewModel.state.entries) { item in
                    NavigationLink(value: item.id) {
                        ShortlistRow(item: item) {
                            editingNoteContext = EditingNoteContext(id: item.id)
                            draftNote = item.note ?? ""
                        } removeAction: {
                            Task { await viewModel.toggleShortlist(userID: item.id) }
                        }
                    }
                }

                if viewModel.state.nextCursor != nil {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(AroosiColors.primary)
                        Spacer()
                    }
                    .task { viewModel.loadMore() }
                }
            }
            .navigationDestination(for: String.self) { profileID in
                ProfileSummaryDetailView(profileID: profileID)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AroosiColors.background)
            .refreshable { viewModel.refresh() }
        }
    }

    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.state.isLoading {
                ProgressView()
                    .tint(AroosiColors.primary)
            } else {
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

private struct EditingNoteContext: Identifiable {
    let id: String
}

@available(iOS 17, *)
private struct ShortlistRow: View {
    let item: ShortlistViewModel.ShortlistItem
    let noteAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 6) {
                Text(item.profile.displayName)
                    .font(AroosiTypography.body(weight: .semibold, size: 17))
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                        .lineLimit(3)
                }
            }
            Spacer()
            noteButton
            removeButton
        }
        .padding(.vertical, 8)
    }

    private var avatar: some View {
        Group {
            if let url = item.profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(AroosiColors.primary)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    @unknown default:
                        AroosiAsset.avatarPlaceholder
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                AroosiAsset.avatarPlaceholder
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .overlay { Circle().stroke(Color(.separator), lineWidth: 1) }
    }

    private var noteButton: some View {
        Button(action: noteAction) {
            Image(systemName: (item.note?.isEmpty == false) ? "note.text" : "note.text.badge.plus")
                .foregroundStyle(AroosiColors.primary)
        }
        .buttonStyle(.borderless)
    }

    private var removeButton: some View {
        Button(role: .destructive, action: removeAction) {
            Image(systemName: "bookmark.slash")
        }
        .buttonStyle(.borderless)
    }
}

@available(iOS 17, *)
private struct NoteEditor: View {
    enum Action {
        case cancel
        case save(String)
    }

    let title: String
    let initialText: String
    let completion: (Action) -> Void

    @State private var text: String

    init(title: String, initialText: String, completion: @escaping (Action) -> Void) {
        self.title = title
        self.initialText = initialText
        self.completion = completion
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .frame(minHeight: 200)
                    .background(AroosiColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { completion(.cancel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { completion(.save(text.trimmingCharacters(in: .whitespacesAndNewlines))) }
                        .tint(AroosiColors.primary)
                }
            }
        }
    }
}
#endif
