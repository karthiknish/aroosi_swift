import SwiftUI

#if os(iOS)
#if canImport(FirebaseFirestore)

@available(iOS 17.0, *)
struct ContentDetailView: View {
    let content: IslamicEducationalContent

    @StateObject private var service = IslamicEducationService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var showQuiz = false
    @State private var relatedContent: [IslamicEducationalContent] = []
    @State private var progress: UserContentProgress?

    init(content: IslamicEducationalContent) {
        self.content = content
        _likeCount = State(initialValue: content.likeCount)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                VStack(alignment: .leading, spacing: 16) {
                    metadataSection
                    actionButtons
                    Divider()
                    Text(content.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    contentBody
                    if let quiz = content.quiz {
                        quizSection(quiz: quiz)
                    }
                    if !relatedContent.isEmpty {
                        relatedContentSection
                    }
                }
                .padding()
                .background(AroosiColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
        .sheet(isPresented: $showQuiz) {
            if let quiz = content.quiz {
                QuizView(content: content, quiz: quiz)
                    .environmentObject(service)
                    .environmentObject(authService)
            }
        }
    }

    // MARK: - Header & Metadata

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let imageURL = headerImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle().fill(Color.gray.opacity(0.15))
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle().fill(Color.gray.opacity(0.15))
                            .overlay {
                                Image(systemName: "book.closed")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        Rectangle().fill(Color.gray.opacity(0.15))
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Label(content.category.displayName, systemImage: content.category.icon)
                    .font(.subheadline)
                    .foregroundStyle(AroosiColors.primary)
                Spacer()
            }

            Text(content.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                Label("\(content.estimatedReadTime) min", systemImage: "clock")
                Label(content.difficultyLevel.displayName, systemImage: "chart.bar")
                if let author = content.author {
                    Label(author, systemImage: "person")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                Task { await toggleBookmark() }
            } label: {
                Label(isBookmarked ? "Bookmarked" : "Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .tint(.aroosi)

            Button {
                Task { await toggleLike() }
            } label: {
                Label("\(likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Spacer()

            if let progress = progress, progress.completed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Completed")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Content Body

    @ViewBuilder
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !sortedSections.isEmpty {
                ForEach(sortedSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(section.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
            }

            if let verses = content.content.quranicVerses, !verses.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Related Quranic Verses")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(verses) { verse in
                        QuranVerseCard(verse: verse)
                    }
                }
            }

            if let hadiths = content.content.hadiths, !hadiths.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Related Hadiths")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(hadiths) { hadith in
                        HadithCard(hadith: hadith)
                    }
                }
            }

            if let images = content.content.images, !images.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Image Gallery")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(images) { image in
                        VStack(alignment: .leading, spacing: 8) {
                            AsyncImage(url: image.url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle().fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                case .success(let loaded):
                                    loaded
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure:
                                    Rectangle().fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundStyle(.secondary)
                                        }
                                @unknown default:
                                    Rectangle().fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            if let caption = image.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let videos = content.content.videos, !videos.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Video Resources")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(videos) { video in
                        Link(destination: video.url) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(AroosiColors.primary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    Text(formatDuration(video.duration))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(AroosiColors.mutedSystemBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }

            if let keyTakeaways = content.content.keyTakeaways, !keyTakeaways.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Takeaways")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(keyTakeaways, id: \.self) { takeaway in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AroosiColors.primary)
                            Text(takeaway)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            if let references = content.content.references, !references.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("References")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(references, id: \.self) { reference in
                        Text(reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Quiz Section

    private func quizSection(quiz: EducationalQuiz) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Test Your Knowledge")
                .font(.title3)
                .fontWeight(.semibold)

            Text(quiz.title)
                .font(.headline)

            Text(quiz.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showQuiz = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Take Quiz")
                    Spacer()
                    Text("\(quiz.questions.count) questions")
                        .font(.caption)
                }
                .padding()
                .background(Color.aroosi)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Related Content

    private var relatedContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Related Content")
                .font(.title3)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedContent) { item in
                        NavigationLink(destination: ContentDetailView(content: item)) {
                            RelatedContentCard(content: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var headerImageURL: URL? {
        if let image = content.content.images?.first?.url {
            return image
        }
        if let thumbnail = content.content.videos?.first?.thumbnailURL {
            return thumbnail
        }
        return nil
    }

    private var sortedSections: [ContentSection] {
        content.content.sections.sorted { $0.order < $1.order }
    }

    private func loadContent() async {
        guard let userId = authService.currentUser?.uid else { return }

        await service.markAsViewed(contentId: content.id, userId: userId)
        isBookmarked = await service.isBookmarked(contentId: content.id, userId: userId)
        progress = service.getProgress(for: content.id)
        relatedContent = await service.getRelatedContent(to: content.id)
    }

    private func toggleBookmark() async {
        guard let userId = authService.currentUser?.uid else { return }
        let newValue = await service.toggleBookmark(contentId: content.id, userId: userId)
        if newValue != isBookmarked {
            isBookmarked = newValue
        }
    }

    private func toggleLike() async {
        guard let userId = authService.currentUser?.uid else { return }
        let newValue = await service.toggleLike(contentId: content.id, userId: userId)
        if newValue != isLiked {
            isLiked = newValue
            likeCount = max(likeCount + (newValue ? 1 : -1), 0)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Quran Verse Card

private struct QuranVerseCard: View {
    let verse: QuranicVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !verse.arabicText.isEmpty {
                Text(verse.arabicText)
                    .font(.title3)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(verse.translation)
                .font(.body)
                .italic()

            Text("Surah \(verse.surahName) (\(verse.surahNumber):\(verse.verseNumber))")
                .font(.caption)
                .foregroundStyle(.aroosi)
                .fontWeight(.medium)

            if let context = verse.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.aroosi.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.aroosi.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Hadith Card

private struct HadithCard: View {
    let hadith: Hadith

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !hadith.arabicText.isEmpty {
                Text(hadith.arabicText)
                    .font(.title3)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(hadith.translation)
                .font(.body)
                .italic()

            HStack {
                Text(hadith.source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)

                Text("• \(hadith.reference)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let context = hadith.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Related Content Card

private struct RelatedContentCard: View {
    let content: IslamicEducationalContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = content.content.images?.first?.url {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(Color.gray.opacity(0.2))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle().fill(Color.gray.opacity(0.2))
                            .overlay {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 200, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text(content.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text("\(content.estimatedReadTime) min read")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 200)
    }
}

#endif

#endif
