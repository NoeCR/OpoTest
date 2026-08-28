import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'weak_points_section.dart';

class RepasoScreen extends StatelessWidget {
  const RepasoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: const Text('Repaso'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.9), AppTheme.cardDark.withValues(alpha: 0.95)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: const [
          Text(
            'Qué leyes y títulos te cuestan más, para reforzarlos.',
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.35),
          ),
          SizedBox(height: 16),
          WeakPointsSection(),
        ],
      ),
    );
  }
}
