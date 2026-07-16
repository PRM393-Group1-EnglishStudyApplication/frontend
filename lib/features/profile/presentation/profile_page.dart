import 'package:flutter/material.dart';

import '../../../api/services/user_api_service.dart';
import '../../../core/widgets/feature_placeholder.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserApiService _userApiService = UserApiService();

  bool _loading = false;
  String? _apiStatus;

  Future<void> _testApi() async {
    setState(() {
      _loading = true;
      _apiStatus = 'Đang gọi API...';
    });
    try {
      final List<dynamic> users = await _userApiService.getUsers();
      if (!mounted) return;
      setState(() => _apiStatus = 'API OK — nhận ${users.length} user.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _apiStatus = 'API lỗi: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholder(
      title: 'Cá nhân',
      icon: Icons.person_rounded,
      subtitle:
          'Hồ sơ, tiến độ học và cài đặt sẽ xuất hiện ở đây.\n'
          'Kết nối API: /api/auth/me, /api/progress/me, /api/hearts/me.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _loading ? null : _testApi,
            icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: Text(_loading ? 'Đang kiểm tra...' : 'Kiểm tra kết nối API'),
          ),
          if (_apiStatus != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _apiStatus!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718078), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
