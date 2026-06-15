class OnboardingQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correct;

  const OnboardingQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
  });
}

const Map<String, List<OnboardingQuestion>> onboardingQuiz = <String, List<OnboardingQuestion>>{
  'BEGINNER': <OnboardingQuestion>[
    OnboardingQuestion(
      id: 'b1',
      question: "Choose the correct translation for 'Hello':",
      options: <String>['Bonjour', 'Au revoir', 'Merci', "S'il vous plaît"],
      correct: 'Bonjour',
    ),
    OnboardingQuestion(
      id: 'b2',
      question: "Which of these means 'Thank you'?",
      options: <String>['Oui', 'Non', 'Merci', 'Chat'],
      correct: 'Merci',
    ),
    OnboardingQuestion(
      id: 'b3',
      question: "Complete the phrase: '___ va?' (How's it going?)",
      options: <String>['Comment', 'Ça', 'Qui', 'Où'],
      correct: 'Ça',
    ),
  ],
  'EXPERIENCED': <OnboardingQuestion>[
    OnboardingQuestion(
      id: 'e1',
      question: "Select the missing word: 'Je voudrais ___ un café.'",
      options: <String>['manger', 'boire', 'commander', 'parler'],
      correct: 'commander',
    ),
    OnboardingQuestion(
      id: 'e2',
      question: "What is the correct past tense form?",
      options: <String>["J'ai mangé", "Je mange", "Je mangerai", "Je mangerais"],
      correct: "J'ai mangé",
    ),
    OnboardingQuestion(
      id: 'e3',
      question: "Translate: 'The weather is beautiful today.'",
      options: <String>['Il fait froid.', "Il fait beau aujourd'hui.", 'Il pleut.', "C'est difficile."],
      correct: "Il fait beau aujourd'hui.",
    ),
  ],
};
