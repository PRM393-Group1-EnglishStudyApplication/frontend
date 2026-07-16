import '../../features/lessons/domain/entities/exercise_entities.dart';

class MatchingPair {
  final String? id;
  final String left;
  final String right;

  const MatchingPair({
    this.id,
    required this.left,
    required this.right,
  });
}

class MatchingCodec {
  static String encodeOption(String left, String right) {
    return '$left::$right';
  }

  static MatchingPair? decodeOption(String optionText, {String? id}) {
    final idx = optionText.indexOf('::');
    if (idx == -1) return null;
    final left = optionText.substring(0, idx);
    final right = optionText.substring(idx + 2);
    if (left.trim().isEmpty || right.trim().isEmpty) return null;
    return MatchingPair(id: id, left: left, right: right);
  }

  static List<MatchingPair> decodePairs(List<ExerciseOption> options) {
    final list = <MatchingPair>[];
    for (final opt in options) {
      final pair = decodeOption(opt.optionText, id: opt.id);
      if (pair != null) {
        list.add(pair);
      }
    }
    return list;
  }

  static String norm(String s) => s.trim().toLowerCase();

  static String canonicalAnswer(List<MatchingPair> pairs) {
    final tokens = pairs.map((p) => '${norm(p.left)}=${norm(p.right)}').toList();
    tokens.sort();
    return tokens.join(';');
  }

  static String? validateSide(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Không được để trống';
    }
    if (text.contains('::') || text.contains('=') || text.contains(';')) {
      return 'Không được chứa ký tự đặc biệt (::, =, ;)';
    }
    return null;
  }
}
