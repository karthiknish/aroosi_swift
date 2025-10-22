import 'package:uuid/uuid.dart';
import 'models.dart';

class IslamicEducationalContentData {
  static const Uuid _uuid = Uuid();

  static List<IslamicEducationalContent> getInitialContent() {
    return [
      // Islamic Marriage Principles
      _createMarriagePrinciplesContent(),
      _createRightsAndResponsibilitiesContent(),
      _createIslamicFamilyValuesContent(),
      
      // Quranic Guidance
      _createQuranicMarriageVersesContent(),
      _createQuranicFamilyGuidanceContent(),
      
      // Prophetic Teachings
      _createPropheticMarriageTeachingsContent(),
      _createPropheticFamilyLifeContent(),
      
      // Afghan Cultural Traditions
      _createAfghanWeddingTraditionsContent(),
      _createAfghanEngagementCustomsContent(),
      _createAfghanFamilyValuesContent(),
      
      // Communication & Relationships
      _createIslamicCommunicationContent(),
      _createConflictResolutionContent(),
      
      // Financial Management
      _createIslamicFinanceContent(),
      _createMahrAndMarriageCostsContent(),
      
      // Parenting
      _createIslamicParentingContent(),
      _createChildUpbringingContent(),
    ];
  }

  static List<AfghanCulturalTradition> getAfghanTraditions() {
    return [
      _createNikahCeremony(),
      _createAfghaniWedding(),
      _createEngagementParty(),
      _createMehndiCeremony(),
      _createFamilyGatherings(),
      _createRamadanTraditions(),
      _createEidCelebrations(),
    ];
  }

