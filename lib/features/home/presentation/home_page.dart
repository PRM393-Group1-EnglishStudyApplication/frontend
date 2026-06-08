import 'package:flutter/material.dart';

import '../../../api/services/user_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserApiService _userApiService = UserApiService();

  bool _loading = false;
  String _message = 'Flutter FE is ready. Tap button to test API call.';

  Future<void> _testApi() async {
    setState(() {
      _loading = true;
      _message = 'Calling API...';
    });

    try {
      final List<dynamic> users = await _userApiService.getUsers();
      setState(() {
        _message = 'API success. Received ${users.length} users.';
      });
    } catch (error) {
      setState(() {
        _message = 'API error: $error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRM Frontend Home'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _testApi,
                child: Text(_loading ? 'Loading...' : 'Test API Route'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
