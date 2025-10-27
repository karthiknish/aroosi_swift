import Foundation
import FirebaseFirestore

#if canImport(FirebaseFirestore)

@available(iOS 17, *)
public final class IslamicQuizUploadService {
    private let db = Firestore.firestore()
    private let logger = Logger.shared
    
    public init() {
        logger.info("[IslamicQuizUploadService] Initialized")
    }
    
    // MARK: - Quiz Upload Methods
    
    public func uploadSampleQuizzes() async throws {
        logger.info("Starting upload of sample Islamic quizzes...")
        
        let sampleQuizzes = createSampleQuizzes()
        
        for quiz in sampleQuizzes {
            try await uploadQuiz(quiz)
            logger.info("Uploaded quiz: \(quiz.title)")
        }
        
        logger.info("Successfully uploaded \(sampleQuizzes.count) sample quizzes")
    }
    
    public func uploadQuiz(_ quiz: IslamicQuiz) async throws {
        let quizRef = db.collection("islamic_quizzes").document(quiz.id)
        
        let quizData: [String: Any] = [
            "id": quiz.id,
            "title": quiz.title,
            "description": quiz.description,
            "category": quiz.category.rawValue,
            "difficulty": quiz.difficulty.rawValue,
            "questions": quiz.questions.map { question in
                [
                    "id": question.id,
                    "question": question.question,
                    "options": question.options,
                    "correctAnswerIndex": question.correctAnswerIndex,
                    "explanation": question.explanation ?? "",
                    "reference": question.reference ?? "",
                    "category": question.category.rawValue,
                    "difficulty": question.difficulty.rawValue,
                    "arabicText": question.arabicText ?? "",
                    "transliteration": question.transliteration ?? ""
                ]
            },
            "timeLimit": quiz.timeLimit ?? NSNull(),
            "passingScore": quiz.passingScore,
            "createdAt": Timestamp(date: quiz.createdAt),
            "updatedAt": Timestamp(date: quiz.updatedAt),
            "isActive": quiz.isActive,
            "isFeatured": true,
            "featuredOrder": 0
        ]
        
        try await quizRef.setData(quizData)
        logger.info("Quiz uploaded successfully: \(quiz.title)")
    }
    
    public func uploadQuizCategory(_ category: QuizCategory, quizzes: [IslamicQuiz]) async throws {
        logger.info("Uploading \(quizzes.count) quizzes for category: \(category.displayName)")
        
        for quiz in quizzes {
            try await uploadQuiz(quiz)
        }
        
        logger.info("Completed upload for category: \(category.displayName)")
    }
    
    // MARK: - Sample Quiz Data
    
    private func createSampleQuizzes() -> [IslamicQuiz] {
        return [
            createQuranBasicsQuiz(),
            createPillarsOfIslamQuiz(),
            createProphetStoriesQuiz(),
            createIslamicEtiquetteQuiz(),
            createPrayerBasicsQuiz(),
            createZakatQuiz(),
            createFastingQuiz(),
            createHajjQuiz(),
            createProphetCompanionsQuiz(),
            createIslamicNamesQuiz()
        ]
    }
    