  static IslamicEducationalContent _createMarriagePrinciplesContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Foundations of Islamic Marriage',
      description: 'Understanding the core principles and objectives of marriage in Islam',
      category: EducationCategory.marriagePrinciples,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Introduction to Islamic Marriage',
            content: '''Marriage in Islam (Nikah) is a sacred contract between two individuals, built on mutual consent, love, and commitment. It is considered half of one's faith and the foundation of Muslim society.

The Prophet Muhammad (peace be upon him) said: "When a man marries, he has completed half of his religion, so let him fear Allah regarding the remaining half."

This guide will help you understand the fundamental principles that make an Islamic marriage successful and blessed.''',
            order: 1,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Key Objectives of Marriage',
            content: '''1. **Spiritual Growth**: Marriage helps both spouses grow spiritually by supporting each other in religious obligations.

2. **Procreation**: Continuing the human race and raising righteous children who worship Allah.

3. **Chastity and Protection**: Preserving modesty and protecting oneself from sinful behavior.

4. **Companionship**: Finding emotional support, comfort, and partnership in life's journey.

5. **Social Stability**: Building strong families that contribute to a stable society.''',
            order: 2,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Essential Conditions for Valid Marriage',
            content: '''1. **Mutual Consent**: Both the bride and groom must willingly agree to the marriage.

2. **Wali (Guardian)**: The bride must have a male guardian (father, brother, or other male relative) approve the marriage.

3. **Mahr (Dowry)**: The groom must provide a gift to the bride as a sign of commitment.

4. **Witnesses**: At least two male witnesses must be present during the marriage contract.

5. **Public Announcement**: The marriage should be made known to avoid secrecy and doubt.''',
            order: 3,
          ),
        ],
        quranicVerses: [
          QuranicVerse(
            surahNumber: 30,
            ayahNumber: 21,
            arabicText: 'وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا لِّتَسْكُنُوا إِلَيْهَا وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً ۚ إِنَّ فِي ذَٰلِكَ لَآيَاتٍ لِّقَوْمٍ يَتَفَكَّرُونَ',
            englishTranslation: 'And among His signs is that He created for you from yourselves mates that you may find tranquility in them; and He placed between you affection and mercy. Indeed in that are signs for a people who give thought.',
            transliteration: 'Wa min ayatihi an khalaqa lakum min anfusikum azwajan litaskunu ilayha waja\'ala baynakum mawwatan wa rahmah. Inna fi thalika la ayatin li qawmin yatafakkarun.',
            relevanceToMarriage: 'This verse establishes marriage as a divine sign meant to bring tranquility, affection, and mercy between spouses.',
          ),
        ],
        hadiths: [
          Hadith(
            id: _uuid.v4(),
            arabicText: 'إِذَا تَزَوَّجَ أَحَدُكُمُ امْرَأَةً أَوِ اشْتَرَى خَادِمًا فَلْيَأْخُذْ بِنَاصِيَتِهَا وَلْيُسَمِّ اللَّهَ عَزَّ وَجَلَّ وَلْيَقُلْ: اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَخَيْرَ مَا جَبَلْتَهَا عَلَيْهِ وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَشَرِّ مَا جَبَلْتَهَا عَلَيْهِ',
            englishTranslation: 'When one of you marries a woman or buys a servant, let him take hold of her forelock, mention Allah\'s name, and say: O Allah, I ask You for her good and the good of her nature, and I seek refuge in You from her evil and the evil of her nature.',
            source: HadithSource.abuDawud,
            narrator: 'Abu Hurairah',
            authenticityGrade: AuthenticityGrade.hasan,
            relevanceToMarriage: 'This hadith teaches the importance of seeking Allah\'s blessing when entering marriage.',
          ),
        ],
        keyTakeaways: [
          'Marriage is a sacred contract with spiritual significance',
          'Both spouses must consent to the marriage willingly',
          'Mahr is a mandatory gift from groom to bride',
          'Marriage provides spiritual, emotional, and social benefits',
          'Seeking Allah\'s blessing is essential in marriage',
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: 'Islamic Scholars',
      tags: ['marriage', 'nikah', 'islamic principles', 'family'],
      isFeatured: true,
      quiz: _createMarriagePrinciplesQuiz(),
    );
  }

  static IslamicEducationalContent _createRightsAndResponsibilitiesContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Rights and Responsibilities in Islamic Marriage',
      description: 'Understanding the mutual rights and duties of husband and wife in Islam',
      category: EducationCategory.marriagePrinciples,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Introduction to Spousal Rights',
            content: '''Islam establishes a balanced system of rights and responsibilities for both husband and wife. These are not meant to create competition but to ensure harmony, justice, and mutual respect in the marital relationship.

Both partners have equal spiritual status before Allah, and their rights complement each other to create a peaceful home environment.''',
            order: 1,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Wife\'s Rights',
            content: '''1. **Mahr (Dowry)**: A gift from the husband that becomes her exclusive property.

2. **Financial Support (Nafaqah)**: The husband must provide for all her basic needs including food, clothing, shelter, and medical care.

3. **Kind Treatment**: The husband must treat his wife with kindness, respect, and compassion.

4. **Privacy**: Her privacy and honor must be protected at all times.

5. **Education**: The right to seek religious and worldly education.

6. **Consent**: She has the right to consent to matters affecting her life and body.''',
            order: 2,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Husband\'s Rights',
            content: '''1. **Obedience in Righteousness**: The wife should obey her husband in matters that are not disobedient to Allah.

2. **Respect and Honor**: He deserves respect and consideration as the leader of the household.

3. **Intimacy**: The right to marital intimacy within Islamic boundaries.

4. **Home Management**: The wife should manage the household affairs wisely.

5. **Protecting His Honor**: She should protect his reputation and family secrets.

6. **Gratitude**: Appreciating his efforts and provisions for the family.''',
            order: 3,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Mutual Responsibilities',
            content: '''1. **Religious Duties**: Both must support each other in fulfilling Islamic obligations.

2. **Raising Children**: Shared responsibility for Islamic upbringing of children.

3. **Conflict Resolution**: Addressing disagreements with wisdom and patience.

4. **Financial Responsibility**: Working together for family financial stability.

5. **Extended Family**: Maintaining good relations with both families.

6. **Personal Growth**: Supporting each other\'s personal and spiritual development.''',
            order: 4,
          ),
        ],
        quranicVerses: [
          QuranicVerse(
            surahNumber: 2,
            ayahNumber: 233,
            arabicText: 'وَالْوَالِدَاتُ يُرْضِعْنَ أَوْلَادَهُنَّ حَوْلَيْنِ كَامِلَيْنِ ۖ لِمَنْ أَرَادَ أَن يُتِمَّ الرَّضَاعَةَ ۚ وَعَلَى الْمَوْلُودِ لَهُ رِزْقُهُنَّ وَكِسْوَتُهُنَّ بِالْمَعْرُوفِ ۚ لَا تُكَلَّفُ نَفْسٌ إِلَّا وُسْعَهَا ۚ لَا تُضَارَّ وَالِدَةٌ بِوَلَدِهَا وَلَا مَوْلُودٌ لَّهُ بِوَلَدِهِ ۚ وَعَلَى الْوَارِثِ مِثْلُ ذَٰلِكَ',
            englishTranslation: 'Mothers may breastfeed their children two complete years for whoever wishes to complete the nursing. Upon the father is their provision and their clothing according to what is acceptable. No person is charged with more than he can bear. No mother should be harmed through her child, and no father through his child.',
            transliteration: 'Walwalidatu yurdi\'na awladahunna hawlayni kamilayni liman arada an yutimma rida\'ah. Wa ala almawuloodihi rizquhunna wa kiswatuhunna bilma\'roof. La tukallafu nafsun illa wus\'aha. La tudarru walidatun biwaladiha wala mawooloodun lahu biwaladih. Wa ala alwarithi mithlu thalik.',
            relevanceToMarriage: 'This verse establishes the financial responsibility of fathers and outlines the rights and responsibilities regarding child-rearing.',
          ),
        ],
        hadiths: [
          Hadith(
            id: _uuid.v4(),
            arabicText: 'خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ، وَأَنَا خَيْرُكُمْ لِأَهْلِي',
            englishTranslation: 'The best of you is the one who is best to his family, and I am the best of you to my family.',
            source: HadithSource.tirmidhi,
            narrator: 'Aisha',
            authenticityGrade: AuthenticityGrade.sahih,
            relevanceToMarriage: 'This hadith emphasizes the importance of good treatment toward family members as a measure of a person\'s excellence.',
          ),
        ],
        keyTakeaways: [
          'Both husband and wife have specific rights in Islam',
          'Financial responsibility primarily lies with the husband',
          'Mutual respect and kindness are mandatory',
          'Both partners share responsibilities in child-rearing',
          'Rights come with corresponding responsibilities',
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: 'Islamic Family Experts',
      tags: ['rights', 'responsibilities', 'husband', 'wife', 'marriage'],
      quiz: _createRightsAndResponsibilitiesQuiz(),
    );
  }

  static IslamicEducationalContent _createQuranicMarriageVersesContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Quranic Guidance on Marriage',
      description: 'Essential Quranic verses about marriage, family, and relationships',
      category: EducationCategory.quranicGuidance,
      contentType: EducationContentType.interactiveModule,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Divine Purpose of Marriage',
            content: '''The Quran presents marriage as a divine institution created to bring peace, tranquility, and mutual compassion between partners. These verses reveal the wisdom and purpose behind this sacred union.

Each verse provides guidance on different aspects of marriage - from finding the right partner to maintaining a harmonious relationship.''',
            order: 1,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Key Marriage Verses',
            content: '''**1. The Sign of Marriage (Surah Ar-Rum 30:21)**
"And among His signs is that He created for you from yourselves mates that you may find tranquility in them; and He placed between you affection and mercy."

**2. Spousal Garments (Surah Al-Baqarah 2:187)**
"They are clothing for you and you are clothing for them."

**3. Justice and Kindness (Surah An-Nisa 4:19)**
"Live with them in kindness. For if you dislike them - perhaps you dislike a thing and Allah makes therein much good."

**4. Divine Guidance (Surah Ar-Rum 30:21)**
"And of His signs is that He created for you from yourselves mates that you may find tranquility in them."''',
            order: 2,
          ),
        ],
        quranicVerses: [
          QuranicVerse(
            surahNumber: 4,
            ayahNumber: 1,
            arabicText: 'يَا أَيُّهَا النَّاسُ اتَّقُوا رَبَّكُمُ الَّذِي خَلَقَكُم مِّن نَّفْسٍ وَاحِدَةٍ وَخَلَقَ مِنْهَا زَوْجَهَا وَبَثَّ مِنْهُمَا رِجَالًا كَثِيرًا وَنِسَاءً',
            englishTranslation: 'O mankind, fear your Lord, who created you from one soul and created from it its mate and dispersed from both of them many men and women.',
            transliteration: 'Ya ayyuhan nasu itaqu rabbakum allathi khalaqakum min nafsin wahidatin wa khalaqa minha zawjaha wa batha minhuma rijalan katheeran wa nisa\'an.',
            relevanceToMarriage: 'This verse establishes the origin of all humanity from a single soul, emphasizing the unity of mankind and the sacred bond between spouses.',
          ),
          QuranicVerse(
            surahNumber: 16,
            ayahNumber: 72,
            arabicText: 'وَاللَّهُ جَعَلَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا وَجَعَلَ لَكُم مِّنْ أَزْوَاجِكُم بَنِينَ وَحَفَدَةً',
            englishTranslation: 'And Allah has made for you from yourselves mates and has made for you from your mates sons and grandchildren.',
            transliteration: 'Wallahu ja\'ala lakum min anfusikum azwajan wa ja\'ala lakum min azwajikum banina wa hafadah.',
            relevanceToMarriage: 'This verse highlights marriage as a divine blessing that leads to the continuation of family through children and grandchildren.',
          ),
        ],
        keyTakeaways: [
          'Marriage is a divine sign from Allah',
          'Spouses are described as garments for each other',
          'Justice and kindness are mandatory in marital relations',
          'Tranquility and mercy are key outcomes of proper marriage',
          'The Quran emphasizes the spiritual dimension of marriage',
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: 'Quranic Scholars',
      tags: ['quran', 'verses', 'marriage', 'divine guidance'],
      isFeatured: true,
      quiz: _createQuranicVersesQuiz(),
    );
  }

  static IslamicEducationalContent _createAfghanWeddingTraditionsContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Afghan Wedding Traditions and Customs',
      description: 'Explore the rich cultural heritage of Afghan wedding ceremonies and their Islamic significance',
      category: EducationCategory.afghanCulture,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Introduction to Afghan Weddings',
            content: '''Afghan weddings are beautiful celebrations that blend Islamic traditions with rich cultural customs. These ceremonies reflect the deep-rooted values of Afghan society while maintaining religious compliance.

Traditional Afghan weddings typically span several days and involve various ceremonies that bring families and communities together in joyous celebration.''',
            order: 1,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Pre-Wedding Ceremonies',
            content: '''**1. Mangni (Engagement)**
- Formal proposal and acceptance between families
- Exchange of gifts and sweets
- Setting of the wedding date

**2. Henna Night (Mehndi)**
- Application of henna designs to bride\'s hands and feet
- Female family members gather for celebration
- Songs, dances, and traditional foods

**3. Ahesta Boro (Bridal Procession)**
- Traditional song sung as the bride prepares
- Symbolizes the bride\'s transition to married life
            ''',
            order: 2,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'The Wedding Day',
            content: '''**1. Nikah Ceremony**
- Islamic marriage contract signed by both parties
- Imam officiates the religious ceremony
- Mahr (dowry) is formally announced

**2. Aina Musaf (Mirror Ceremony)**
- Bride and groom see each other through a mirror
- Symbolizes seeing their future together
- Quran is placed between them for blessings

**3. Wedding Feast (Walima)**
- Elaborate celebration with traditional Afghan cuisine
- Family and friends gather to celebrate
- Music, dancing, and cultural performances''',
            order: 3,
          ),
          ContentSection(
            id: _uuid.v4(),
            title: 'Regional Variations',
            content: '''Different regions of Afghanistan have unique wedding customs:

**Kabul Style**: More modern with mixed-gender celebrations
**Kandahar Style**: Traditional with gender-segregated events
**Hazaragi Weddings**: Include specific cultural rituals and foods
**Nuristani Traditions**: Unique customs reflecting local heritage

Each variation maintains Islamic principles while celebrating cultural diversity.''',
            order: 4,
          ),
        ],
        keyTakeaways: [
          'Afghan weddings blend Islamic and cultural traditions',
          'Multiple ceremonies lead up to the main wedding day',
          'The Nikah ceremony is the religious core of the marriage',
          'Regional variations reflect Afghanistan\'s diverse heritage',
          'Family involvement is central to Afghan wedding traditions',
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: 'Cultural Experts',
      tags: ['afghan', 'wedding', 'traditions', 'culture', 'ceremony'],
      quiz: _createAfghanWeddingQuiz(),
    );
  }

  static EducationalQuiz _createMarriagePrinciplesQuiz() {
    return EducationalQuiz(
      id: _uuid.v4(),
      title: 'Islamic Marriage Principles Quiz',
      questions: [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is the Arabic term for Islamic marriage?',
          options: ['Nikah', 'Walima', 'Mahr', 'Zawaj'],
          correctAnswer: 'Nikah',
          explanation: 'Nikah is the Arabic term for the Islamic marriage contract. Walima is the wedding feast, Mahr is the dowry, and Zawaj generally means marriage.',
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'How much of religion is completed when one gets married according to the hadith?',
          options: ['One-third', 'Half', 'Two-thirds', 'All of it'],
          correctAnswer: 'Half',
          explanation: 'The Prophet Muhammad (peace be upon him) said that marriage completes half of one\'s religion, emphasizing its importance.',
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Which of these is NOT a condition for a valid Islamic marriage?',
          options: ['Mutual consent', 'Mahr (dowry)', 'Love at first sight', 'Witnesses'],
          correctAnswer: 'Love at first sight',
          explanation: 'While love is desirable, it\'s not a condition for valid marriage. The essential conditions are mutual consent, wali, mahr, and witnesses.',
        ),
      ],
      passingScore: 0.7,
      timeLimit: 10,
    );
  }

  static EducationalQuiz _createRightsAndResponsibilitiesQuiz() {
    return EducationalQuiz(
      id: _uuid.v4(),
      title: 'Rights and Responsibilities Quiz',
      questions: [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Who is primarily responsible for financial support in an Islamic marriage?',
          options: ['Wife', 'Husband', 'Both equally', 'Parents'],
          correctAnswer: 'Husband',
          explanation: 'The husband is primarily responsible for providing financial support (nafaqah) for the wife and family in Islamic marriage.',
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What term describes the mandatory gift from groom to bride in Islamic marriage?',
          options: ['Sadaqah', 'Zakat', 'Mahr', 'Inheritance'],
          correctAnswer: 'Mahr',
          explanation: 'Mahr is the mandatory gift/dowry that the groom must give to the bride, which becomes her exclusive property.',
        ),
      ],
      passingScore: 0.8,
      timeLimit: 8,
    );
  }

  static EducationalQuiz _createQuranicVersesQuiz() {
    return EducationalQuiz(
      id: _uuid.v4(),
      title: 'Quranic Marriage Verses Quiz',
      questions: [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'Which Surah contains the verse "And among His signs is that He created for you from yourselves mates"?',
          options: ['Al-Baqarah', 'Ar-Rum', 'An-Nisa', 'Al-Furqan'],
          correctAnswer: 'Ar-Rum',
          explanation: 'This famous verse about marriage is found in Surah Ar-Rum, chapter 30, verse 21.',
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'In the Quran, spouses are described as what for each other?',
          options: ['Shields', 'Garments', 'Pillars', 'Lights'],
          correctAnswer: 'Garments',
          explanation: 'Surah Al-Baqarah 2:187 describes spouses as garments for each other, symbolizing protection, beautification, and intimacy.',
        ),
      ],
      passingScore: 0.75,
      timeLimit: 12,
    );
  }

  static EducationalQuiz _createAfghanWeddingQuiz() {
    return EducationalQuiz(
      id: _uuid.v4(),
      title: 'Afghan Wedding Traditions Quiz',
      questions: [
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is the traditional Afghan henna ceremony called?',
          options: ['Mangni', 'Mehndi', 'Ahesta Boro', 'Aina Musaf'],
          correctAnswer: 'Mehndi',
          explanation: 'Mehndi is the traditional henna ceremony held before the wedding where intricate designs are applied to the bride\'s hands and feet.',
        ),
        QuizQuestion(
          id: _uuid.v4(),
          question: 'What is the Aina Musaf ceremony in Afghan weddings?',
          options: ['Engagement ceremony', 'Mirror ceremony where bride and groom see each other', 'Henna application', 'Wedding feast'],
          correctAnswer: 'Mirror ceremony where bride and groom see each other',
          explanation: 'Aina Musaf is the mirror ceremony where the bride and groom see each other through a mirror for the first time after the religious ceremony.',
        ),
      ],
      passingScore: 0.7,
      timeLimit: 8,
    );
  }

  // Afghan Cultural Traditions
  static AfghanCulturalTradition _createNikahCeremony() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Afghan Nikah Ceremony',
      description: 'The traditional Islamic marriage contract ceremony in Afghan culture',
      category: CulturalCategory.wedding,
      region: 'Throughout Afghanistan',
      significance: 'The Nikah is the religious and legal foundation of marriage in Afghan culture, combining Islamic requirements with local customs.',
      practices: [
        'Islamic marriage contract signing by both parties',
        'Imam or religious scholar officiates the ceremony',
        'Two male witnesses required',
        'Mahr (dowry) announcement and agreement',
        'Prayers and blessings for the couple',
        'Family participation and approval',
      ],
      modernAdaptation: 'Modern Afghan Nikah ceremonies may include written contracts, pre-marital counseling, and sometimes joint celebrations while maintaining religious requirements.',
      relatedVerses: ['30:21', '4:1'],
      relatedHadiths: ['hadith_nikah_importance'],
    );
  }

  static AfghanCulturalTradition _createAfghaniWedding() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Afghani Wedding Celebration',
      description: 'The elaborate multi-day wedding celebration following Islamic principles',
      category: CulturalCategory.wedding,
      region: 'Throughout Afghanistan with regional variations',
      significance: 'Weddings are major community events that celebrate family honor, cultural heritage, and religious values.',
      practices: [
        'Pre-wedding engagement ceremonies',
        'Henna night celebrations',
        'Traditional wedding attire and jewelry',
        'Islamic marriage contract ceremony',
        'Wedding feast (Walima)',
        'Traditional music and dance performances',
        'Family blessing rituals',
      ],
      modernAdaptation: 'Modern Afghan weddings often incorporate contemporary elements while preserving traditional rituals, with some couples having gender-mixed celebrations.',
      relatedVerses: ['30:21', '24:32'],
      relatedHadiths: ['hadith_walima'],
    );
  }

  // Add more content methods as needed...
  static IslamicEducationalContent _createIslamicFamilyValuesContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Islamic Family Values',
      description: 'Core Islamic values that strengthen family bonds',
      category: EducationCategory.familyLife,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Core Family Values in Islam',
            content: '''Islamic family values are based on love, mercy, justice, and mutual respect. These values create a nurturing environment where both spouses and children can flourish spiritually and emotionally.

The family is considered the cornerstone of Islamic society, and maintaining strong family ties is emphasized throughout the Quran and Sunnah.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 8,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['family', 'values', 'islamic', 'relationships'],
    );
  }

  static IslamicEducationalContent _createPropheticMarriageTeachingsContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Prophetic Teachings on Marriage',
      description: 'Lessons from the Prophet Muhammad\'s marriages and guidance',
      category: EducationCategory.propheticTeachings,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'The Prophet as a Role Model',
            content: '''The Prophet Muhammad (peace be upon him) demonstrated ideal marriage conduct through his own relationships with his wives. His teachings provide practical guidance for maintaining happy and successful marriages.

