import 'package:flutter/material.dart';

import '../routes/app_router.dart';

class PrmApp extends StatelessWidget {
  const PrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PRM Frontend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
