import 'package:flutter/material.dart';

/// Shared "coming soon" scaffold used by feature tabs that are not built yet.
///
/// Keeps every unfinished tab visually consistent with the chat feature's
/// design language (off-white background, green accent, rounded cards) so the
/// app feels like one product while the team fills each feature in.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
    this.child,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        titleSpacing: 18,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF17241F),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF1FC98F), Color(0xFF078F67)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0BAA73).withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF17241F),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle ?? 'Tính năng đang được phát triển.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718078),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                if (child != null) ...<Widget>[
                  const SizedBox(height: 24),
                  child!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