His marriages were based on mutual respect, love, and partnership in spreading the message of Islam.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['prophet', 'marriage', 'sunnah', 'teachings'],
    );
  }

  static IslamicEducationalContent _createPropheticFamilyLifeContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Prophetic Family Life',
      description: 'Insights into the Prophet\'s family life and relationships',
      category: EducationCategory.propheticTeachings,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Family Life of the Prophet',
            content: '''The Prophet Muhammad (peace be upon him) balanced his role as a messenger with his family responsibilities. He was known to be kind, helpful, and loving toward his family members.

His example shows the importance of maintaining strong family bonds while fulfilling religious and social duties.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['prophet', 'family', 'sunnah', 'home'],
    );
  }

  static IslamicEducationalContent _createAfghanEngagementCustomsContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Afghan Engagement Customs',
      description: 'Traditional Afghan engagement ceremonies and their significance',
      category: EducationCategory.afghanCulture,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Mangni - Afghan Engagement',
            content: '''The Afghan engagement, known as Mangni, is a formal agreement between two families that precedes the wedding. It involves traditional customs that strengthen family bonds and prepare for the upcoming marriage.

The ceremony includes exchange of gifts, setting the wedding date, and formal acceptance between families.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 8,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['afghan', 'engagement', 'mangni', 'customs'],
    );
  }

  static IslamicEducationalContent _createAfghanFamilyValuesContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Afghan Family Values',
      description: 'Traditional Afghan family values and their Islamic foundations',
      category: EducationCategory.afghanCulture,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Core Afghan Family Values',
            content: '''Afghan family values are deeply rooted in Islamic teachings and tribal traditions. These values emphasize respect for elders, strong family bonds, hospitality, and community support.

The family unit plays a central role in Afghan society, with extended families often living together or maintaining close relationships.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['afghan', 'family', 'values', 'traditions'],
    );
  }

  static IslamicEducationalContent _createIslamicCommunicationContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Islamic Communication in Marriage',
      description: 'Principles of effective communication from an Islamic perspective',
      category: EducationCategory.communication,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Communication in Islamic Marriage',
            content: '''Effective communication is essential for a successful Islamic marriage. Islam emphasizes honesty, kindness, and wisdom in speech between spouses.

