import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/multiplayer_models.dart';
import '../providers/multiplayer_match_provider.dart';
import 'multiplayer_match_screen.dart';
import 'multiplayer_result_screen.dart';

class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends ConsumerState<MultiplayerLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiplayerMatchProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiplayerMatchProvider);
    final notifier = ref.read(multiplayerMatchProvider.notifier);
    final theme = Theme.of(context);

    // Listen for errors and trigger standard snackbars
    ref.listen<MultiplayerMatchState>(multiplayerMatchProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        notifier.clearError();
      }

      if (next.status == MultiplayerStatus.playing) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const MultiplayerMatchScreen(),
          ),
        );
      } else if (next.status == MultiplayerStatus.finished) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const MultiplayerResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đấu Trường 1v1'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            notifier.disconnect();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: _buildBody(context, state, notifier, theme),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MultiplayerMatchState state,
    MultiplayerMatchNotifier notifier,
    ThemeData theme,
  ) {
    switch (state.status) {
      case MultiplayerStatus.connecting:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Đang kết nối đến đấu trường...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        );
      case MultiplayerStatus.disconnected:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Mất kết nối đến máy chủ.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => notifier.init(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử kết nối lại'),
              ),
            ],
          ),
        );
      case MultiplayerStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Đã xảy ra lỗi kết nối.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => notifier.init(),
                child: const Text('Tải lại'),
              ),
            ],
          ),
        );
      case MultiplayerStatus.queueing:
        return _buildQueueingView(context, state, notifier, theme);
      case MultiplayerStatus.inRoom:
        return _buildRoomView(context, state, notifier, theme);
      case MultiplayerStatus.lobby:
      default:
        return _buildLobbySelectionView(context, state, notifier, theme);
    }
  }

  // Lobby selection view: Quick match, Create room, Join room
  Widget _buildLobbySelectionView(
    BuildContext context,
    MultiplayerMatchState state,
    MultiplayerMatchNotifier notifier,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Chọn chế độ đấu',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tranh tài kiến thức Anh ngữ thời gian thực 1v1 cùng người học khác!',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Quick Match Card
          Card(
            elevation: 2,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => notifier.joinQueue(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.flash_on_rounded, color: theme.colorScheme.primary, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đấu Nhanh',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ghép ngẫu nhiên với một người chơi trực tuyến.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Create Private Room Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => notifier.createPrivateRoom(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_box_rounded, color: theme.colorScheme.secondary, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo Phòng Riêng',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tạo phòng và nhận mã phòng để chia sẻ với bạn bè.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Join Room with Code Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.vpn_key_rounded, color: theme.colorScheme.tertiary, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Vào Phòng Bằng Mã',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          maxLength: 6,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Nhập mã 6 ký tự',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          final code = _codeController.text.trim();
                          if (code.length == 6) {
                            notifier.joinPrivateRoom(code);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mã phòng phải gồm 6 ký tự.')),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Vào'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Queueing view showing search radar / spinner
  Widget _buildQueueingView(
    BuildContext context,
    MultiplayerMatchState state,
    MultiplayerMatchNotifier notifier,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              Icon(Icons.flash_on_rounded, size: 48, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'Đang tìm đối thủ phù hợp...',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng chờ trong giây lát.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          OutlinedButton.icon(
            onPressed: () => notifier.leaveQueue(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Hủy Tìm Kiếm'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // Room view before private match starts
  Widget _buildRoomView(
    BuildContext context,
    MultiplayerMatchState state,
    MultiplayerMatchNotifier notifier,
    ThemeData theme,
  ) {
    final myUserId = ref.watch(currentUserProvider).value?.id;
    final myPlayer = state.players.firstWhere(
      (p) => p.userId == myUserId,
      orElse: () => const MatchPlayer(userId: '', fullName: '', avatarUrl: ''),
    );
    final hasOpponent = state.players.length >= 2;
    final opponent = hasOpponent ? state.players.firstWhere((p) => p.userId != myPlayer.userId) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'MÃ PHÒNG RIÊNG',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.roomCode ?? '',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: state.roomCode ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã phòng!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Thành viên trong phòng',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Display Both Players side by side
        Row(
          children: [
            Expanded(child: _buildPlayerRoomCard(theme, myPlayer, 'Bạn')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            Expanded(
              child: opponent != null
                  ? _buildPlayerRoomCard(theme, opponent, 'Đối thủ')
                  : _buildEmptyOpponentCard(theme),
            ),
          ],
        ),
        const Spacer(),

        // Action Buttons
        if (hasOpponent) ...[
          if (!myPlayer.isReady)
            FilledButton.icon(
              onPressed: () => notifier.ready(),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('SẴN SÀNG'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Đã sẵn sàng. Đang chờ đối thủ...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Đang chờ đối thủ tham gia...'),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => notifier.leaveRoom(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('THOÁT PHÒNG'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPlayerRoomCard(ThemeData theme, MatchPlayer player, String role) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
              child: player.avatarUrl.isEmpty ? const Icon(Icons.person, size: 36) : null,
            ),
            const SizedBox(height: 16),
            Text(
              player.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            // Ready status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: player.isReady
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player.isReady ? 'SẴN SÀNG' : 'CHƯA READY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: player.isReady ? Colors.green : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOpponentCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          style: BorderStyle.values[1], // Dashed border in practice
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person_add_rounded, size: 36, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Trống',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              'Đang đợi...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
