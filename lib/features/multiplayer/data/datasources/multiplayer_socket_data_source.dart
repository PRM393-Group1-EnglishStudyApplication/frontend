import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/multiplayer_models.dart';

class MultiplayerSocketDataSource {
  final String _baseUrl;
  socket_io.Socket? _socket;

  // Event callbacks
  void Function()? onConnectCallback;
  void Function(String reason)? onDisconnectCallback;
  void Function(dynamic error)? onConnectErrorCallback;
  void Function(String message)? onMatchErrorCallback;
  void Function(String roomCode, List<MatchPlayer> players)? onRoomUpdatedCallback;
  void Function(String matchId, int totalQuestions, List<MatchPlayer> players)? onMatchStartedCallback;
  void Function(MatchQuestion question)? onQuestionNextCallback;
  void Function(int questionIndex, bool correct)? onAnswerAckCallback;
  void Function(
    int index,
    String correctAnswer,
    String? scorerUserId,
    Map<String, int> scores,
  )? onQuestionClosedCallback;
  void Function(MatchResult result)? onMatchFinishedCallback;
  void Function(String reason)? onOpponentLeftCallback;
  void Function(Map<String, dynamic> data)? onRoomReconnectedCallback;

  MultiplayerSocketDataSource(this._baseUrl);

  bool get isConnected => _socket?.connected ?? false;

  void connect(String Function() getToken) {
    // If socket exists, clean it up first
    disconnect();

    final String cleanBaseUrl = _baseUrl.replaceAll(RegExp(r'/+$'), '');

    _socket = socket_io.io(
      '$cleanBaseUrl/multiplayer',
      socket_io.OptionBuilder()
          // socket_io_client on native platforms (dart:io) only implements the
          // websocket transport: requesting 'polling' still opens a WebSocket
          // but with transport=polling in the query, which the server rejects
          // before the handshake — the connection dies with no server logs.
          .setTransports(<String>['websocket'])
          // Clerk JWTs expire after ~60s: resolve the token lazily so every
          // reconnect attempt sends a fresh one instead of the initial JWT.
          .setAuthFn((void Function(Map<dynamic, dynamic> auth) callback) {
            callback(<String, dynamic>{'token': getToken()});
          })
          // Server handshake verifies the token with Clerk; allow it time.
          .setTimeout(20000)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(5)
          .disableAutoConnect()
          .build(),
    );

    // Register basic socket listeners
    _socket!.onConnect((_) {
      if (onConnectCallback != null) onConnectCallback!();
    });

    _socket!.onDisconnect((dynamic reason) {
      if (onDisconnectCallback != null) {
        onDisconnectCallback!(reason?.toString() ?? 'unknown');
      }
    });

    _socket!.onConnectError((dynamic err) {
      if (onConnectErrorCallback != null) onConnectErrorCallback!(err);
    });

    // Register game-specific socket listeners
    _socket!.on('match:error', (dynamic data) {
      if (onMatchErrorCallback != null && data is Map) {
        onMatchErrorCallback!(data['message'] as String? ?? 'Đã xảy ra lỗi.');
      }
    });

    _socket!.on('room:updated', (dynamic data) {
      if (onRoomUpdatedCallback != null && data is Map) {
        final roomCode = data['roomCode'] as String? ?? '';
        final playerList = data['players'] as List<dynamic>? ?? [];
        final players = playerList
            .map((dynamic p) => MatchPlayer.fromJson(p as Map<String, dynamic>))
            .toList();
        onRoomUpdatedCallback!(roomCode, players);
      }
    });

    _socket!.on('match:started', (dynamic data) {
      if (onMatchStartedCallback != null && data is Map) {
        final matchId = data['matchId'] as String? ?? '';
        final totalQuestions = data['totalQuestions'] as int? ?? 10;
        final playerList = data['players'] as List<dynamic>? ?? [];
        final players = playerList
            .map((dynamic p) => MatchPlayer.fromJson(p as Map<String, dynamic>))
            .toList();
        onMatchStartedCallback!(matchId, totalQuestions, players);
      }
    });

    _socket!.on('question:next', (dynamic data) {
      if (onQuestionNextCallback != null && data is Map) {
        final question = MatchQuestion.fromJson(data as Map<String, dynamic>);
        onQuestionNextCallback!(question);
      }
    });

    _socket!.on('answer:ack', (dynamic data) {
      if (onAnswerAckCallback != null && data is Map) {
        final questionIndex = data['questionIndex'] as int? ?? 0;
        final correct = data['correct'] as bool? ?? false;
        onAnswerAckCallback!(questionIndex, correct);
      }
    });

    _socket!.on('question:closed', (dynamic data) {
      if (onQuestionClosedCallback != null && data is Map) {
        final index = data['index'] as int? ?? 0;
        final correctAnswer = data['correctAnswer'] as String? ?? '';
        final scorerUserId = data['scorerUserId'] as String?;
        final rawScores = data['scores'] as Map<String, dynamic>? ?? {};
        final scores = rawScores.map((key, value) => MapEntry(key, (value as num).toInt()));
        onQuestionClosedCallback!(index, correctAnswer, scorerUserId, scores);
      }
    });

    _socket!.on('match:finished', (dynamic data) {
      if (onMatchFinishedCallback != null && data is Map) {
        final result = MatchResult.fromJson(data as Map<String, dynamic>);
        onMatchFinishedCallback!(result);
      }
    });

    _socket!.on('opponent:left', (dynamic data) {
      if (onOpponentLeftCallback != null && data is Map) {
        onOpponentLeftCallback!(data['reason'] as String? ?? 'disconnect');
      }
    });

    _socket!.on('room:reconnected', (dynamic data) {
      if (onRoomReconnectedCallback != null && data is Map) {
        onRoomReconnectedCallback!(data as Map<String, dynamic>);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
    }
  }

  // Client actions
  void joinQueue() {
    _socket?.emit('queue:join');
  }

  void leaveQueue() {
    _socket?.emit('queue:leave');
  }

  void createPrivateRoom(void Function(String roomCode) onCreated) {
    _socket?.emitWithAck('room:create', {}, ack: (dynamic response) {
      if (response is Map && response['roomCode'] != null) {
        onCreated(response['roomCode'] as String);
      } else if (response is Map && response['error'] != null) {
        if (onMatchErrorCallback != null) {
          onMatchErrorCallback!(response['error'] as String);
        }
      }
    });
  }

  void joinPrivateRoom(String roomCode, void Function(bool success, String? error) onJoined) {
    _socket?.emitWithAck('room:join', <String, dynamic>{'roomCode': roomCode}, ack: (dynamic response) {
      if (response is Map) {
        final ok = response['ok'] as bool? ?? false;
        final err = response['error'] as String?;
        onJoined(ok, err);
      } else {
        onJoined(false, 'Phản hồi không hợp lệ từ máy chủ.');
      }
    });
  }

  void ready() {
    _socket?.emit('player:ready');
  }

  void submitAnswer(String matchId, int questionIndex, String answer) {
    _socket?.emit('answer:submit', <String, dynamic>{
      'matchId': matchId,
      'questionIndex': questionIndex,
      'answer': answer,
    });
  }

  void leaveRoom() {
    _socket?.emit('room:leave');
  }
}