The Prophet Muhammad (peace be upon him) provided guidance on how couples should communicate respectfully and resolve conflicts through dialogue rather than confrontation.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['communication', 'marriage', 'islamic', 'dialogue'],
    );
  }

  static IslamicEducationalContent _createConflictResolutionContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Islamic Conflict Resolution',
      description: 'Resolving marital conflicts according to Islamic principles',
      category: EducationCategory.conflictResolution,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Conflict Resolution in Islam',
            content: '''Islam provides a comprehensive framework for resolving conflicts in marriage through patience, forgiveness, and mutual understanding. The Quran and Sunnah offer practical guidance for couples facing disagreements.

The goal is not to win arguments but to maintain harmony and strengthen the marital bond.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['conflict', 'resolution', 'marriage', 'islamic'],
    );
  }

  static IslamicEducationalContent _createIslamicFinanceContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Islamic Finance in Marriage',
      description: 'Managing finances according to Islamic principles in marriage',
      category: EducationCategory.financialManagement,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Financial Management in Islamic Marriage',
            content: '''Islamic finance in marriage emphasizes fairness, transparency, and avoiding interest-based transactions. Couples are encouraged to manage their wealth according to Sharia principles.

This includes proper budgeting, charitable giving, and investments that comply with Islamic guidelines.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['finance', 'islamic', 'marriage', 'money'],
    );
  }

  static IslamicEducationalContent _createMahrAndMarriageCostsContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Mahr and Marriage Costs',
      description: 'Understanding Mahr and managing wedding expenses Islamically',
      category: EducationCategory.financialManagement,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Mahr and Wedding Expenses',
            content: '''Mahr is a mandatory gift from the groom to the bride in Islamic marriage. Wedding expenses should be managed according to Islamic principles, avoiding extravagance and debt.

Islam encourages simplicity in wedding celebrations while maintaining the joy and significance of the occasion.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['mahr', 'wedding', 'costs', 'islamic'],
    );
  }

  static IslamicEducationalContent _createIslamicParentingContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Islamic Parenting Principles',
      description: 'Raising children according to Islamic teachings and values',
      category: EducationCategory.parenting,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Principles of Islamic Parenting',
            content: '''Islamic parenting is based on love, guidance, and religious education. Parents are responsible for teaching their children Islamic values, Quran, and the example of the Prophet Muhammad (peace be upon him).

