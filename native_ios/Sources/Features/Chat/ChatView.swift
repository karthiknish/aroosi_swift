#if os(iOS)
import SwiftUI

@available(iOS 17, macOS 13, *)
struct ChatView: View {
    let currentUser: UserProfile
    let item: MatchesViewModel.MatchListItem
    let onUnreadCountReset: () -> Void
    @StateObject private var viewModel: ChatViewModel
    @State private var scrollPosition: ChatMessage.ID?
    @State private var autoScrollEnabled = true
    @State private var showJumpToLatest = false

    @MainActor
    init(currentUser: UserProfile,
         item: MatchesViewModel.MatchListItem,
         messageRepository: ChatMessageRepository = FirestoreChatMessageRepository(),
         deliveryService: ChatDeliveryServicing? = FirestoreChatDeliveryService(),
         onUnreadCountReset: @escaping () -> Void) {
        self.currentUser = currentUser
        self.item = item
        self.onUnreadCountReset = onUnreadCountReset

        let participants = item.match.participants.map { $0.userID }
        if let conversationID = item.match.conversationID {
            _viewModel = StateObject(wrappedValue: ChatViewModel(conversationID: conversationID,
                                                                 currentUserID: currentUser.id,
                                                                 participants: participants,
                                                                 messageRepository: messageRepository,
                                                                 deliveryService: deliveryService))
        } else {
            _viewModel = StateObject(wrappedValue: ChatViewModel(conversationID: "",
                                                                 currentUserID: currentUser.id,
                                                                 participants: participants,
                                                                 messageRepository: messageRepository,
                                                                 deliveryService: deliveryService))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let conversationID = item.match.conversationID, !conversationID.isEmpty {
                conversationContent
                composer
            } else {
                unavailableContent
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .task(id: item.match.conversationID) {
            guard let conversationID = item.match.conversationID, !conversationID.isEmpty else { return }
            autoScrollEnabled = true
            showJumpToLatest = false
            scrollPosition = nil
            viewModel.observeMessages()
            await viewModel.markConversationRead()
            onUnreadCountReset()
        }
        .onDisappear {
            viewModel.stop()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                    if let counterpart = item.counterpartProfile,
                       let lastActive = counterpart.lastActiveAt {
                        Text("Active \(lastActive.relativeDescription())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var title: String {
        if let name = item.counterpartProfile?.displayName, !name.isEmpty {
            return name
        }
        return "Match"
    }

    private var conversationContent: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let counterpart = item.counterpartProfile {
                            conversationHeader(for: counterpart)
                        }

                        if viewModel.state.isLoading && viewModel.state.messages.isEmpty {
                            loadingPlaceholder
                        } else if let error = viewModel.state.errorMessage, viewModel.state.messages.isEmpty {
                            errorPlaceholder(message: error)
                        } else if viewModel.state.messages.isEmpty {
                            emptyConversationPlaceholder
                        } else {
                            ForEach(viewModel.state.messages) { message in
                                messageBubble(for: message)
                                    .id(message.id)
                            }
                        }

                        if let error = viewModel.state.errorMessage,
                           !viewModel.state.messages.isEmpty {
                            errorBanner(error)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .scrollTargetLayout()
                }
                .background(Color(.systemGroupedBackground))
                .scrollIndicators(.hidden)
                .scrollPosition(id: $scrollPosition)
                .refreshable {
                    await viewModel.refresh()
                    await viewModel.markConversationRead()
                    onUnreadCountReset()
                }
                .onChange(of: viewModel.state.messages) { _, messages in
                    guard autoScrollEnabled, let last = messages.last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: scrollPosition) { position in
                    guard let lastID = viewModel.state.messages.last?.id else {
                        showJumpToLatest = false
                        autoScrollEnabled = true
                        return
                    }

                    if position == lastID || viewModel.state.messages.count <= 1 {
                        showJumpToLatest = false
                        autoScrollEnabled = true
                    } else if position != nil {
                        showJumpToLatest = true
                        autoScrollEnabled = false
                    }
                }

                if showJumpToLatest {
                    Button {
                        guard let last = viewModel.state.messages.last else { return }
                        autoScrollEnabled = true
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    } label: {
                        Label("Jump to Latest", systemImage: "arrow.down.circle.fill")
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func conversationHeader(for profile: ProfileSummary) -> some View {
        HStack(spacing: 16) {
            avatarView(for: profile)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName.isEmpty ? "Match" : profile.displayName)
                    .font(.headline)

                if let location = profile.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lastActive = profile.lastActiveAt {
                    Text("Active \(lastActive.relativeDescription())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }

    private func avatarView(for profile: ProfileSummary) -> some View {
        Group {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(alignment: .bottom, spacing: 12) {
                TextEditor(text: $viewModel.draftMessage)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 36, idealHeight: 44)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if viewModel.draftMessage.isEmpty {
                            Text("Message")
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 16)
                                .padding(.top, 12)
                        }
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                }
                .disabled(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private var unavailableContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "ellipsis.bubble")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("Conversation not ready yet")
                .font(.headline)
            Text("We will notify you when you can start chatting here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func messageBubble(for message: ChatMessage) -> some View {
        let isCurrentUser = message.authorID == currentUser.id
        return HStack {
            if isCurrentUser { Spacer(minLength: 12) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isCurrentUser ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(isCurrentUser ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(message.sentAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !isCurrentUser { Spacer(minLength: 12) }
        }
        .transition(.move(edge: isCurrentUser ? .trailing : .leading).combined(with: .opacity))
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(Color.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, 12)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading conversation...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.red)

            VStack(spacing: 4) {
                Text("Unable to load messages")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await viewModel.refresh()
                    await viewModel.markConversationRead()
                    onUnreadCountReset()
                }
            } label: {
                Text("Try Again")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyConversationPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "message")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Color.accentColor)

            Text("Say salaam to start the conversation")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Once someone replies you will see messages appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func sendMessage() {
        autoScrollEnabled = true
        Task {
            await viewModel.sendMessage()
        }
    }
}

#Preview {
    if #available(iOS 17, *) {
        let summary = ProfileSummary(id: "user-2",
                                     displayName: "Nadia",
                                     age: 28,
                                     location: "San Francisco",
                                     bio: "Adventurer",
                                     avatarURL: nil,
                                     interests: ["Cuisine", "Travel"],
                                     lastActiveAt: .now.addingTimeInterval(-3600))
        let match = Match(
            id: "match-1",
            participants: [
                Match.Participant(userID: "user-1", isInitiator: true),
                Match.Participant(userID: "user-2", isInitiator: false)
            ],
            status: .active,
            lastMessagePreview: "Salaam!",
            lastUpdatedAt: .now,
            conversationID: "conversation-1"
        )
        let item = MatchesViewModel.MatchListItem(id: match.id,
                                                  match: match,
                                                  counterpartProfile: summary,
                                                  unreadCount: 3)
        ChatView(currentUser: UserProfile(id: "user-1", displayName: "You", email: nil, avatarURL: nil),
                 item: item,
                 onUnreadCountReset: { _ in })
    }
}
#endif
