#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ChatView: View {
    let currentUser: UserProfile
    let item: MatchesViewModel.MatchListItem
    let onUnreadCountReset: () -> Void
    private let conversationService: any ConversationServicing
    @StateObject private var viewModel: ChatViewModel
    @State private var conversationID: String?
    @State private var scrollPosition: ChatMessage.ID?
    @State private var autoScrollEnabled = true
    @State private var showJumpToLatest = false
    @State private var isEnsuringConversation = false
    @State private var ensureError: String?

    @MainActor
    init(currentUser: UserProfile,
         item: MatchesViewModel.MatchListItem,
         messageRepository: ChatMessageRepository = FirestoreChatMessageRepository(),
         deliveryService: ChatDeliveryServicing? = FirestoreChatDeliveryService(),
         conversationService: ConversationServicing = FirestoreConversationService(),
         onUnreadCountReset: @escaping () -> Void) {
        self.currentUser = currentUser
        self.item = item
        self.onUnreadCountReset = onUnreadCountReset
        self.conversationService = conversationService

        let participants = item.match.participants.map { $0.userID }
        let initialConversationID: String?
        if let existingID = item.match.conversationID, !existingID.isEmpty {
            initialConversationID = existingID
        } else {
            initialConversationID = nil
        }

        _conversationID = State(initialValue: initialConversationID)
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationID: initialConversationID,
                                                             currentUserID: currentUser.id,
                                                             participants: participants,
                                                             messageRepository: messageRepository,
                                                             deliveryService: deliveryService))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let conversationID, !conversationID.isEmpty {
                conversationContent
                composer
            } else {
                ensureConversationContent
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(AroosiColors.background)
        .task(id: conversationID) {
            guard let conversationID, !conversationID.isEmpty else { return }
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
                        .font(AroosiTypography.heading(.h3))
                    if let counterpart = item.counterpartProfile,
                       let lastActive = counterpart.lastActiveAt {
                        Text("Active \(lastActive.relativeDescription())")
                            .font(AroosiTypography.caption())
                            .foregroundStyle(AroosiColors.muted)
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
                .background(AroosiColors.surfaceSecondary)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $scrollPosition)
                .refreshable {
                    await viewModel.refresh()
                    await viewModel.markConversationRead()
                    onUnreadCountReset()
                }
                .onChange(of: viewModel.state.messages) { _, messages in
                    guard autoScrollEnabled, let last = messages.last else { return }
                    withAnimation(.easeOut(duration: AroosiMotionDurations.fast)) {
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
                        withAnimation(.easeOut(duration: AroosiMotionDurations.short)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    } label: {
                        Label("Jump to Latest", systemImage: "arrow.down.circle.fill")
                            .font(AroosiTypography.body(weight: .semibold, size: 15))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AroosiColors.primary.opacity(0.12), in: Capsule())
                            .foregroundStyle(AroosiColors.primary)
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
                    .font(AroosiTypography.body(weight: .semibold, size: 17))

                if let location = profile.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }

                if let lastActive = profile.lastActiveAt {
                    Text("Active \(lastActive.relativeDescription())")
                        .font(AroosiTypography.caption())
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }

    private func avatar(for url: URL?) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ResponsiveAvatar(
                url: url,
                size: .medium,
                width: width
            )
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
                    .background(AroosiColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if viewModel.draftMessage.isEmpty {
                            Text("Message")
                                .foregroundStyle(AroosiColors.muted)
                                .padding(.leading, 16)
                                .padding(.top, 12)
                        }
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AroosiColors.primary)
                }
                .disabled(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(AroosiColors.background)
    }

    private var ensureConversationContent: some View {
        VStack(spacing: 24) {
            if let profile = item.counterpartProfile {
                conversationHeader(for: profile)
            } else {
                conversationFallbackHeader
            }

            VStack(spacing: 12) {
                Text("Start the conversation when you're ready")
                    .font(AroosiTypography.heading(.h3))
                    .multilineTextAlignment(.center)

                Text("Create a chat so both of you can coordinate inside Aroosi.")
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
                    .multilineTextAlignment(.center)
            }

            if let ensureError {
                Text(ensureError)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                Task { await ensureConversation() }
            } label: {
                Text(isEnsuringConversation ? "Starting conversation…" : "Start Conversation")
                    .font(AroosiTypography.body(weight: .semibold, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AroosiColors.primary)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
            .disabled(isEnsuringConversation)

            if isEnsuringConversation {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AroosiColors.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AroosiColors.surfaceSecondary)
    }

    private var conversationFallbackHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.circle")
                .font(.system(size: 56))
                .foregroundStyle(AroosiColors.primary)
            Text(title)
                .font(AroosiTypography.heading(.h3))
        }
        .frame(maxWidth: .infinity)
    }

    private func messageBubble(for message: ChatMessage) -> some View {
        let isCurrentUser = message.authorID == currentUser.id
        return HStack {
            if isCurrentUser { Spacer(minLength: 12) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isCurrentUser ? AroosiColors.primary : AroosiColors.surfaceSecondary)
                    .foregroundStyle(isCurrentUser ? Color.white : AroosiColors.text)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(message.sentAt, style: .time)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.muted)
            }

            if !isCurrentUser { Spacer(minLength: 12) }
        }
        .transition(.move(edge: isCurrentUser ? .trailing : .leading).combined(with: .opacity))
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(AroosiTypography.caption())
            .foregroundStyle(Color.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AroosiColors.error.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, 12)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AroosiColors.primary)
            Text("Loading conversation...")
                .font(AroosiTypography.caption())
                .foregroundStyle(AroosiColors.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AroosiColors.error)

            VStack(spacing: 4) {
                Text("Unable to load messages")
                    .font(AroosiTypography.heading(.h3))
                Text(message)
                    .font(AroosiTypography.body())
                    .foregroundStyle(AroosiColors.muted)
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
                    .font(AroosiTypography.body(weight: .semibold, size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AroosiColors.primary.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyConversationPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "message")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(AroosiColors.primary)

            Text("Say salaam to start the conversation")
                .font(AroosiTypography.heading(.h3))
                .multilineTextAlignment(.center)
            Text("Once someone replies you will see messages appear here.")
                .font(AroosiTypography.body())
                .foregroundStyle(AroosiColors.muted)
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

    @MainActor
    private func ensureConversation() async {
        guard !isEnsuringConversation else { return }
        if let conversationID, !conversationID.isEmpty {
            return
        }
        isEnsuringConversation = true
        ensureError = nil

        let participants = item.match.participants.map { $0.userID }

        do {
            let newConversationID = try await conversationService.ensureConversation(for: item.match,
                                                                                      participants: participants,
                                                                                      currentUserID: currentUser.id)
            viewModel.updateConversationID(newConversationID)
            conversationID = newConversationID
            autoScrollEnabled = true
            showJumpToLatest = false
            scrollPosition = nil
            onUnreadCountReset()
        } catch {
            ensureError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isEnsuringConversation = false
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
                 onUnreadCountReset: { })
    }
}
#endif