The goal is to raise righteous children who will benefit society and contribute positively to the Muslim community.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['parenting', 'islamic', 'children', 'upbringing'],
    );
  }

  static IslamicEducationalContent _createChildUpbringingContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Child Upbringing in Islam',
      description: 'Comprehensive guide to raising children according to Islamic principles',
      category: EducationCategory.parenting,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Islamic Child Upbringing',
            content: '''Raising children in Islam involves providing spiritual, moral, and practical guidance. Parents must balance discipline with love and teach Islamic values through example and instruction.

The Prophet Muhammad (peace be upon him) emphasized the importance of treating children with kindness and educating them properly.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.intermediate,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['children', 'upbringing', 'islamic', 'education'],
    );
  }

  static IslamicEducationalContent _createQuranicFamilyGuidanceContent() {
    return IslamicEducationalContent(
      id: _uuid.v4(),
      title: 'Quranic Family Guidance',
      description: 'Quranic verses about family life and relationships',
      category: EducationCategory.quranicGuidance,
      contentType: EducationContentType.article,
      content: EducationContent(
        sections: [
          ContentSection(
            id: _uuid.v4(),
            title: 'Family Life in the Quran',
            content: '''The Quran provides comprehensive guidance on all aspects of family life, including marriage, parenting, and relationships with extended family. These verses establish the framework for happy and successful families according to divine wisdom.

