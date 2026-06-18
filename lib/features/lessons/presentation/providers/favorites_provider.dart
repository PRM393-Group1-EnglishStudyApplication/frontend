import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise_model.dart';
import 'lessons_providers.dart';

// Provider to fetch favorite vocabularies list from remote API
final favoriteVocabulariesProvider = FutureProvider<List<VocabularyModel>>((ref) async {
  final repository = ref.watch(lessonsRepositoryProvider);
  return repository.getFavoriteVocabularies();
});

// Notifier to manage the set of favorited vocabulary IDs (for fast lookup and optimistic UI)
class FavoritesNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final Ref _ref;

  FavoritesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Sync with favoriteVocabulariesProvider
    _ref.listen<AsyncValue<List<VocabularyModel>>>(
      favoriteVocabulariesProvider,
      (previous, next) {
        next.when(
          data: (list) {
            state = AsyncValue.data(list.map((v) => v.id).toSet());
          },
          error: (err, stack) => state = AsyncValue.error(err, stack),
          loading: () {
            if (state is! AsyncData) {
              state = const AsyncValue.loading();
            }
          },
        );
      },
      fireImmediately: true,
    );
  }

  Future<void> toggleFavorite(VocabularyModel vocab) async {
    final repository = _ref.read(lessonsRepositoryProvider);
    final currentSet = state.value ?? {};
    final isFav = currentSet.contains(vocab.id);

    // Optimistic UI update
    final newSet = Set<String>.from(currentSet);
    if (isFav) {
      newSet.remove(vocab.id);
    } else {
      newSet.add(vocab.id);
    }
    state = AsyncValue.data(newSet);

    try {
      if (isFav) {
        await repository.removeFavoriteVocabulary(vocab.id);
      } else {
        await repository.addFavoriteVocabulary(vocab.id);
      }
      // Refresh the list provider in the background
      _ref.invalidate(favoriteVocabulariesProvider);
    } catch (e) {
      // Revert state on error
      state = AsyncValue.data(currentSet);
      rethrow;
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<Set<String>>>((ref) {
  return FavoritesNotifier(ref);
});
