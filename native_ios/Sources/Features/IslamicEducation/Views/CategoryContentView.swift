import SwiftUI

#if canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct CategoryContentView: View {
    let category: EducationCategory
    
    @StateObject private var service = IslamicEducationService()
    @State private var content: [IslamicEducationalContent] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(.aroosi)
                    
                    Text(category.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AroosiColors.mutedSystemBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Content List
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if content.isEmpty {
                    ContentUnavailableView(
                        "No Content Available",
                        systemImage: "book.closed",
                        description: Text("Check back later for new educational content")
                    )
                    .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(content) { item in
                            NavigationLink(destination: ContentDetailView(content: item)) {
                                CategoryContentRow(content: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        content = await service.loadContent(for: category)
        isLoading = false
    }
}

// MARK: - Category Content Row

private struct CategoryContentRow: View {
    let content: IslamicEducationalContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let imageUrl = content.content.thumbnailUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(content.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    
                    HStack(spacing: 12) {
                        Label("\(content.estimatedReadTime) min", systemImage: "clock")
                        Label(content.difficultyLevel.displayName, systemImage: "chart.bar")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(AroosiColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Bookmarked Content View

@available(iOS 17.0.0, *)
struct BookmarkedContentView: View {
    @StateObject private var service = IslamicEducationService()
    @EnvironmentObject private var authService: AuthenticationService
    
    var body: some View {
        ScrollView {
            if service.bookmarkedContent.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Bookmark content to access it quickly later")
                )
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(service.bookmarkedContent) { content in
                        NavigationLink(destination: ContentDetailView(content: content)) {
                            CategoryContentRow(content: content)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Bookmarks")
        .task {
            if let userId = authService.currentUser?.uid {
                await service.loadBookmarks(userId: userId)
            }
        }
    }
}

// MARK: - Extensions

extension EducationCategory {
    var description: String {
        switch self {
        case .islamicMarriage:
            return "Learn about the sacred bond of marriage in Islam and its significance"
        case .familyValues:
            return "Explore Islamic teachings on family, kinship, and community"
        case .parentingIslam:
            return "Guidance on raising children according to Islamic principles"
        case .relationshipEthics:
            return "Understanding halal relationships and Islamic boundaries"
        case .spiritualGrowth:
            return "Strengthen your faith and connection with Allah"
        case .islamicEtiquette:
            return "Learn proper conduct and manners in Islam"
        case .communicationSkills:
            return "Develop effective and respectful communication"
        case .conflictResolution:
            return "Islamic approaches to resolving disputes peacefully"
        case .afghanCulture:
            return "Discover Afghan cultural traditions and heritage"
        case .islamicHistory:
            return "Journey through Islamic history and civilization"
        }
    }
}

// MARK: - Previews

#Preview("Category View") {
    NavigationStack {
        CategoryContentView(category: .islamicMarriage)
    }
}

#Preview("Bookmarks") {
    NavigationStack {
        BookmarkedContentView()
            
    }
}
#endif
