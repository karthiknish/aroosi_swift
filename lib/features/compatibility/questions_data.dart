import 'models.dart';

class IslamicCompatibilityQuestions {
  static List<IslamicCompatibilityCategory> getCategories() {
    return [
      // 1. Religious Practice
      IslamicCompatibilityCategory(
        id: 'religious_practice',
        name: 'Religious Practice',
        description: 'Daily Islamic practices and religious observance',
        weight: 0.20, // 20% weight - most important
        questions: [
          CompatibilityQuestion(
            id: 'daily_prayer',
            text: 'How often do you perform the five daily prayers?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'all_five', text: 'All 5 prayers daily', value: 1.0),
              QuestionOption(id: 'most_prayers', text: 'Most prayers (3-4 daily)', value: 0.8),
              QuestionOption(id: 'some_prayers', text: 'Some prayers (1-2 daily)', value: 0.5),
              QuestionOption(id: 'occasionally', text: 'Occasionally', value: 0.2),
              QuestionOption(id: 'rarely', text: 'Rarely/Never', value: 0.0),
            ],
          ),
          CompatibilityQuestion(
            id: 'quran_reading',
            text: 'How frequently do you read or study the Quran?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'daily', text: 'Daily', value: 1.0),
              QuestionOption(id: 'weekly', text: 'Weekly', value: 0.8),
              QuestionOption(id: 'monthly', text: 'Monthly', value: 0.6),
              QuestionOption(id: 'occasionally', text: 'Occasionally', value: 0.3),
              QuestionOption(id: 'rarely', text: 'Rarely', value: 0.1),
            ],
          ),
          CompatibilityQuestion(
            id: 'ramadan_fasting',
            text: 'Do you fast during Ramadan?',
            type: QuestionType.yesNo,
            options: [
              QuestionOption(id: 'yes', text: 'Yes, all required fasts', value: 1.0),
              QuestionOption(id: 'no', text: 'No', value: 0.0),
            ],
          ),
          CompatibilityQuestion(
            id: 'halal_diet',
            text: 'How strictly do you follow halal dietary requirements?',
            type: QuestionType.scale,
            options: [
              QuestionOption(id: 'very_strict', text: 'Very strict - only certified halal', value: 1.0),
              QuestionOption(id: 'strict', text: 'Strict - avoid haram ingredients', value: 0.8),
              QuestionOption(id: 'moderate', text: 'Moderate - mostly halal', value: 0.6),
              QuestionOption(id: 'flexible', text: 'Flexible', value: 0.3),
              QuestionOption(id: 'not_strict', text: 'Not strict', value: 0.1),
            ],
          ),
        ],
      ),

