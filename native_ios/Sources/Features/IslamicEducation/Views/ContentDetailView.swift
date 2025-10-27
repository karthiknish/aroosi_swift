import SwiftUI

#if canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct ContentDetailView: View {
    let content: IslamicEducationalContent
    
    @StateObject private var service = IslamicEducationService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var showQuiz = false
    @State private var relatedContent: [IslamicEducationalContent] = []
    @State private var progress: UserContentProgress?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                if let imageUrl = content.content.thumbnailUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title & Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text(content.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label(content.category.displayName, systemImage: content.category.icon)
                            Spacer()
                            Label("\(content.estimatedReadTime) min", systemImage: "clock")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        if let author = content.author {
                            Text("By \(author)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: { Task { await toggleBookmark() } }) {
                            Label(isBookmarked ? "Bookmarked" : "Bookmark", systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.aroosi)
                        
                        Button(action: { Task { await toggleLike() } }) {
                            Label("\(content.likeCount ?? 0)", systemImage: isLiked ? "heart.fill" : "heart")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        
                        Spacer()
                        
                        if let progress = progress, progress.completed {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Completed")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    Text(content.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    // Main Content
                    contentBody
                    
                    // Quiz Section
                    if let quiz = content.quiz {
                        quizSection(quiz: quiz)
                    }
                    
                    // Related Content
                    if !relatedContent.isEmpty {
                        relatedContentSection
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
    }
    
    // MARK: - Content Body
    
    @ViewBuilder
    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sections
            ForEach(content.content.sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(section.content)
                        .font(.body)
                        .lineSpacing(4)
                }
            }
            
            // Quranic Verses
            if !content.content.verses.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Related Quranic Verses")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    ForEach(content.content.verses) { verse in
                        QuranVerseCard(verse: verse)
                    }
                }
            }
            
            // Hadiths
            if !content.content.hadiths.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Related Hadiths")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    ForEach(content.content.hadiths) { hadith in
                        HadithCard(hadith: hadith)
                    }
                }
            }
            
            // Images
            ForEach(content.content.images, id: \.url) { image in
                VStack(alignment: .leading, spacing: 8) {
                    AsyncImage(url: URL(string: image.url)) { img in
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                    }
                    .cornerRadius(8)
                    
                    if let caption = image.caption {
                        Text(caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Videos
            ForEach(content.content.videos, id: \.url) { video in
                VStack(alignment: .leading, spacing: 8) {
                    Link(destination: URL(string: video.url)!) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(video.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let duration = video.duration {
                                    Text("\(duration / 60):\(String(format: "%02d", duration % 60))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(AroosiColors.mutedSystemBackground)
                        .cornerRadius(8)
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
            
            Button(action: { showQuiz = true }) {
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
                .cornerRadius(8)
            }
            .sheet(isPresented: $showQuiz) {
                QuizView(content: content, quiz: quiz)
                    .environmentObject(service)
                    .environmentObject(authService)
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
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadContent() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        // Mark as viewed
        await service.markAsViewed(contentId: content.id, userId: userId)
        
        // Check bookmark status
        isBookmarked = await service.isBookmarked(contentId: content.id, userId: userId)
        
        // Load progress
        progress = service.getProgress(for: content.id)
        
        // Load related content
        relatedContent = await service.getRelatedContent(to: content.id)
    }
    
    private func toggleBookmark() async {
        guard let userId = authService.currentUser?.uid else { return }
        isBookmarked = await service.toggleBookmark(contentId: content.id, userId: userId)
    }
    
    private func toggleLike() async {
        guard let userId = authService.currentUser?.uid else { return }
        isLiked = await service.toggleLike(contentId: content.id, userId: userId)
    }
}

// MARK: - Quran Verse Card

private struct QuranVerseCard: View {
    let verse: QuranicVerse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Arabic text
            if let arabic = verse.arabicText {
                Text(arabic)
                    .font(.title2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 4)
            }
            
            // Translation
            Text(verse.translation)
                .font(.body)
                .italic()
            
            // Reference
            Text("Surah \(verse.surahName) (\(verse.surahNumber):\(verse.verseNumber))")
                .font(.caption)
                .foregroundStyle(.aroosi)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.aroosi.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
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
            // Arabic text
            if let arabic = hadith.arabicText {
                Text(arabic)
                    .font(.title3)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 4)
            }
            
            // Translation
            Text(hadith.translation)
                .font(.body)
                .italic()
            
            // Reference
            HStack {
                Text(hadith.source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                
                Text("• \(hadith.reference)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
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
            if let images = content.content.images, let firstImage = images.first {
                AsyncImage(url: firstImage.url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 200, height: 120)
                .clipped()
                .cornerRadius(8)
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

// MARK: - Previews

#Preview {
    NavigationStack {
        ContentDetailView(content: IslamicEducationalContent(
            id: "1",
            title: "The Importance of Marriage in Islam",
            description: "Understanding the sacred bond of marriage",
            category: .islamicMarriage,
            contentType: .article,
            content: EducationContent(
                sections: [
                    ContentSection(
                        title: "Introduction",
                        content: "Marriage is considered half of one's faith in Islam..."
                    )
                ],
                verses: [],
                hadiths: [],
                images: [],
                videos: [],
                thumbnailUrl: nil
            ),
            difficultyLevel: .beginner,
            estimatedReadTime: 10,
            createdAt: Date(),
            updatedAt: Date(),
            author: "Islamic Scholar",
            tags: ["marriage", "faith"],
            isFeatured: true,
            viewCount: 150,
            likeCount: 45,
            bookmarkCount: 30,
            quiz: nil,
            relatedContent: nil
        ))
        
    }
}
#endif
