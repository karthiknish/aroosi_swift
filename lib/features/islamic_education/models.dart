class IslamicEducationalContent {
  const IslamicEducationalContent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.contentType,
    required this.content,
    required this.difficultyLevel,
    required this.estimatedReadTime,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.tags,
    this.isFeatured = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.bookmarkCount = 0,
    this.quiz,
    this.relatedContent,
  });

  final String id;
  final String title;
  final String description;
  final EducationCategory category;
  final EducationContentType contentType;
  final EducationContent content;
  final DifficultyLevel difficultyLevel;
  final int estimatedReadTime; // in minutes
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? author;
  final List<String>? tags;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final int bookmarkCount;
  final EducationalQuiz? quiz;
  final List<String>? relatedContent;

  factory IslamicEducationalContent.fromJson(Map<String, dynamic> json) {
    return IslamicEducationalContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: EducationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EducationCategory.general,
      ),
      contentType: EducationContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => EducationContentType.article,
      ),
      content: EducationContent.fromJson(json['content'] as Map<String, dynamic>),
      difficultyLevel: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficultyLevel'],
        orElse: () => DifficultyLevel.beginner,
      ),
      estimatedReadTime: json['estimatedReadTime'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      author: json['author'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
      quiz: json['quiz'] != null
          ? EducationalQuiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
      relatedContent: (json['relatedContent'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'contentType': contentType.name,
      'content': content.toJson(),
      'difficultyLevel': difficultyLevel.name,
      'estimatedReadTime': estimatedReadTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'author': author,
      'tags': tags,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'bookmarkCount': bookmarkCount,
      'quiz': quiz?.toJson(),
      'relatedContent': relatedContent,
    };
  }
}

class EducationContent {
  const EducationContent({
    required this.sections,
    this.quranicVerses,
    this.hadiths,
    this.images,
    this.videos,
    this.keyTakeaways,
  });

  final List<ContentSection> sections;
  final List<QuranicVerse>? quranicVerses;
  final List<Hadith>? hadiths;
  final List<ContentImage>? images;
  final List<ContentVideo>? videos;
  final List<String>? keyTakeaways;

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      sections: (json['sections'] as List<dynamic>)
          .map((e) => ContentSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      quranicVerses: (json['quranicVerses'] as List<dynamic>?)
          ?.map((e) => QuranicVerse.fromJson(e as Map<String, dynamic>))
          .toList(),
      hadiths: (json['hadiths'] as List<dynamic>?)
          ?.map((e) => Hadith.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ContentImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => ContentVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
      keyTakeaways: (json['keyTakeaways'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((e) => e.toJson()).toList(),
      'quranicVerses': quranicVerses?.map((e) => e.toJson()).toList(),
      'hadiths': hadiths?.map((e) => e.toJson()).toList(),
      'images': images?.map((e) => e.toJson()).toList(),
      'videos': videos?.map((e) => e.toJson()).toList(),
      'keyTakeaways': keyTakeaways,
    };
  }
}

class ContentSection {
  const ContentSection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    this.sectionType = SectionContentType.text,
  });

  final String id;
  final String title;
  final String content;
  final int order;
  final SectionContentType sectionType;

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
      sectionType: SectionContentType.values.firstWhere(
        (e) => e.name == json['sectionType'],
        orElse: () => SectionContentType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'sectionType': sectionType.name,
    };
  }
}

class QuranicVerse {
  const QuranicVerse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.englishTranslation,
    required this.transliteration,
    this.context,
    this.relevanceToMarriage,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String englishTranslation;
  final String transliteration;
  final String? context;
  final String? relevanceToMarriage;

  String get verseReference => '$surahNumber:$ayahNumber';

  factory QuranicVerse.fromJson(Map<String, dynamic> json) {
    return QuranicVerse(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      arabicText: json['arabicText'] as String,
      englishTranslation: json['englishTranslation'] as String,
      transliteration: json['transliteration'] as String,
      context: json['context'] as String?,
      relevanceToMarriage: json['relevanceToMarriage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'arabicText': arabicText,
      'englishTranslation': englishTranslation,
      'transliteration': transliteration,
      'context': context,
      'relevanceToMarriage': relevanceToMarriage,
    };
  }
}

class Hadith {
  const Hadith({
    required this.id,
    required this.arabicText,
    required this.englishTranslation,
    required this.source,
    required this.narrator,
    required this.authenticityGrade,
    this.relevanceToMarriage,
    this.explanation,
  });

  final String id;
  final String arabicText;
  final String englishTranslation;
  final HadithSource source;
  final String narrator;
  final AuthenticityGrade authenticityGrade;
  final String? relevanceToMarriage;
  final String? explanation;

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as String,
      arabicText: json['arabicText'] as String,
      englishTranslation: json['englishTranslation'] as String,
      source: HadithSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => HadithSource.bukhari,
      ),
      narrator: json['narrator'] as String,
      authenticityGrade: AuthenticityGrade.values.firstWhere(
        (e) => e.name == json['authenticityGrade'],
        orElse: () => AuthenticityGrade.sahih,
      ),
      relevanceToMarriage: json['relevanceToMarriage'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabicText': arabicText,
      'englishTranslation': englishTranslation,
      'source': source.name,
      'narrator': narrator,
      'authenticityGrade': authenticityGrade.name,
      'relevanceToMarriage': relevanceToMarriage,
      'explanation': explanation,
    };
  }
}