    private func createQuranBasicsQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Quran Basics",
            description: "Test your knowledge about the Holy Quran, its structure, and basic teachings",
            category: .quran,
            difficulty: .beginner,
            questions: [
                IslamicQuizQuestion(
                    question: "How many chapters (Surahs) are there in the Holy Quran?",
                    options: ["114", "99", "30", "66"],
                    correctAnswerIndex: 0,
                    explanation: "The Holy Quran contains 114 chapters (Surahs), starting with Al-Fatiha and ending with An-Nas.",
                    reference: "Quranic Structure",
                    category: .quran,
                    difficulty: .beginner,
                    arabicText: "١١٤ سورة في القرآن الكريم",
                    transliteration: "114 surah fil-qur'an al-karim"
                ),
                IslamicQuizQuestion(
                    question: "Which is the longest chapter in the Quran?",
                    options: ["Al-Baqarah", "Al-Imran", "Al-Fatiha", "Al-Ikhlas"],
                    correctAnswerIndex: 0,
                    explanation: "Surah Al-Baqarah (The Cow) is the longest chapter in the Quran with 286 verses.",
                    reference: "Quran 2:1-286",
                    category: .quran,
                    difficulty: .beginner,
                    arabicText: "سورة البقرة",
                    transliteration: "Surat Al-Baqarah"
                ),
                IslamicQuizQuestion(
                    question: "What does the word 'Quran' mean?",
                    options: ["Recitation", "Book", "Light", "Guidance"],
                    correctAnswerIndex: 0,
                    explanation: "The word 'Quran' comes from the Arabic root 'qara-a' which means 'to read' or 'to recite'.",
                    reference: "Etymology of Quran",
                    category: .quran,
                    difficulty: .beginner,
                    arabicText: "قرآن",
                    transliteration: "Qur'an"
                ),
                IslamicQuizQuestion(
                    question: "In which month was the Quran first revealed?",
                    options: ["Ramadan", "Muharram", "Dhul Hijjah", "Shawwal"],
                    correctAnswerIndex: 0,
                    explanation: "The Quran was first revealed in the month of Ramadan during Laylat al-Qadr (the Night of Power).",
                    reference: "Quran 2:185",
                    category: .quran,
                    difficulty: .beginner,
                    arabicText: "شهر رمضان",
                    transliteration: "Shahr Ramadan"
                ),
                IslamicQuizQuestion(
                    question: "Which chapter is known as 'The Mother of the Quran'?",
                    options: ["Al-Fatiha", "Al-Baqarah", "Al-Ikhlas", "Ayat al-Kursi"],
                    correctAnswerIndex: 0,
                    explanation: "Surah Al-Fatiha is called 'Umm al-Quran' (Mother of the Quran) as it summarizes the entire Quran's message.",
                    reference: "Quran 1:1-7",
                    category: .quran,
                    difficulty: .beginner,
                    arabicText: "أم القرآن",
                    transliteration: "Umm al-Qur'an"
                )
            ],
            timeLimit: 10,
            passingScore: 70
        )
    }
    
    private func createPillarsOfIslamQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Pillars of Islam",
            description: "Learn about the five fundamental pillars that form the foundation of Islamic faith",
            category: .aqidah,
            difficulty: .beginner,
            questions: [
                IslamicQuizQuestion(
                    question: "How many pillars does Islam have?",
                    options: ["5", "6", "4", "7"],
                    correctAnswerIndex: 0,
                    explanation: "Islam has five pillars that form the foundation of Muslim faith and practice.",
                    reference: "Hadith: 'Islam is built upon five'",
                    category: .aqidah,
                    difficulty: .beginner,
                    arabicText: "خمس أركان الإسلام",
                    transliteration: "Khams arkan al-Islam"
                ),
                IslamicQuizQuestion(
                    question: "Which pillar involves the declaration of faith?",
                    options: ["Shahada", "Salah", "Zakat", "Sawm"],
                    correctAnswerIndex: 0,
                    explanation: "The Shahada is the declaration of faith: 'There is no god but Allah, and Muhammad is His messenger.'",
                    reference: "Shahada: 'La ilaha illallah, Muhammadur rasulullah'",
                    category: .aqidah,
                    difficulty: .beginner,
                    arabicText: "الشهادة",
                    transliteration: "Ash-Shahada"
                ),
                IslamicQuizQuestion(
                    question: "How many times a day should Muslims perform Salah?",
                    options: ["5", "3", "7", "6"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims are required to perform five daily prayers: Fajr, Dhuhr, Asr, Maghrib, and Isha.",
                    reference: "Quran 11:114",
                    category: .aqidah,
                    difficulty: .beginner,
                    arabicText: "الصلوات الخمس",
                    transliteration: "As-salawat al-khams"
                ),
                IslamicQuizQuestion(
                    question: "What is the Arabic term for charity given to the poor?",
                    options: ["Zakat", "Sadaqah", "Waqf", "Hadiya"],
                    correctAnswerIndex: 0,
                    explanation: "Zakat is the obligatory charity that Muslims must give, typically 2.5% of their wealth annually.",
                    reference: "Quran 2:177",
                    category: .aqidah,
                    difficulty: .beginner,
                    arabicText: "الزكاة",
                    transliteration: "Az-Zakat"
                ),
                IslamicQuizQuestion(
                    question: "During which Islamic month do Muslims fast?",
                    options: ["Ramadan", "Muharram", "Dhul Hijjah", "Shaban"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims fast from dawn to sunset during the holy month of Ramadan.",
                    reference: "Quran 2:185",
                    category: .aqidah,
                    difficulty: .beginner,
                    arabicText: "صوم رمضان",
                    transliteration: "Sawm Ramadan"
                )
            ],
            timeLimit: 15,
            passingScore: 80
        )
    }
    
    private func createProphetStoriesQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Stories of the Prophets",
            description: "Test your knowledge about the prophets mentioned in the Quran and their stories",
            category: .prophets,
            difficulty: .intermediate,
            questions: [
                IslamicQuizQuestion(
                    question: "Which prophet is known as the 'Friend of God' (Khalilullah)?",
                    options: ["Abraham (Ibrahim)", "Moses (Musa)", "Jesus (Isa)", "Muhammad"],
                    correctAnswerIndex: 0,
                    explanation: "Prophet Abraham is called Khalilullah (Friend of God) due to his complete devotion and faith.",
                    reference: "Quran 4:125",
                    category: .prophets,
                    difficulty: .intermediate,
                    arabicText: "خليل الله",
                    transliteration: "Khalilullah"
                ),
                IslamicQuizQuestion(
                    question: "Which prophet could speak with animals and was given control over winds?",
                    options: ["Solomon (Sulaiman)", "David (Dawud)", "Joseph (Yusuf)", "Job (Ayub)"],
                    correctAnswerIndex: 0,
                    explanation: "Prophet Solomon was given control over winds, could understand animals, and ruled over jinns.",
                    reference: "Quran 21:81-82, 27:16-17",
                    category: .prophets,
                    difficulty: .intermediate,
                    arabicText: "سليمان",
                    transliteration: "Sulaiman"
                ),
                IslamicQuizQuestion(
                    question: "Which prophet was swallowed by a whale?",
                    options: ["Jonah (Yunus)", "Moses (Musa)", "Noah (Nuh)", "Abraham (Ibrahim)"],
                    correctAnswerIndex: 0,
                    explanation: "Prophet Jonah was swallowed by a whale after he fled from his mission to Nineveh.",
                    reference: "Quran 37:139-148",
                    category: .prophets,
                    difficulty: .intermediate,
                    arabicText: "يونس",
                    transliteration: "Yunus"
                ),
                IslamicQuizQuestion(
                    question: "Which prophet built the Ark?",
                    options: ["Noah (Nuh)", "Moses (Musa)", "Abraham (Ibrahim)", "Adam"],
                    correctAnswerIndex: 0,
                    explanation: "Prophet Noah built the Ark under God's command to save believers from the great flood.",
                    reference: "Quran 11:36-48",
                    category: .prophets,
                    difficulty: .intermediate,
                    arabicText: "نوح",
                    transliteration: "Nuh"
                ),
                IslamicQuizQuestion(
                    question: "Which prophet was known for his patience and suffered from a severe illness?",
                    options: ["Job (Ayub)", "Jacob (Yaqub)", "Joseph (Yusuf)", "Moses (Musa)"],
                    correctAnswerIndex: 0,
                    explanation: "Prophet Job is renowned for his extraordinary patience while enduring severe trials and illness.",
                    reference: "Quran 38:41-44",
                    category: .prophets,
                    difficulty: .intermediate,
                    arabicText: "أيوب",
                    transliteration: "Ayub"
                )
            ],
            timeLimit: 20,
            passingScore: 70
        )
    }
    
    private func createIslamicEtiquetteQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Islamic Etiquette & Manners",
            description: "Learn about proper Islamic manners and daily etiquette",
            category: .ethics,
            difficulty: .beginner,
            questions: [
                IslamicQuizQuestion(
                    question: "What should a Muslim say before eating?",
                    options: ["Bismillah", "Alhamdulillah", "Assalamu Alaikum", "Insha'Allah"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims should say 'Bismillah' (In the name of Allah) before eating.",
                    reference: "Hadith: 'When one of you eats, he should mention Allah's name'",
                    category: .ethics,
                    difficulty: .beginner,
                    arabicText: "بسم الله",
                    transliteration: "Bismillah"
                ),
                IslamicQuizQuestion(
                    question: "What should a Muslim say after eating?",
                    options: ["Alhamdulillah", "Bismillah", "Assalamu Alaikum", "JazakAllah"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims should say 'Alhamdulillah' (All praise is due to Allah) after eating.",
                    reference: "Hadith: 'Indeed, Allah is pleased with His servant who praises Him after eating'",
                    category: .ethics,
                    difficulty: .beginner,
                    arabicText: "الحمد لله",
                    transliteration: "Alhamdulillah"
                ),
                IslamicQuizQuestion(
                    question: "Which hand should be used for eating according to Islamic etiquette?",
                    options: ["Right hand", "Left hand", "Both hands", "Either hand"],
                    correctAnswerIndex: 0,
                    explanation: "The Prophet Muhammad (peace be upon him) taught Muslims to eat and drink with their right hand.",
                    reference: "Hadith: 'Eat with your right hand, drink with your right hand'",
                    category: .ethics,
                    difficulty: .beginner,
                    arabicText: "باليد اليمنى",
                    transliteration: "Bil-yad al-yumna"
                ),
                IslamicQuizQuestion(
                    question: "What is the Islamic greeting?",
                    options: ["Assalamu Alaikum", "Salam", "Marhaba", "Ahlan"],
                    correctAnswerIndex: 0,
                    explanation: "'Assalamu Alaikum' means 'Peace be upon you' and is the Islamic greeting.",
                    reference: "Quran 6:54",
                    category: .ethics,
                    difficulty: .beginner,
                    arabicText: "السلام عليكم",
                    transliteration: "As-salamu alaykum"
                ),
                IslamicQuizQuestion(
                    question: "What should be the response to 'Assalamu Alaikum'?",
                    options: ["Wa Alaikumus Salam", "Assalamu Alaikum", "Salam", "Shukran"],
                    correctAnswerIndex: 0,
                    explanation: "The proper response is 'Wa Alaikumus Salam' meaning 'And upon you be peace'.",
                    reference: "Quran 4:86",
                    category: .ethics,
                    difficulty: .beginner,
                    arabicText: "وعليكم السلام",
                    transliteration: "Wa alaykum as-salam"
                )
            ],
            timeLimit: 12,
            passingScore: 75
        )
    }
    
    private func createPrayerBasicsQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Prayer (Salah) Basics",
            description: "Essential knowledge about Islamic prayer and its performance",
            category: .prayer,
            difficulty: .beginner,
            questions: [
                IslamicQuizQuestion(
                    question: "How many rakats are in Fajr prayer?",
                    options: ["2", "3", "4", "6"],
                    correctAnswerIndex: 0,
                    explanation: "Fajr prayer consists of 2 rakats (units) and is performed before sunrise.",
                    reference: "Prayer Times",
                    category: .prayer,
                    difficulty: .beginner,
                    arabicText: "ركعتان",
                    transliteration: "Rak'atan"
                ),
                IslamicQuizQuestion(
                    question: "What is the call to prayer called?",
                    options: ["Adhan", "Iqama", "Salah", "Wudu"],
                    correctAnswerIndex: 0,
                    explanation: "The Adhan is the Islamic call to prayer, announced five times daily.",
                    reference: "Hadith: 'The Adhan is one of the most beautiful sounds'",
                    category: .prayer,
                    difficulty: .beginner,
                    arabicText: "الأذان",
                    transliteration: "Al-adhan"
                ),
                IslamicQuizQuestion(
                    question: "What is the ritual purification before prayer called?",
                    options: ["Wudu", "Ghusl", "Tayammum", "Niyyah"],
                    correctAnswerIndex: 0,
                    explanation: "Wudu is the ablution performed before prayer to achieve ritual purity.",
                    reference: "Quran 5:6",
                    category: .prayer,
                    difficulty: .beginner,
                    arabicText: "الوضوء",
                    transliteration: "Al-wudu"
                ),
                IslamicQuizQuestion(
                    question: "In which direction do Muslims pray?",
                    options: ["Towards Kaaba in Mecca", "Towards Jerusalem", "Towards East", "Towards North"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims pray facing the Kaaba in Mecca, known as the Qibla.",
                    reference: "Quran 2:144",
                    category: .prayer,
                    difficulty: .beginner,
                    arabicText: "القبلة",
                    transliteration: "Al-qibla"
                ),
                IslamicQuizQuestion(
                    question: "What is the prayer said after completing Salah?",
                    options: ["Subhanallah", "Alhamdulillah", "Allahu Akbar", "Astaghfirullah"],
                    correctAnswerIndex: 2,
                    explanation: "After prayer, Muslims commonly say 'Subhanallah' (Glory be to Allah), 'Alhamdulillah' (Praise be to Allah), and 'Allahu Akbar' (Allah is Great) 33 times each.",
                    reference: "Hadith: 'Recite Subhanallah, Alhamdulillah, Allahu Akbar 33 times each'",
                    category: .prayer,
                    difficulty: .beginner,
                    arabicText: "الله أكبر",
                    transliteration: "Allahu Akbar"
                )
            ],
            timeLimit: 15,
            passingScore: 70
        )
    }
    
    private func createZakatQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Zakat & Charity",
            description: "Understanding the Islamic concept of obligatory charity and its importance",
            category: .zakat,
            difficulty: .intermediate,
            questions: [
                IslamicQuizQuestion(
                    question: "What is the standard percentage of Zakat on wealth?",
                    options: ["2.5%", "5%", "10%", "20%"],
                    correctAnswerIndex: 0,
                    explanation: "Zakat is typically 2.5% (1/40) of a Muslim's qualifying wealth and assets.",
                    reference: "Islamic Jurisprudence",
                    category: .zakat,
                    difficulty: .intermediate,
                    arabicText: "٢.٥٪",
                    transliteration: "2.5%"
                ),
                IslamicQuizQuestion(
                    question: "Which of the following is NOT one of the eight categories of Zakat recipients?",
                    options: ["Business owners", "The poor", "The needy", "Those in debt"],
                    correctAnswerIndex: 0,
                    explanation: "The eight categories are: the poor, the needy, Zakat administrators, those whose hearts are to be reconciled, those in bondage, those in debt, in the cause of Allah, and the wayfarer.",
                    reference: "Quran 9:60",
                    category: .zakat,
                    difficulty: .intermediate,
                    arabicText: "مصارف الزكاة",
                    transliteration: "Masarif az-zakat"
                ),
                IslamicQuizQuestion(
                    question: "What is the minimum amount of wealth (nisab) required for Zakat to be obligatory?",
                    options: ["85 grams of gold or 595 grams of silver", "100 grams of gold", "500 grams of silver", "1 kilogram of gold"],
                    correctAnswerIndex: 0,
                    explanation: "The nisab is the minimum amount of wealth a Muslim must possess before Zakat becomes obligatory, equivalent to 85g of gold or 595g of silver.",
                    reference: "Hadith: 'No Zakat is due on wealth less than five uqiyyas'",
                    category: .zakat,
                    difficulty: .intermediate,
                    arabicText: "النصاب",
                    transliteration: "An-nisab"
                ),
                IslamicQuizQuestion(
                    question: "What is voluntary charity in Islam called?",
                    options: ["Sadaqah", "Zakat", "Waqf", "Hadiya"],
                    correctAnswerIndex: 0,
                    explanation: "Sadaqah is voluntary charity given out of compassion, unlike Zakat which is obligatory.",
                    reference: "Hadith: 'Sadaqah extinguishes sin as water extinguishes fire'",
                    category: .zakat,
                    difficulty: .intermediate,
                    arabicText: "الصدقة",
                    transliteration: "As-sadaqah"
                ),
                IslamicQuizQuestion(
                    question: "How often must Zakat be paid?",
                    options: ["Annually", "Monthly", "Weekly", "Once in lifetime"],
                    correctAnswerIndex: 0,
                    explanation: "Zakat must be paid annually on wealth that has been held for one lunar year.",
                    reference: "Islamic Law",
                    category: .zakat,
                    difficulty: .intermediate,
                    arabicText: "سنوياً",
                    transliteration: "Sanawiyan"
                )
            ],
            timeLimit: 18,
            passingScore: 70
        )
    }
    
    private func createFastingQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Fasting (Sawm) in Islam",
            description: "Learn about the rules and spiritual significance of Islamic fasting",
            category: .fasting,
            difficulty: .intermediate,
            questions: [
                IslamicQuizQuestion(
                    question: "From what time to what time do Muslims fast during Ramadan?",
                    options: ["Dawn to sunset", "Sunrise to sunset", "Dawn to midnight", "Sunrise to midnight"],
                    correctAnswerIndex: 0,
                    explanation: "Muslims fast from dawn (Fajr time) to sunset (Maghrib time) during Ramadan.",
                    reference: "Quran 2:187",
                    category: .fasting,
                    difficulty: .intermediate,
                    arabicText: "من الفجر إلى المغرب",
                    transliteration: "Min al-fajr ila al-maghrib"
                ),
                IslamicQuizQuestion(
                    question: "What is the pre-dawn meal before fasting called?",
                    options: ["Suhoor", "Iftar", "Taraweeh", "I'tikaf"],
                    correctAnswerIndex: 0,
                    explanation: "Suhoor is the pre-dawn meal eaten before beginning the fast for the day.",
                    reference: "Hadith: 'Eat suhoor, for in suhoor there is blessing'",
                    category: .fasting,
                    difficulty: .intermediate,
                    arabicText: "السحور",
                    transliteration: "As-suhoor"
                ),
                IslamicQuizQuestion(
                    question: "What is the meal to break the fast called?",
                    options: ["Iftar", "Suhoor", "Taraweeh", "Sadaqah"],
                    correctAnswerIndex: 0,
                    explanation: "Iftar is the meal eaten at sunset to break the daily fast during Ramadan.",
                    reference: "Hadith: 'The people will not cease to be upon good as long as they hasten in breaking the fast'",
                    category: .fasting,
                    difficulty: .intermediate,
                    arabicText: "الإفطار",
                    transliteration: "Al-iftar"
                ),
                IslamicQuizQuestion(
                    question: "Which night in Ramadan is better than a thousand months?",
                    options: ["Laylat al-Qadr", "Laylat al-Bara'ah", "Laylat al-Mi'raj", "Laylat al-Ragha'ib"],
                    correctAnswerIndex: 0,
                    explanation: "Laylat al-Qadr (Night of Power) is better than a thousand months of worship.",
                    reference: "Quran 97:1-5",
                    category: .fasting,
                    difficulty: .intermediate,
                    arabicText: "ليلة القدر",
                    transliteration: "Laylat al-Qadr"
                ),
                IslamicQuizQuestion(
                    question: "What are the special night prayers during Ramadan called?",
                    options: ["Taraweeh", "Tahajjud", "Witr", "Duha"],
                    correctAnswerIndex: 0,
                    explanation: "Taraweeh are special night prayers performed during Ramadan after Isha prayer.",
                    reference: "Hadith: 'Whoever stands for prayer on the night of Qadr out of faith and seeking reward will have his previous sins forgiven'",
                    category: .fasting,
                    difficulty: .intermediate,
                    arabicText: "التراويح",
                    transliteration: "At-taraweeh"
                )
            ],
            timeLimit: 16,
            passingScore: 75
        )
    }
    
    private func createHajjQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Hajj Pilgrimage",
            description: "Essential knowledge about the Hajj pilgrimage and its rituals",
            category: .hajj,
            difficulty: .advanced,
            questions: [
                IslamicQuizQuestion(
                    question: "In which Islamic month is Hajj performed?",
                    options: ["Dhul Hijjah", "Ramadan", "Muharram", "Shawwal"],
                    correctAnswerIndex: 0,
                    explanation: "Hajj is performed during the month of Dhul Hijjah, the 12th month of the Islamic calendar.",
                    reference: "Quran 2:197",
                    category: .hajj,
                    difficulty: .advanced,
                    arabicText: "ذو الحجة",
                    transliteration: "Dhul Hijjah"
                ),
                IslamicQuizQuestion(
                    question: "What is the state of ritual purity and devotion during Hajj called?",
                    options: ["Ihram", "Tawaf", "Sa'i", "Wudu"],
                    correctAnswerIndex: 0,
                    explanation: "Ihram is the sacred state a pilgrim must enter before performing Hajj or Umrah.",
                    reference: "Quran 2:197",
                    category: .hajj,
                    difficulty: .advanced,
                    arabicText: "الإحرام",
                    transliteration: "Al-ihram"
                ),
                IslamicQuizQuestion(
                    question: "What is the circumambulation around the Kaaba called?",
                    options: ["Tawaf", "Sa'i", "Ramy al-Jamarat", "Wuquf"],
                    correctAnswerIndex: 0,
                    explanation: "Tawaf is the act of circumambulating the Kaaba seven times in a counter-clockwise direction.",
                    reference: "Hajj Rituals",
                    category: .hajj,
                    difficulty: .advanced,
                    arabicText: "الطواف",
                    transliteration: "At-tawaf"
                ),
                IslamicQuizQuestion(
                    question: "What is the stoning of the pillars ritual called?",
                    options: ["Ramy al-Jamarat", "Sa'i", "Tawaf", "Wuquf"],
                    correctAnswerIndex: 0,
                    explanation: "Ramy al-Jamarat is the ritual of stoning three pillars at Mina, symbolizing the rejection of evil.",
                    reference: "Hajj Rituals",
                    category: .hajj,
                    difficulty: .advanced,
                    arabicText: "رمي الجمرات",
                    transliteration: "Ramy al-jamarat"
                ),
                IslamicQuizQuestion(
                    question: "What is the standing at Arafat called?",
                    options: ["Wuquf", "Tawaf", "Sa'i", "Ihram"],
                    correctAnswerIndex: 0,
                    explanation: "Wuquf is the standing at the plain of Arafat, considered the most important ritual of Hajj.",
                    reference: "Hadith: 'Hajj is Arafat'",
                    category: .hajj,
                    difficulty: .advanced,
                    arabicText: "الوقوف بعرفة",
                    transliteration: "Al-wuquf bi-Arafat"
                )
            ],
            timeLimit: 20,
            passingScore: 70
        )
    }
    
    private func createProphetCompanionsQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Companions of the Prophet",
            description: "Test your knowledge about the noble companions of Prophet Muhammad (peace be upon him)",
            category: .companions,
            difficulty: .intermediate,
            questions: [
                IslamicQuizQuestion(
                    question: "Who was the first Caliph after Prophet Muhammad's death?",
                    options: ["Abu Bakr", "Umar", "Uthman", "Ali"],
                    correctAnswerIndex: 0,
                    explanation: "Abu Bakr as-Siddiq was the first Caliph and the Prophet's closest companion.",
                    reference: "Islamic History",
                    category: .companions,
                    difficulty: .intermediate,
                    arabicText: "أبو بكر الصديق",
                    transliteration: "Abu Bakr as-Siddiq"
                ),
                IslamicQuizQuestion(
                    question: "Which companion was known as 'The Truthful' (As-Siddiq)?",
                    options: ["Abu Bakr", "Umar", "Uthman", "Ali"],
                    correctAnswerIndex: 0,
                    explanation: "Abu Bakr was given the title 'As-Siddiq' (The Truthful) for his unwavering faith.",
                    reference: "Hadith: 'If the faith of Abu Bakr were weighed against the faith of all people, it would outweigh them'",
                    category: .companions,
                    difficulty: .intermediate,
                    arabicText: "الصديق",
                    transliteration: "As-Siddiq"
                ),
                IslamicQuizQuestion(
                    question: "Which companion was the Prophet's cousin and son-in-law?",
                    options: ["Ali", "Umar", "Uthman", "Abu Bakr"],
                    correctAnswerIndex: 0,
                    explanation: "Ali ibn Abi Talib was the Prophet's cousin and married to his daughter Fatima.",
                    reference: "Islamic History",
                    category: .companions,
                    difficulty: .intermediate,
                    arabicText: "علي بن أبي طالب",
                    transliteration: "Ali ibn Abi Talib"
                ),
                IslamicQuizQuestion(
                    question: "Which companion was known as 'The Lion of Allah'?",
                    options: ["Ali", "Umar", "Khalid ibn Walid", "Hamza"],
                    correctAnswerIndex: 0,
                    explanation: "Ali was known as 'Asadullah' (The Lion of Allah) for his bravery in battle.",
                    reference: "Islamic History",
                    category: .companions,
                    difficulty: .intermediate,
                    arabicText: "أسد الله",
                    transliteration: "Asadullah"
                ),
                IslamicQuizQuestion(
                    question: "Who was the first man to accept Islam?",
                    options: ["Abu Bakr", "Ali", "Umar", "Zayd"],
                    correctAnswerIndex: 0,
                    explanation: "Abu Bakr was the first adult man to accept Islam, while Ali was the first child.",
                    reference: "Islamic History",
                    category: .companions,
                    difficulty: .intermediate,
                    arabicText: "أول رجل أسلم",
                    transliteration: "Awwal rajul aslam"
                )
            ],
            timeLimit: 18,
            passingScore: 70
        )
    }
    
    private func createIslamicNamesQuiz() -> IslamicQuiz {
        return IslamicQuiz(
            title: "Islamic Names & Meanings",
            description: "Learn about beautiful Islamic names and their meanings",
            category: .islamicNames,
            difficulty: .beginner,
            questions: [
                IslamicQuizQuestion(
                    question: "What does the name 'Muhammad' mean?",
                    options: ["Praised", "Chosen", "Blessed", "Noble"],
                    correctAnswerIndex: 0,
                    explanation: "Muhammad means 'praised' or 'praiseworthy' and is derived from the root 'hamd' (praise).",
                    reference: "Arabic Etymology",
                    category: .islamicNames,
                    difficulty: .beginner,
                    arabicText: "محمد",
                    transliteration: "Muhammad"
                ),
                IslamicQuizQuestion(
                    question: "What does the name 'Aisha' mean?",
                    options: ["Living", "Life", "Alive", "Prosperous"],
                    correctAnswerIndex: 0,
                    explanation: "Aisha means 'living' or 'alive' and was the name of the Prophet's beloved wife.",
                    reference: "Arabic Etymology",
                    category: .islamicNames,
                    difficulty: .beginner,
                    arabicText: "عائشة",
                    transliteration: "Aisha"
                ),
                IslamicQuizQuestion(
                    question: "What does the name 'Fatima' mean?",
                    options: ["To abstain", "To capture", "To shine", "To lead"],
                    correctAnswerIndex: 0,
                    explanation: "Fatima means 'to abstain' or 'to wean' and was the name of the Prophet's daughter.",
                    reference: "Arabic Etymology",
                    category: .islamicNames,
                    difficulty: .beginner,
                    arabicText: "فاطمة",
                    transliteration: "Fatima"
                ),
                IslamicQuizQuestion(
                    question: "What does the name 'Omar' mean?",
                    options: ["Flourishing", "Life", "Strength", "Wisdom"],
                    correctAnswerIndex: 0,
                    explanation: "Omar (Umar) means 'flourishing' or 'thriving' and was the name of the second Caliph.",
                    reference: "Arabic Etymology",
                    category: .islamicNames,
                    difficulty: .beginner,
                    arabicText: "عمر",
                    transliteration: "Umar"
                ),
                IslamicQuizQuestion(
                    question: "What does the name 'Khadija' mean?",
                    options: ["Premature child", "Trustworthy", "Beautiful", "Noble"],
                    correctAnswerIndex: 0,
                    explanation: "Khadija means 'premature child' and was the name of the Prophet's first wife.",
                    reference: "Arabic Etymology",
                    category: .islamicNames,
                    difficulty: .beginner,
                    arabicText: "خديجة",
                    transliteration: "Khadija"
                )
            ],
            timeLimit: 12,
            passingScore: 70
        )
    }
}

// MARK: - Upload Result

@available(iOS 17, *)
public struct QuizUploadResult {
    public let totalQuizzes: Int
    public let successfulUploads: Int
    public let failedUploads: Int
    public let errors: [Error]
    
    public init(totalQuizzes: Int, successfulUploads: Int, failedUploads: Int, errors: [Error]) {
        self.totalQuizzes = totalQuizzes
        self.successfulUploads = successfulUploads
        self.failedUploads = failedUploads
        self.errors = errors
    }
}

#endif
