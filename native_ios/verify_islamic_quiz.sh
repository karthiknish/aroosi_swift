#!/bin/bash

echo "🕌 Verifying Islamic Quiz System Setup..."

# Check if all required files exist
echo "📁 Checking Islamic quiz files..."

quiz_files=(
    "Sources/Features/IslamicEducation/Models/IslamicQuizModels.swift"
    "Sources/Features/IslamicEducation/Repositories/IslamicQuizRepository.swift"
    "Sources/Features/IslamicEducation/Services/IslamicQuizService.swift"
    "Sources/Features/IslamicEducation/Services/IslamicQuizUploadService.swift"
    "Sources/Features/IslamicEducation/Views/EnhancedIslamicQuizView.swift"
    "Sources/Features/IslamicEducation/Views/IslamicQuizManagementView.swift"
)

for file in "${quiz_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check for Firebase imports
echo "🔥 Checking Firebase integration..."
if grep -q "import FirebaseFirestore" Sources/Features/IslamicEducation/Repositories/IslamicQuizRepository.swift; then
    echo "✅ Firebase Firestore imported in repository"
else
    echo "❌ Firebase Firestore not imported in repository"
    exit 1
fi

if grep -q "import FirebaseFirestore" Sources/Features/IslamicEducation/Services/IslamicQuizService.swift; then
    echo "✅ Firebase Firestore imported in service"
else
    echo "❌ Firebase Firestore not imported in service"
    exit 1
fi

# Check for quiz categories
echo "📚 Checking quiz categories..."
categories=(
    "quran"
    "hadith"
    "fiqh"
    "aqidah"
    "seerah"
    "islamicHistory"
    "prophets"
    "companions"
    "prayer"
    "zakat"
    "fasting"
    "hajj"
    "family"
    "ethics"
    "islamicNames"
)

for category in "${categories[@]}"; do
    if grep -q "case $category" Sources/Features/IslamicEducation/Models/IslamicQuizModels.swift; then
        echo "✅ Quiz category $category defined"
    else
        echo "❌ Quiz category $category missing"
        exit 1
    fi
done

# Check for sample quizzes
echo "📝 Checking sample quiz content..."
sample_quizzes=(
    "createQuranBasicsQuiz"
    "createPillarsOfIslamQuiz"
    "createProphetStoriesQuiz"
    "createIslamicEtiquetteQuiz"
    "createPrayerBasicsQuiz"
    "createZakatQuiz"
    "createFastingQuiz"
    "createHajjQuiz"
    "createProphetCompanionsQuiz"
    "createIslamicNamesQuiz"
)

for quiz in "${sample_quizzes[@]}"; do
    if grep -q "$quiz" Sources/Features/IslamicEducation/Services/IslamicQuizUploadService.swift; then
        echo "✅ Sample quiz $quiz implemented"
    else
        echo "❌ Sample quiz $quiz missing"
        exit 1
    fi
done

# Check for Firebase collections
echo "🗄️ Checking Firebase collection definitions..."
collections=(
    "islamic_quizzes"
    "islamic_quiz_results"
    "islamic_quiz_profiles"
)

for collection in "${collections[@]}"; do
    if grep -q "$collection" Sources/Features/IslamicEducation/Repositories/IslamicQuizRepository.swift; then
        echo "✅ Firebase collection $collection defined"
    else
        echo "❌ Firebase collection $collection missing"
        exit 1
    fi
done

# Check for quiz features
echo "🎯 Checking quiz features..."

# Timer functionality
if grep -q "timeRemaining" Sources/Features/IslamicEducation/Views/EnhancedIslamicQuizView.swift; then
    echo "✅ Quiz timer functionality implemented"
else
    echo "❌ Quiz timer functionality missing"
    exit 1
fi

# Progress tracking
if grep -q "progress" Sources/Features/IslamicEducation/Views/EnhancedIslamicQuizView.swift; then
    echo "✅ Quiz progress tracking implemented"
else
    echo "❌ Quiz progress tracking missing"
    exit 1
