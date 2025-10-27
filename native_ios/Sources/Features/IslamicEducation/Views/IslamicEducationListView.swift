import SwiftUI

#if canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
struct IslamicEducationListView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var service = IslamicEducationService()
    @State private var selectedCategory: EducationCategory?
    @State private var searchQuery = ""
    @State private var searchResults: [IslamicEducationalContent] = []
    @State private var isSearching = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AroosiSpacing.lg) {
                    // Search Bar
                    SearchBar(text: $searchQuery, onSubmit: performSearch)
                        .padding(.horizontal, AroosiSpacing.md)
                    
                    if isSearching {
                        searchResultsView
                    } else {
                        mainContentView
                    }
                }
                .padding(.vertical, AroosiSpacing.md)
            }
            .background(AroosiColors.background)
            .navigationTitle("Islamic Education")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: BookmarkedContentView()) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(AroosiColors.primary)
                    }
                }
            }
        }
        .tint(AroosiColors.primary)
        .task {
            await service.loadFeaturedContent()
            // Load user progress when auth is available
            if let userId = authService.currentUser?.uid {
                await service.loadUserProgress(userId: userId)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: AroosiSpacing.lg) {
            // Featured Content
            if !service.featuredContent.isEmpty {
                VStack(alignment: .leading, spacing: AroosiSpacing.sm) {
                    Text("Featured")
                        .font(AroosiTypography.heading(.h2))
                        .foregroundStyle(AroosiColors.text)
                        .padding(.horizontal, AroosiSpacing.md)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AroosiSpacing.md) {
                            ForEach(service.featuredContent) { content in
                                NavigationLink(destination: ContentDetailView(content: content)) {
                                    FeaturedContentCard(content: content)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AroosiSpacing.md)
                    }
                }
            }
            
            // Categories
            VStack(alignment: .leading, spacing: AroosiSpacing.sm) {
                Text("Explore by Category")
                    .font(AroosiTypography.heading(.h2))
                    .foregroundStyle(AroosiColors.text)
                    .padding(.horizontal, AroosiSpacing.md)
                
                LazyVGrid(columns: columns, spacing: AroosiSpacing.md) {
                    ForEach(EducationCategory.allCases, id: \.self) { category in
                        NavigationLink(destination: CategoryContentView(category: category)) {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AroosiSpacing.md)
            }
            
            // Your Progress - Enabled when auth is available
            if let userId = authService.currentUser?.uid {
                ProgressSummaryView(userId: userId)
                    .environmentObject(service)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term")
                )
                .frame(height: 300)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults) { content in
                        NavigationLink(destination: ContentDetailView(content: content)) {
                            ContentListRow(content: content)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Search
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        
        isSearching = true
        Task {
            searchResults = await service.searchContent(query: searchQuery)
        }
    }
}

// MARK: - Featured Content Card

@available(iOS 17.0.0, *)
private struct FeaturedContentCard: View {
    let content: IslamicEducationalContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            if let imageUrl = content.content.images?.first?.url {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 280, height: 160)
                .clipped()
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(content.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(content.estimatedReadTime) min", systemImage: "clock")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                        Text("\(content.viewCount ?? 0)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 280)
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Category Card

@available(iOS 17.0.0, *)
private struct CategoryCard: View {
    let category: EducationCategory
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundStyle(.aroosi)
            
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(AroosiColors.mutedSystemBackground)
        .cornerRadius(12)
    }
}

// MARK: - Content List Row

@available(iOS 17.0.0, *)
private struct ContentListRow: View {
    let content: IslamicEducationalContent
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageUrl = content.content.images?.first?.url {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(content.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(content.estimatedReadTime) min", systemImage: "clock")
                    Spacer()
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(content.viewCount ?? 0)")
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                            Text("\(content.likeCount ?? 0)")
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Progress Summary

@available(iOS 17.0.0, *)
private struct ProgressSummaryView: View {
    let userId: String
    @EnvironmentObject var service: IslamicEducationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Completed",
                    value: "\(service.userProgress.values.filter { $0.completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "In Progress",
                    value: "\(service.userProgress.values.filter { !$0.completed && $0.viewedAt != nil }.count)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Completion",
                    value: String(format: "%.0f%%", service.getCompletionRate() * 100),
                    icon: "chart.pie.fill",
                    color: .aroosi
                )
            }
        }
        .padding()
        .background(AroosiColors.mutedSystemBackground)
        .cornerRadius(12)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(8)
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search educational content...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(AroosiColors.mutedSystemBackground)
        .cornerRadius(10)
    }
}

// MARK: - Category Extensions

extension EducationCategory {
    var icon: String {
        switch self {
        case .islamicMarriage: return "heart.circle"
        case .familyValues: return "house.fill"
        case .relationshipAdvice: return "person.2.fill"
        case .islamicEthics: return "book.fill"
        case .afghanCulture: return "globe.asia.australia.fill"
        case .general: return "sparkles"
        }
    }
}

// MARK: - Previews

#Preview {
    IslamicEducationListView()
        
}
#endif
