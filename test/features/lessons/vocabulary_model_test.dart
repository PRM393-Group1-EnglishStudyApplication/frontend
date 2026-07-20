import 'package:flutter_test/flutter_test.dart';
import 'package:prm_frontend/features/lessons/data/models/exercise_model.dart';

void main() {
  test('lesson vocabulary parses the seeded image URL', () {
    const imageUrl = 'https://assets.example.test/curriculum/hello.webp';

    final vocabulary = VocabularyModel.fromJson({
      '_id': 'vocabulary-id',
      'word': 'hello',
      'meaning': 'xin chào',
      'pronunciation': '/həˈləʊ/',
      'example_sentence': 'Hello, it is nice to meet you.',
      'image_url': imageUrl,
    });

    expect(vocabulary.imageUrl, imageUrl);
  });
}