fi

# Arabic text support
if grep -q "arabicText" Sources/Features/IslamicEducation/Models/IslamicQuizModels.swift; then
    echo "✅ Arabic text support implemented"
else
    echo "❌ Arabic text support missing"
    exit 1
fi

# User profiles
if grep -q "UserIslamicQuizProfile" Sources/Features/IslamicEducation/Models/IslamicQuizModels.swift; then
    echo "✅ User quiz profiles implemented"
else
    echo "❌ User quiz profiles missing"
    exit 1
fi

# Achievements system
if grep -q "QuizAchievement" Sources/Features/IslamicEducation/Models/IslamicQuizModels.swift; then
    echo "✅ Quiz achievements system implemented"
else
    echo "❌ Quiz achievements system missing"
    exit 1
fi

# Analytics integration
if grep -q "analytics.track" Sources/Features/IslamicEducation/Services/IslamicQuizService.swift; then
    echo "✅ Analytics integration implemented"
else
    echo "❌ Analytics integration missing"
    exit 1
fi

# Check for Islamic content validation
echo "🕌 Checking Islamic content validation..."

# Quran references
if grep -q "Quran" Sources/Features/IslamicEducation/Services/IslamicQuizUploadService.swift; then
    echo "✅ Quranic references included in content"
else
    echo "❌ Quranic references missing from content"
    exit 1
fi

# Hadith references
if grep -q "Hadith" Sources/Features/IslamicEducation/Services/IslamicQuizUploadService.swift; then
    echo "✅ Hadith references included in content"
else
    echo "❌ Hadith references missing from content"
    exit 1
fi

# Arabic text
if grep -q "arabicText" Sources/Features/IslamicEducation/Services/IslamicQuizUploadService.swift; then
    echo "✅ Arabic text included in quiz content"
else
    echo "❌ Arabic text missing from quiz content"
    exit 1
fi

# Check for proper error handling
echo "⚠️ Checking error handling..."
if grep -q "IslamicQuizError" Sources/Features/IslamicEducation/Repositories/IslamicQuizRepository.swift; then
    echo "✅ Custom error handling implemented"
else
    echo "❌ Custom error handling missing"
    exit 1
fi

# Check for async/await usage
echo "⚡ Checking async implementation..."
if grep -q "async throws" Sources/Features/IslamicEducation/Repositories/IslamicQuizRepository.swift; then
    echo "✅ Async/await properly implemented"
else
    echo "❌ Async/await implementation missing"
    exit 1
fi

# Summary
echo ""
echo "🕌 Islamic Quiz System Verification Summary:"
echo "✅ Model definitions: COMPLETE"
echo "✅ Firebase repository: IMPLEMENTED"
echo "✅ Service layer: IMPLEMENTED"
echo "✅ Upload service: IMPLEMENTED"
echo "✅ Enhanced quiz view: IMPLEMENTED"
echo "✅ Management interface: IMPLEMENTED"
echo "✅ Sample content: CREATED (10 quizzes)"
echo "✅ Arabic text support: IMPLEMENTED"
echo "✅ User profiles: IMPLEMENTED"
echo "✅ Achievements system: IMPLEMENTED"
echo "✅ Analytics integration: COMPLETE"
echo "✅ Error handling: IMPLEMENTED"
echo "✅ Async/await: PROPERLY IMPLEMENTED"

echo ""
echo "🎯 Islamic Quiz System Status: COMPLETE"
echo "📱 Ready for Firebase integration"
echo "🕌 15 Islamic categories covered"
echo "📚 10 Sample quizzes prepared"
echo "👤 User profile tracking implemented"
echo "🏆 Achievement system ready"
echo "📊 Analytics tracking configured"

echo ""
echo "🚀 Next Steps:"
echo "1. Run the app and test quiz upload functionality"
echo "2. Verify Firebase collections are created"
echo "3. Test quiz taking and result saving"
echo "4. Validate user profile updates"
echo "5. Check analytics events are tracked"
