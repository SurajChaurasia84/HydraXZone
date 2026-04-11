import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screen_constants.dart';
import 'theme_controller.dart';
import 'user_cache_service.dart';

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

          return FutureBuilder<Map<String, String>>(
            future: UserCacheService.load(),
            builder: (context, cacheSnapshot) {
              final cached = cacheSnapshot.data ?? const <String, String>{};
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: userStream,
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  if (data != null) {
                    UserCacheService.save(data);
                  }
                  final game = ((data?['game'] as String?) ?? cached['game'] ?? '').trim();
                  final gameId = ((data?['gameId'] as String?) ?? cached['gameId'] ?? '').trim();
                  final username =
                      ((data?['username'] as String?) ?? cached['username'] ?? '').trim();
                  final name = ((data?['name'] as String?) ?? cached['name'] ?? '').trim();
                  final email = ((data?['email'] as String?) ?? cached['email'] ?? '').trim();
                  final photo = ((data?['photo'] as String?) ?? cached['photo'] ?? '').trim();

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
                              backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                              child: photo.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? (user?.displayName ?? 'Player') : name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(email.isEmpty ? (user?.email ?? '') : email),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ProfileInfoTile(
                        label: 'Game',
                        value: game.isEmpty ? 'Not set' : game,
                        icon: Icons.sports_esports,
                      ),
                      const SizedBox(height: 12),
                      _ProfileInfoTile(
                        label: 'Game ID',
                        value: gameId.isEmpty ? 'Not set' : gameId,
                        icon: Icons.badge_outlined,
                        trailing: gameId.isEmpty
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
                        value: username.isEmpty ? 'Not set' : username,
                        icon: Icons.alternate_email_rounded,
                        trailing: username.isEmpty
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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_rounded, color: primaryColor),
                        title: const Text('Privacy Policy'),
                        onTap: () async {
                          final uri = Uri.parse('https://example.com/privacy-policy');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open link')),
                            );
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.gavel_rounded, color: primaryColor),
                        title: const Text('Battle Rules'),
                        onTap: () {
                          // TODO: implement actual screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Battle rules coming soon!')),
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.group_add_rounded, color: primaryColor),
                        title: const Text('Refer and Earn'),
                        onTap: () {
                          // TODO: implement actual screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refer and earn coming soon!')),
                          );
                        },
                      ),
                    ],
                  );
                },
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
