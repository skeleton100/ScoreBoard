import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_color.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.settingsAppBar,
        foregroundColor: AppColors.textLight,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.palette, color: AppColors.primary),
                title: const Text('Theme', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Change app appearance', style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  // TODO: Navigate to theme settings
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.language, color: AppColors.secondary),
                title: const Text('Language', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Change app language', style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  // TODO: Navigate to language settings
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.notifications, color: AppColors.accent),
                title: const Text('Notifications', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Configure notifications', style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.info, color: AppColors.info),
                title: const Text('About', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('App information and version', style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  // TODO: Navigate to about screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
