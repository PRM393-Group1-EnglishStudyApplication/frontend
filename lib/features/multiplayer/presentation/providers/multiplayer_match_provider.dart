import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/multiplayer_socket_data_source.dart';
import '../../data/models/multiplayer_models.dart';

enum MultiplayerStatus {
  disconnected,
  connecting,
  lobby,
  queueing,
  inRoom,
  playing,
  intermission,
  finished,
  error,
}

class MultiplayerMatchState {
  final MultiplayerStatus status;
  final String? errorMessage;
  final String? roomCode;
  final String? matchId;
  final List<MatchPlayer> players;
  final MatchQuestion? currentQuestion;
  final String? lastCorrectAnswer;
  final String? lastScorerUserId;
  final bool isAnswerAckReceived;
  final bool isMyLastAnswerCorrect;
  final bool isMySubmitLocked;
  final MatchResult? matchResult;
  final String? disconnectReason;
  final int totalQuestions;
  final Map<String, int> playerScores;

  const MultiplayerMatchState({
    this.status = MultiplayerStatus.disconnected,
    this.errorMessage,
    this.roomCode,
    this.matchId,
    this.players = const [],
    this.currentQuestion,
    this.lastCorrectAnswer,
    this.lastScorerUserId,
    this.isAnswerAckReceived = false,
    this.isMyLastAnswerCorrect = false,
    this.isMySubmitLocked = false,
    this.matchResult,
    this.disconnectReason,
    this.totalQuestions = 10,
    this.playerScores = const {},
  });

  // Sentinel so copyWith can tell "not passed" apart from "explicitly null":
  // errorMessage and lastScorerUserId must be clearable (null scorer = nobody
  // answered correctly; with plain `??` the previous winner would stick).
  static const Object _unset = Object();

  MultiplayerMatchState copyWith({
    MultiplayerStatus? status,
    Object? errorMessage = _unset,
    String? roomCode,
    String? matchId,
    List<MatchPlayer>? players,
    MatchQuestion? currentQuestion,
    String? lastCorrectAnswer,
    Object? lastScorerUserId = _unset,
    bool? isAnswerAckReceived,
    bool? isMyLastAnswerCorrect,
    bool? isMySubmitLocked,
    MatchResult? matchResult,
    String? disconnectReason,
    int? totalQuestions,
    Map<String, int>? playerScores,
  }) {
    return MultiplayerMatchState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      roomCode: roomCode ?? this.roomCode,
      matchId: matchId ?? this.matchId,
      players: players ?? this.players,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastCorrectAnswer: lastCorrectAnswer ?? this.lastCorrectAnswer,
      lastScorerUserId:
          identical(lastScorerUserId, _unset) ? this.lastScorerUserId : lastScorerUserId as String?,
      isAnswerAckReceived: isAnswerAckReceived ?? this.isAnswerAckReceived,
      isMyLastAnswerCorrect: isMyLastAnswerCorrect ?? this.isMyLastAnswerCorrect,
      isMySubmitLocked: isMySubmitLocked ?? this.isMySubmitLocked,
      matchResult: matchResult ?? this.matchResult,
      disconnectReason: disconnectReason ?? this.disconnectReason,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      playerScores: playerScores ?? this.playerScores,
    );
  }
}

class MultiplayerMatchNotifier extends StateNotifier<MultiplayerMatchState> {
  final Ref _ref;
  MultiplayerSocketDataSource? _dataSource;

  MultiplayerMatchNotifier(this._ref) : super(const MultiplayerMatchState());

