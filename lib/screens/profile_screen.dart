import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screen_constants.dart';
import 'theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final userStream = user == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.themeMode,
        builder: (context, themeMode, _) {
          final isDark = switch (themeMode) {
            ThemeMode.dark => true,
            ThemeMode.light => false,
            ThemeMode.system => brightness == Brightness.dark,
          };

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final game = (data?['game'] as String?)?.trim() ?? 'Not set';
              final gameId = (data?['gameId'] as String?)?.trim() ?? 'Not set';
              final username = (data?['username'] as String?)?.trim() ?? 'Not set';

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? cardBackground
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (user?.photoURL ?? '').isEmpty
                              ? null
                              : NetworkImage(user!.photoURL!),
                          child: (user?.photoURL ?? '').isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Player',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(user?.email ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProfileInfoTile(
                    label: 'Game',
                    value: game,
                    icon: Icons.sports_esports,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoTile(
                    label: 'Game ID',
                    value: gameId,
                    icon: Icons.badge_outlined,
                    trailing: gameId == 'Not set'
                        ? null
                        : IconButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: gameId));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Game ID copied'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy',
                          ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoTile(
                    label: 'Username',
                    value: username,
                    icon: Icons.alternate_email_rounded,
                    trailing: username == 'Not set'
                        ? null
                        : IconButton(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: username));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username copied'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy',
                          ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    value: isDark,
                    onChanged: AppThemeController.setDarkMode,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cardBackground
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