      // 2. Family Structure
      IslamicCompatibilityCategory(
        id: 'family_structure',
        name: 'Family Structure',
        description: 'Views on family roles, parenting, and extended family involvement',
        weight: 0.18, // 18% weight
        questions: [
          CompatibilityQuestion(
            id: 'gender_roles',
            text: 'What are your views on traditional gender roles in marriage?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'traditional', text: 'Traditional - clear separate roles', value: 1.0),
              QuestionOption(id: 'mostly_traditional', text: 'Mostly traditional with flexibility', value: 0.8),
              QuestionOption(id: 'balanced', text: 'Balanced - shared responsibilities', value: 0.6),
              QuestionOption(id: 'modern', text: 'Modern - role-based on skills/preferences', value: 0.4),
              QuestionOption(id: 'very_modern', text: 'Very modern - complete flexibility', value: 0.2),
            ],
          ),
          CompatibilityQuestion(
            id: 'parenting_style',
            text: 'What parenting approach do you prefer?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'authoritative', text: 'Authoritative - clear boundaries with love', value: 1.0),
              QuestionOption(id: 'permissive', text: 'Permissive - high warmth, low control', value: 0.6),
              QuestionOption(id: 'authoritarian', text: 'Authoritarian - strict discipline', value: 0.4),
              QuestionOption(id: 'gentle', text: 'Gentle parenting - collaboration focused', value: 0.8),
            ],
          ),
          CompatibilityQuestion(
            id: 'extended_family',
            text: 'How involved should extended family be in your married life?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'very_involved', text: 'Very involved - frequent contact and input', value: 1.0),
              QuestionOption(id: 'moderately_involved', text: 'Moderately involved - regular contact', value: 0.8),
              QuestionOption(id: 'selective_involvement', text: 'Selective involvement for major decisions', value: 0.6),
              QuestionOption(id: 'minimal_involvement', text: 'Minimal involvement', value: 0.4),
              QuestionOption(id: 'independent', text: 'Independent nuclear family', value: 0.2),
            ],
          ),
        ],
      ),

      // 3. Cultural Values
      IslamicCompatibilityCategory(
        id: 'cultural_values',
        name: 'Cultural Values',
        description: 'Cultural traditions, language, and customs',
        weight: 0.12, // 12% weight
        questions: [
          CompatibilityQuestion(
            id: 'cultural_traditions',
            text: 'How important are cultural traditions in your life?',
            type: QuestionType.scale,
            options: [
              QuestionOption(id: 'very_important', text: 'Very important', value: 1.0),
              QuestionOption(id: 'important', text: 'Important', value: 0.8),
              QuestionOption(id: 'somewhat_important', text: 'Somewhat important', value: 0.6),
              QuestionOption(id: 'not_very_important', text: 'Not very important', value: 0.3),
              QuestionOption(id: 'not_important', text: 'Not important', value: 0.1),
            ],
          ),
          CompatibilityQuestion(
            id: 'language_preference',
            text: 'What language(s) should be spoken at home?',
            type: QuestionType.multipleChoice,
            options: [
              QuestionOption(id: 'arabic', text: 'Arabic', value: 0.8),
              QuestionOption(id: 'english', text: 'English', value: 0.6),
              QuestionOption(id: 'native_language', text: 'Native language', value: 1.0),
              QuestionOption(id: 'multiple', text: 'Multiple languages', value: 0.9),
            ],
          ),
          CompatibilityQuestion(
            id: 'cultural_celebrations',
            text: 'How do you approach cultural celebrations (weddings, Eid, etc.)?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'traditional', text: 'Traditional customs and celebrations', value: 1.0),
              QuestionOption(id: 'moderate', text: 'Moderate celebration', value: 0.7),
              QuestionOption(id: 'simple', text: 'Simple observance', value: 0.5),
              QuestionOption(id: 'minimal', text: 'Minimal celebration', value: 0.3),
            ],
          ),
        ],
      ),

      // 4. Financial Management
      IslamicCompatibilityCategory(
        id: 'financial_management',
        name: 'Financial Management',
        description: 'Halal income, spending habits, and charitable giving',
        weight: 0.15, // 15% weight
        questions: [
          CompatibilityQuestion(
            id: 'halal_income',
            text: 'How important is it that income comes from halal sources?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'essential', text: 'Essential - 100% halal income required', value: 1.0),
              QuestionOption(id: 'very_important', text: 'Very important', value: 0.9),
              QuestionOption(id: 'important', text: 'Important', value: 0.7),
              QuestionOption(id: 'preferable', text: 'Preferable but flexible', value: 0.4),
              QuestionOption(id: 'not_critical', text: 'Not critical', value: 0.1),
            ],
          ),
          CompatibilityQuestion(
            id: 'zakat_charity',
            text: 'How do you approach zakat and charitable giving?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'regular_calculated', text: 'Regular calculated zakat + additional charity', value: 1.0),
              QuestionOption(id: 'regular_zakat', text: 'Regular zakat only', value: 0.8),
              QuestionOption(id: 'occasional', text: 'Occasional giving', value: 0.5),
              QuestionOption(id: 'rare', text: 'Rare giving', value: 0.2),
              QuestionOption(id: 'not_giving', text: 'Not currently giving', value: 0.0),
            ],
          ),
          CompatibilityQuestion(
            id: 'spending_habits',
            text: 'What describes your spending philosophy?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'frugal', text: 'Frugal - save most income', value: 0.6),
              QuestionOption(id: 'balanced', text: 'Balanced - save and spend wisely', value: 1.0),
              QuestionOption(id: 'moderate', text: 'Moderate spender', value: 0.7),
              QuestionOption(id: 'generous', text: 'Generous spender', value: 0.4),
            ],
          ),
        ],
      ),

      // 5. Education & Career
      IslamicCompatibilityCategory(
        id: 'education_career',
        name: 'Education & Career',
        description: 'Educational priorities and work-life balance',
        weight: 0.10, // 10% weight
        questions: [
          CompatibilityQuestion(
            id: 'education_priority',
            text: 'How important is higher education to you?',
            type: QuestionType.scale,
            options: [
              QuestionOption(id: 'very_important', text: 'Very important', value: 1.0),
              QuestionOption(id: 'important', text: 'Important', value: 0.8),
              QuestionOption(id: 'somewhat_important', text: 'Somewhat important', value: 0.6),
              QuestionOption(id: 'not_very_important', text: 'Not very important', value: 0.3),
              QuestionOption(id: 'not_important', text: 'Not important', value: 0.1),
            ],
          ),
          CompatibilityQuestion(
            id: 'work_life_balance',
            text: 'What work-life balance do you prefer?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'family_priority', text: 'Family priority - work to support family', value: 1.0),
              QuestionOption(id: 'balanced', text: 'Balanced career and family', value: 0.8),
              QuestionOption(id: 'career_focused', text: 'Career focused with family time', value: 0.6),
              QuestionOption(id: 'ambitious', text: 'Ambitious - career priority', value: 0.4),
            ],
          ),
          CompatibilityQuestion(
            id: 'spouse_working',
            text: 'Should your spouse work outside the home?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'yes_definitely', text: 'Yes, definitely', value: 0.3),
              QuestionOption(id: 'yes_if_needed', text: 'Yes, if needed/desired', value: 0.6),
              QuestionOption(id: 'neutral', text: 'Neutral', value: 0.8),
              QuestionOption(id: 'prefer_not', text: 'Prefer not', value: 0.9),
              QuestionOption(id: 'definitely_not', text: 'Definitely not', value: 1.0),
            ],
          ),
        ],
      ),

      // 6. Social Life
      IslamicCompatibilityCategory(
        id: 'social_life',
        name: 'Social Life',
        description: 'Friendships, community involvement, and entertainment',
        weight: 0.08, // 8% weight
        questions: [
          CompatibilityQuestion(
            id: 'friendship_circle',
            text: 'What type of friendship circle do you prefer?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'muslim_only', text: 'Muslim friends only', value: 1.0),
              QuestionOption(id: 'mostly_muslim', text: 'Mostly Muslim friends', value: 0.8),
              QuestionOption(id: 'mixed', text: 'Mixed religious friends', value: 0.6),
              QuestionOption(id: 'diverse', text: 'Diverse friendship circle', value: 0.4),
            ],
          ),
          CompatibilityQuestion(
            id: 'community_involvement',
            text: 'How involved do you want to be in the Muslim community?',
            type: QuestionType.scale,
            options: [
              QuestionOption(id: 'very_active', text: 'Very active leadership', value: 1.0),
              QuestionOption(id: 'active', text: 'Active participant', value: 0.8),
              QuestionOption(id: 'regular_attendance', text: 'Regular event attendance', value: 0.6),
              QuestionOption(id: 'occasional', text: 'Occasional participation', value: 0.3),
              QuestionOption(id: 'minimal', text: 'Minimal involvement', value: 0.1),
            ],
          ),
          CompatibilityQuestion(
            id: 'entertainment_preferences',
            text: 'What entertainment do you prefer?',
            type: QuestionType.multipleChoice,
            options: [
              QuestionOption(id: 'islamic_content', text: 'Islamic content only', value: 1.0),
              QuestionOption(id: 'family_friendly', text: 'Family-friendly content', value: 0.8),
              QuestionOption(id: 'selective_mainstream', text: 'Selective mainstream', value: 0.6),
              QuestionOption(id: 'varied', text: 'Varied content', value: 0.4),
            ],
          ),
        ],
      ),

      // 7. Conflict Resolution
      IslamicCompatibilityCategory(
        id: 'conflict_resolution',
        name: 'Conflict Resolution',
        description: 'Communication styles and decision-making approaches',
        weight: 0.10, // 10% weight
        questions: [
          CompatibilityQuestion(
            id: 'communication_style',
            text: 'How do you prefer to communicate during disagreements?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'direct_immediate', text: 'Direct and immediate resolution', value: 0.8),
              QuestionOption(id: 'calm_discussion', text: 'Calm discussion after cooling down', value: 1.0),
              QuestionOption(id: 'written', text: 'Written communication', value: 0.6),
              QuestionOption(id: 'mediated', text: 'With family mediation', value: 0.4),
            ],
          ),
          CompatibilityQuestion(
            id: 'decision_making',
            text: 'How should major decisions be made in marriage?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'mutual_consensus', text: 'Mutual consensus', value: 1.0),
              QuestionOption(id: 'husband_leads', text: 'Husband leads with wife input', value: 0.7),
              QuestionOption(id: 'wife_leads', text: 'Wife leads with husband input', value: 0.5),
              QuestionOption(id: 'situational', text: 'Depends on the situation', value: 0.8),
            ],
          ),
          CompatibilityQuestion(
            id: 'conflict_avoidance',
            text: 'How do you handle conflicts?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'address_immediately', text: 'Address immediately', value: 0.8),
              QuestionOption(id: 'reflect_then_discuss', text: 'Reflect then discuss', value: 1.0),
              QuestionOption(id: 'seek_counsel', text: 'Seek counsel first', value: 0.6),
              QuestionOption(id: 'avoid_conflict', text: 'Try to avoid conflict', value: 0.4),
            ],
          ),
        ],
      ),

      // 8. Life Goals
      IslamicCompatibilityCategory(
        id: 'life_goals',
        name: 'Life Goals',
        description: 'Future plans including location, children, and long-term objectives',
        weight: 0.07, // 7% weight
        questions: [
          CompatibilityQuestion(
            id: 'living_location',
            text: 'Where do you prefer to live long-term?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'muslim_country', text: 'Muslim-majority country', value: 1.0),
              QuestionOption(id: 'western_country', text: 'Western country', value: 0.6),
              QuestionOption(id: 'flexible', text: 'Flexible based on opportunities', value: 0.8),
              QuestionOption(id: 'current_location', text: 'Current location', value: 0.7),
            ],
          ),
          CompatibilityQuestion(
            id: 'having_children',
            text: 'Do you want to have children?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'definitely_yes', text: 'Definitely yes', value: 1.0),
              QuestionOption(id: 'yes_soon', text: 'Yes, preferably soon', value: 0.9),
              QuestionOption(id: 'yes_later', text: 'Yes, but later', value: 0.7),
              QuestionOption(id: 'unsure', text: 'Unsure', value: 0.5),
              QuestionOption(id: 'no', text: 'No', value: 0.0),
            ],
          ),
          CompatibilityQuestion(
            id: 'children_desired',
            text: 'How many children would you like?',
            type: QuestionType.singleChoice,
            options: [
              QuestionOption(id: 'many', text: 'Many children (4+)', value: 1.0),
              QuestionOption(id: 'several', text: 'Several children (3-4)', value: 0.9),
              QuestionOption(id: 'few', text: 'A few children (2-3)', value: 0.7),
              QuestionOption(id: 'one_or_two', text: 'One or two children', value: 0.5),
              QuestionOption(id: 'none', text: 'No children', value: 0.0),
            ],
          ),
          CompatibilityQuestion(
            id: 'islamic_priorities',
            text: 'How important is it to prioritize Islamic values in life goals?',
            type: QuestionType.scale,
            options: [
              QuestionOption(id: 'absolute_priority', text: 'Absolute priority', value: 1.0),
              QuestionOption(id: 'high_priority', text: 'High priority', value: 0.8),
              QuestionOption(id: 'important_factor', text: 'Important factor', value: 0.6),
              QuestionOption(id: 'consideration', text: 'One consideration among many', value: 0.3),
              QuestionOption(id: 'not_major_factor', text: 'Not a major factor', value: 0.1),
            ],
          ),
        ],
      ),
    ];
  }

  static double getTotalWeight() {
    return getCategories().fold(0.0, (sum, category) => sum + category.weight);
  }
}