class ContentImage {
  const ContentImage({
    required this.url,
    required this.caption,
    required this.altText,
    this.source,
    this.width,
    this.height,
  });

  final String url;
  final String caption;
  final String altText;
  final String? source;
  final int? width;
  final int? height;

  factory ContentImage.fromJson(Map<String, dynamic> json) {
    return ContentImage(
      url: json['url'] as String,
      caption: json['caption'] as String,
      altText: json['altText'] as String,
      source: json['source'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'caption': caption,
      'altText': altText,
      'source': source,
      'width': width,
      'height': height,
    };
  }
}

class ContentVideo {
  const ContentVideo({
    required this.url,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    this.description,
  });

  final String url;
  final String title;
  final int duration; // in seconds
  final String thumbnailUrl;
  final String? description;

  factory ContentVideo.fromJson(Map<String, dynamic> json) {
    return ContentVideo(
      url: json['url'] as String,
      title: json['title'] as String,
      duration: json['duration'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
    };
  }
}

class EducationalQuiz {
  const EducationalQuiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.passingScore,
    this.timeLimit, // in minutes
    this.description,
  });

  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final double passingScore; // 0.0 to 1.0
  final int? timeLimit;
  final String? description;

  factory EducationalQuiz.fromJson(Map<String, dynamic> json) {
    return EducationalQuiz(
      id: json['id'] as String,
      title: json['title'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      passingScore: (json['passingScore'] as num).toDouble(),
      timeLimit: json['timeLimit'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((e) => e.toJson()).toList(),
      'passingScore': passingScore,
      'timeLimit': timeLimit,
      'description': description,
    };
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.questionType = QuizQuestionType.multipleChoice,
  });

  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final QuizQuestionType questionType;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
      questionType: QuizQuestionType.values.firstWhere(
        (e) => e.name == json['questionType'],
        orElse: () => QuizQuestionType.multipleChoice,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'questionType': questionType.name,
    };
  }
}

class AfghanCulturalTradition {
  const AfghanCulturalTradition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.region,
    required this.significance,
    required this.practices,
    required this.modernAdaptation,
    this.images,
    this.videos,
    this.relatedVerses,
    this.relatedHadiths,
  });

  final String id;
  final String name;
  final String description;
  final CulturalCategory category;
  final String region;
  final String significance;
  final List<String> practices;
  final String modernAdaptation;
  final List<ContentImage>? images;
  final List<ContentVideo>? videos;
  final List<String>? relatedVerses;
  final List<String>? relatedHadiths;

  factory AfghanCulturalTradition.fromJson(Map<String, dynamic> json) {
    return AfghanCulturalTradition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: CulturalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CulturalCategory.wedding,
      ),
      region: json['region'] as String,
      significance: json['significance'] as String,
      practices: (json['practices'] as List<dynamic>).cast<String>(),
      modernAdaptation: json['modernAdaptation'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ContentImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => ContentVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedVerses: (json['relatedVerses'] as List<dynamic>?)?.cast<String>() ?? [],
      relatedHadiths: (json['relatedHadiths'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'region': region,
      'significance': significance,
      'practices': practices,
      'modernAdaptation': modernAdaptation,
      'images': images?.map((e) => e.toJson()).toList(),
      'videos': videos?.map((e) => e.toJson()).toList(),
      'relatedVerses': relatedVerses,
      'relatedHadiths': relatedHadiths,
    };
  }
}

// Enums
enum EducationCategory {
  marriagePrinciples,
  quranicGuidance,
  propheticTeachings,
  afghanCulture,
  familyLife,
  communication,
  conflictResolution,
  financialManagement,
  parenting,
  general,
}

enum EducationContentType {
  article,
  interactiveModule,
  videoCourse,
  ebook,
  infographic,
  podcast,
  webinar,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

enum SectionContentType {
  text,
  image,
  video,
  interactive,
  quiz,
  reflection,
}

enum HadithSource {
  bukhari,
  muslim,
  abuDawud,
  tirmidhi,
  nasai,
  ibnMajah,
  malik,
  ahmad,
}

enum AuthenticityGrade {
  sahih, // Authentic
  hasan, // Good
  daif, // Weak
  mawdu, // Fabricated
}

enum QuizQuestionType {
  multipleChoice,
  trueFalse,
  fillInBlank,
  matching,
  essay,
}

enum CulturalCategory {
  wedding,
  engagement,
  family,
  social,
  religious,
  seasonal,
  culinary,
  artistic,
}