  void init() {
    // Already connected: nothing to do. A disconnected data source must be
    // rebuilt, otherwise the "retry" button becomes a no-op.
    if (_dataSource != null && _dataSource!.isConnected) return;

    final token = _ref.read(clerkTokenProvider);
    if (token == null) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Bạn cần đăng nhập để tham gia đấu 1v1.',
      );
      return;
    }

    // Dispose any stale (disconnected or still-retrying) socket before
    // building a fresh one.
    _dataSource?.disconnect();

    final rawUrl = dotenv.get('API_BASE_URL', fallback: 'https://backend-6i8r.onrender.com');
    _dataSource = MultiplayerSocketDataSource(rawUrl);

    // Register callbacks
    _dataSource!.onConnectCallback = () {
      state = state.copyWith(
        status: MultiplayerStatus.lobby,
        errorMessage: null,
      );
    };

    _dataSource!.onDisconnectCallback = (String reason) {
      debugPrint('Multiplayer socket disconnected: $reason');
      state = state.copyWith(status: MultiplayerStatus.disconnected);
    };

    _dataSource!.onConnectErrorCallback = (err) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Không thể kết nối đến máy chủ: $err',
      );
    };

    _dataSource!.onMatchErrorCallback = (message) {
      state = state.copyWith(
        status: MultiplayerStatus.lobby, // Go back to lobby or keep state
        errorMessage: message,
      );
    };

    _dataSource!.onRoomUpdatedCallback = (roomCode, players) {
      state = state.copyWith(
        status: MultiplayerStatus.inRoom,
        roomCode: roomCode,
        players: players,
        errorMessage: null,
      );
    };

    _dataSource!.onMatchStartedCallback = (matchId, totalQuestions, players) {
      state = state.copyWith(
        status: MultiplayerStatus.inRoom,
        matchId: matchId,
        totalQuestions: totalQuestions,
        players: players,
        errorMessage: null,
      );
    };

    _dataSource!.onQuestionNextCallback = (question) {
      state = state.copyWith(
        status: MultiplayerStatus.playing,
        currentQuestion: question,
        isAnswerAckReceived: false,
        isMyLastAnswerCorrect: false,
        isMySubmitLocked: false,
        errorMessage: null,
      );
    };

    _dataSource!.onAnswerAckCallback = (questionIndex, correct) {
      if (state.currentQuestion?.index == questionIndex) {
        state = state.copyWith(
          isAnswerAckReceived: true,
          isMyLastAnswerCorrect: correct,
          isMySubmitLocked: !correct,
        );
      }
    };

    _dataSource!.onQuestionClosedCallback = (index, correctAnswer, scorerUserId, scores) {
      state = state.copyWith(
        status: MultiplayerStatus.intermission,
        lastCorrectAnswer: correctAnswer,
        lastScorerUserId: scorerUserId,
        playerScores: scores,
      );
    };

    _dataSource!.onMatchFinishedCallback = (result) {
      state = state.copyWith(
        status: MultiplayerStatus.finished,
        matchResult: result,
      );
    };

    _dataSource!.onOpponentLeftCallback = (reason) {
      state = state.copyWith(
        disconnectReason: reason,
      );
    };

    _dataSource!.onRoomReconnectedCallback = (data) {
      final statusStr = data['status'] as String? ?? 'playing';
      MultiplayerStatus mStatus = MultiplayerStatus.playing;
      if (statusStr == 'intermission') {
        mStatus = MultiplayerStatus.intermission;
      } else if (statusStr == 'finished') {
        mStatus = MultiplayerStatus.finished;
      } else if (statusStr == 'waiting' || statusStr == 'ready') {
        // Match hasn't started: back to the room view, not the match screen.
        mStatus = MultiplayerStatus.inRoom;
      }

      final playerList = data['players'] as List<dynamic>? ?? [];
      final players = playerList
          .map((dynamic p) => MatchPlayer.fromJson(p as Map<String, dynamic>))
          .toList();

      final rawScores = data['scores'] as Map<String, dynamic>? ?? {};
      final scores = rawScores.map((key, value) => MapEntry(key, (value as num).toInt()));

      final questionData = data['exercise'];
      MatchQuestion? curQ;
      if (questionData != null) {
        curQ = MatchQuestion.fromJson(<String, dynamic>{
          'index': data['currentQuestionIndex'] ?? 0,
          'endsAt': data['endsAt'] ?? DateTime.now().toIso8601String(),
          'exercise': questionData,
        });
      }

      state = state.copyWith(
        status: mStatus,
        matchId: data['matchId'] as String?,
        roomCode: data['roomCode'] as String?,
        players: players.isNotEmpty ? players : null,
        currentQuestion: curQ,
        lastCorrectAnswer: data['correctAnswer'] as String?,
        playerScores: scores,
        isMySubmitLocked: data['isLocked'] as bool? ?? false,
        errorMessage: null,
      );
    };

    state = state.copyWith(status: MultiplayerStatus.connecting);
    // Lazy getter: every (re)connect handshake reads the latest Clerk JWT
    // from Riverpod instead of reusing the token captured at init time.
    _dataSource!.connect(() => _ref.read(clerkTokenProvider) ?? token);
  }

  void joinQueue() {
    state = state.copyWith(status: MultiplayerStatus.queueing, errorMessage: null);
    _dataSource?.joinQueue();
  }

  void leaveQueue() {
    _dataSource?.leaveQueue();
    state = state.copyWith(status: MultiplayerStatus.lobby);
  }

  void createPrivateRoom() {
    state = state.copyWith(status: MultiplayerStatus.connecting, errorMessage: null);
    _dataSource?.createPrivateRoom((roomCode) {
      state = state.copyWith(
        status: MultiplayerStatus.inRoom,
        roomCode: roomCode,
        errorMessage: null,
      );
    });
  }

  void joinPrivateRoom(String roomCode) {
    state = state.copyWith(status: MultiplayerStatus.connecting, errorMessage: null);
    _dataSource?.joinPrivateRoom(roomCode, (success, error) {
      if (!success) {
        state = state.copyWith(
          status: MultiplayerStatus.lobby,
          errorMessage: error ?? 'Không thể vào phòng riêng.',
        );
      }
    });
  }

  void ready() {
    _dataSource?.ready();
  }

  void submitAnswer(String answer) {
    final matchId = state.matchId;
    final currentQ = state.currentQuestion;
    if (matchId == null || currentQ == null || state.isMySubmitLocked) return;

    _dataSource?.submitAnswer(matchId, currentQ.index, answer);
  }

  void leaveRoom() {
    _dataSource?.leaveRoom();
    state = const MultiplayerMatchState(
      status: MultiplayerStatus.lobby,
    );
  }

  void disconnect() {
    _dataSource?.disconnect();
    _dataSource = null;
    state = const MultiplayerMatchState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _dataSource?.disconnect();
    super.dispose();
  }
}

final StateNotifierProvider<MultiplayerMatchNotifier, MultiplayerMatchState> multiplayerMatchProvider =
    StateNotifierProvider<MultiplayerMatchNotifier, MultiplayerMatchState>((ref) {
  final notifier = MultiplayerMatchNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
