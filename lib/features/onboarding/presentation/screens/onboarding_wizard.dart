import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math' as math;

import '../../constants/onboarding_questions.dart';

enum OnboardingStep {
  purpose,
  level,
  quiz,
  celebration,
  registration,
  directSignIn,
}

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> with SingleTickerProviderStateMixin {
  OnboardingStep _currentStep = OnboardingStep.purpose;
  OnboardingStep _previousStep = OnboardingStep.purpose; // To return from direct sign-in

  String? _selectedPurpose;
  String? _selectedLevel;
  int _quizProgress = 0;
  int _score = 0;

  String? _selectedOption;
  bool? _isCorrect;
  bool _isTransitioning = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0.0);
  }

  double _getProgressPercentage() {
    switch (_currentStep) {
      case OnboardingStep.purpose:
        return 0.2;
      case OnboardingStep.level:
        return 0.4;
      case OnboardingStep.quiz:
        return 0.4 + (_quizProgress + 1) * 0.1; // 0.5, 0.6, 0.7
      case OnboardingStep.celebration:
        return 0.85;
      case OnboardingStep.registration:
        return 1.0;
      case OnboardingStep.directSignIn:
        return 1.0;
    }
  }

  Future<void> _saveOnboardingProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_selectedPurpose != null) {
        await prefs.setString('onboarding_purpose', _selectedPurpose!);
      }
      if (_selectedLevel != null) {
        await prefs.setString('onboarding_level', _selectedLevel!);
      }
      await prefs.setInt('onboarding_score', _score);
    } catch (e) {
      // SharedPreferences plugin unavailable (needs full app rebuild).
      // Onboarding progress won't persist, but flow still works.
      print('SharedPreferences unavailable, progress not saved: $e');
    }
  }

  void _handleOptionSelected(OnboardingQuestion question, String option) {
    if (_selectedOption != null || _isTransitioning) return;

    setState(() {
      _selectedOption = option;
      _isCorrect = option == question.correct;
      if (_isCorrect!) {
        _score++;
      } else {
        _shake();
      }
      _isTransitioning = true;
    });

    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _selectedOption = null;
        _isCorrect = null;
        _isTransitioning = false;
        
        if (_quizProgress < 2) {
          _quizProgress++;
        } else {
          _currentStep = OnboardingStep.celebration;
          _saveOnboardingProgress();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = _getProgressPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRM Learning'),
        centerTitle: true,
        leading: _currentStep == OnboardingStep.directSignIn
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentStep = _previousStep;
                  });
                },
              )
            : (_currentStep != OnboardingStep.purpose &&
                    _currentStep != OnboardingStep.celebration &&
                    _currentStep != OnboardingStep.registration
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        if (_currentStep == OnboardingStep.quiz) {
                          if (_quizProgress > 0) {
                            _quizProgress--;
                          } else {
                            _currentStep = OnboardingStep.level;
                          }
                        } else if (_currentStep == OnboardingStep.level) {
                          _currentStep = OnboardingStep.purpose;
                        }
                      });
                    },
                  )
                : null),
        actions: <Widget>[
          if (_currentStep != OnboardingStep.directSignIn && _currentStep != OnboardingStep.registration)
            TextButton(
              onPressed: () {
                setState(() {
                  _previousStep = _currentStep;
                  _currentStep = OnboardingStep.directSignIn;
                });
              },
              child: const Text('Sign In'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStepContent(context),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case OnboardingStep.purpose:
        return _buildPurposeScreen(context);
      case OnboardingStep.level:
        return _buildLevelScreen(context);
      case OnboardingStep.quiz:
        return _buildQuizScreen(context);
      case OnboardingStep.celebration:
        return _buildCelebrationScreen(context);
      case OnboardingStep.registration:
        return _buildRegistrationScreen(context);
      case OnboardingStep.directSignIn:
        return _buildDirectSignInScreen(context);
    }
  }

  Widget _buildPurposeScreen(BuildContext context) {
    final theme = Theme.of(context);

    final purposes = [
      {'title': '✈️ Travel & Culture', 'value': 'travel', 'desc': 'Learn to connect, navigate, and blend in abroad.'},
      {'title': '💼 Career Growth', 'value': 'career', 'desc': 'Advance your professional opportunities and networks.'},
      {'title': '🧠 Brain Training', 'value': 'fun', 'desc': 'Keep your mind active and improve cognitive agility.'},
    ];

    return SingleChildScrollView(
      key: const ValueKey<String>('purpose_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'What is your main purpose for learning?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We will tailor your learning path based on your goals.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...purposes.map((p) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedPurpose = p['value'];
                    _currentStep = OnboardingStep.level;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        p['title']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['desc']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelScreen(BuildContext context) {
    final theme = Theme.of(context);

    final levels = [
      {
        'title': '👶 I am brand new',
        'value': 'BEGINNER',
        'desc': 'Start from absolute scratch with common words and basic grammar.'
      },
      {
        'title': '🚀 I know some basics',
        'value': 'EXPERIENCED',
        'desc': 'Jump straight into intermediate syntax, dialogues, and exercises.'
      },
    ];

    return SingleChildScrollView(
      key: const ValueKey<String>('level_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Select your starting level',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We will fork the next micro-lesson based on your background.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...levels.map((l) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedLevel = l['value'];
                    _quizProgress = 0;
                    _score = 0;
                    _currentStep = OnboardingStep.quiz;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l['title']!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l['desc']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuizScreen(BuildContext context) {
    final theme = Theme.of(context);
    final List<OnboardingQuestion> questions = onboardingQuiz[_selectedLevel] ?? onboardingQuiz['BEGINNER']!;
    final OnboardingQuestion currentQuestion = questions[_quizProgress];

    // Shake offset for wrong answers
    final double offset = (1 - _shakeController.value) * 10 *
        math.sin(_shakeController.value * math.pi * 4);

    return Center(
      key: const ValueKey<String>('quiz_screen'),
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Question ${_quizProgress + 1} of 3',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                currentQuestion.question,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...currentQuestion.options.map((option) {
                final bool isSelected = _selectedOption == option;
                final bool isCorrect = option == currentQuestion.correct;
                
                Color cardColor = theme.cardColor;
                Color textColor = theme.colorScheme.onSurface;
                BorderSide border = BorderSide(color: theme.colorScheme.outlineVariant);

                if (_selectedOption != null) {
                  if (isCorrect) {
                    cardColor = Colors.green.shade50;
                    textColor = Colors.green.shade900;
                    border = BorderSide(color: Colors.green.shade400, width: 2);
                  } else if (isSelected) {
                    cardColor = Colors.red.shade50;
                    textColor = Colors.red.shade900;
                    border = BorderSide(color: Colors.red.shade400, width: 2);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: border,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _handleOptionSelected(currentQuestion, option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  option,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: textColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_selectedOption != null)
                                Icon(
                                  isCorrect ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationScreen(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const ValueKey<String>('celebration_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 24),
          Icon(
            Icons.stars_rounded,
            size: 100,
            color: Colors.amber.shade600,
          ),
          const SizedBox(height: 24),
          Text(
            'Micro-lesson Complete!',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You answered $_score of 3 questions correctly. Let\'s lock in your achievements.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    children: [
                      Text(
                        '+150',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'XP Unlocked',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Column(
                    children: [
                      Text(
                        '3/3',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Words Mastered',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () {
              setState(() {
                _currentStep = OnboardingStep.registration;
              });
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue to Lock In Progress', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationScreen(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const ValueKey<String>('registration_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Create a free account to lock in your 150 XP and start Unit 1.',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: ClerkAuthentication(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectSignInScreen(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const ValueKey<String>('direct_sign_in_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PRM Learning',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your potential. Learn, practice, and master skills at your own pace.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: ClerkAuthentication(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


