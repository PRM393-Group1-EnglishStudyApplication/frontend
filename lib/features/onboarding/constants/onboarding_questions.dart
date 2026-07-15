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
      question: "Chọn từ tiếng Anh có nghĩa là 'Xin chào':",
      options: <String>['Hello', 'Goodbye', 'Thank you', 'Please'],
      correct: 'Hello',
    ),
    OnboardingQuestion(
      id: 'b2',
      question: "Từ nào dưới đây có nghĩa là 'Cảm ơn'?",
      options: <String>['Yes', 'No', 'Thank you', 'Sorry'],
      correct: 'Thank you',
    ),
    OnboardingQuestion(
      id: 'b3',
      question: "Hoàn thành câu sau: 'How ___ you?' (Bạn khỏe không?)",
      options: <String>['is', 'are', 'am', 'be'],
      correct: 'are',
    ),
  ],
  'EXPERIENCED': <OnboardingQuestion>[
    OnboardingQuestion(
      id: 'e1',
      question: "Chọn từ còn thiếu: 'I would like to ___ a cup of coffee.' (Tôi muốn gọi một tách cà phê.)",
      options: <String>['eat', 'order', 'speak', 'run'],
      correct: 'order',
    ),
    OnboardingQuestion(
      id: 'e2',
      question: "Dạng quá khứ của động từ 'go' là gì?",
      options: <String>['went', 'going', 'gone', 'goes'],
      correct: 'went',
    ),
    OnboardingQuestion(
      id: 'e3',
      question: "Dịch câu sau sang tiếng Anh: 'Hôm nay thời tiết thật đẹp.'",
      options: <String>[
        'It is raining today.',
        'The weather is beautiful today.',
        'It is very cold today.',
        'It is dark today.'
      ],
      correct: 'The weather is beautiful today.',
    ),
  ],
};