Understanding and implementing these teachings leads to harmonious family relationships and spiritual growth.''',
            order: 1,
          ),
        ],
      ),
      difficultyLevel: DifficultyLevel.beginner,
      estimatedReadTime: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['quran', 'family', 'guidance', 'verses'],
    );
  }

  // Additional Afghan Traditions
  static AfghanCulturalTradition _createEngagementParty() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Engagement Party (Mangni)',
      description: 'Traditional Afghan engagement ceremony',
      category: CulturalCategory.engagement,
      region: 'Throughout Afghanistan',
      significance: 'Formal agreement between families with celebration and gift exchange',
      practices: [
        'Formal proposal acceptance',
        'Exchange of rings and gifts',
        'Traditional Afghan sweets and tea',
        'Family speeches and blessings',
        'Setting wedding date',
      ],
      modernAdaptation: 'Modern engagement parties may include photography, mixed gatherings, and contemporary elements while preserving traditional customs.',
    );
  }

  static AfghanCulturalTradition _createMehndiCeremony() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Mehndi Night',
      description: 'Traditional henna ceremony before wedding',
      category: CulturalCategory.wedding,
      region: 'Throughout Afghanistan',
      significance: 'Celebration of beauty and joy before the wedding day',
      practices: [
        'Application of henna designs',
        'Female family gathering',
        'Traditional songs and dances',
        'Sweet distribution',
        'Blessings for the bride',
      ],
      modernAdaptation: 'Modern Mehndi nights may include professional henna artists, DJs, and elaborate themes while maintaining traditional elements.',
    );
  }

  static AfghanCulturalTradition _createFamilyGatherings() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Afghan Family Gatherings',
      description: 'Regular family meetings and celebrations',
      category: CulturalCategory.family,
      region: 'Throughout Afghanistan',
      significance: 'Maintaining strong family bonds and cultural traditions',
      practices: [
        'Weekly family meals',
        'Holiday celebrations',
        'Elders\' wisdom sharing',
        'Children\'s participation',
        'Traditional food preparation',
      ],
      modernAdaptation: 'Modern family gatherings may include video calls with distant relatives and updated menu options while preserving traditional values.',
    );
  }

  static AfghanCulturalTradition _createRamadanTraditions() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Ramadan Traditions',
      description: 'Afghan customs during the holy month of Ramadan',
      category: CulturalCategory.religious,
      region: 'Throughout Afghanistan',
      significance: 'Spiritual reflection, fasting, and community bonding',
      practices: [
        'Suhoor and Iftar meals',
        'Taraweeh prayers',
        'Quran recitation',
        'Charitable giving',
        'Family Iftar gatherings',
      ],
      modernAdaptation: 'Modern Ramadan traditions include online lectures, charitable apps, and community iftars while maintaining spiritual focus.',
    );
  }

  static AfghanCulturalTradition _createEidCelebrations() {
    return AfghanCulturalTradition(
      id: _uuid.v4(),
      name: 'Eid Celebrations',
      description: 'Afghan Eid traditions and festivities',
      category: CulturalCategory.religious,
      region: 'Throughout Afghanistan',
      significance: 'Celebration of religious festivals with family and community',
      practices: [
        'Eid prayers',
        'New clothes and gifts',
        'Family visits',
        'Traditional sweets',
        'Charitable giving',
        'Children\'s entertainment',
      ],
      modernAdaptation: 'Modern Eid celebrations include social media greetings, virtual family connections, and community events while preserving religious significance.',
    );
  }
}
