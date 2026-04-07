import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'battle_room_screen.dart';
import 'battle_service.dart';
import 'coin_service.dart';
import 'screen_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bonusHandled = false;

  Future<void> _showSignupBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _bonusHandled || !mounted) return;

    _bonusHandled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryColor,
          content: const Text(
            'Signup Bonus +500 coins added to your wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'signupBonusPending': false,
      }, SetOptions(merge: true));
    });
  }

  Future<void> _showPlayOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Battle Entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will be matched with any ready player in the same tier.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _PlayOptionTile(
                  label: 'Free Battle',
                  amount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    _startBattle(0);
                  },
                ),
                const SizedBox(height: 10),
                _PlayOptionTile(
                  label: '25 Coin Battle',
                  amount: 25,
                  onTap: () {
                    Navigator.pop(context);
                    _startBattle(25);
                  },
                ),
                const SizedBox(height: 10),
                _PlayOptionTile(
                  label: '50 Coin Battle',
                  amount: 50,
                  onTap: () {
                    Navigator.pop(context);
                    _startBattle(50);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startBattle(int entryFee) async {
    try {
      final battleId = await BattleService.createOrJoinBattle(entryFee: entryFee);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BattleRoomScreen(battleId: battleId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data?['signupBonusPending'] == true) {
          _showSignupBonus();
        }

        final username =
            (data?['username'] as String?)?.trim().isNotEmpty == true
            ? (data?['username'] as String).trim()
            : (user?.displayName ?? 'Player').trim();
        final photoUrl = (data?['photo'] as String?)?.trim().isNotEmpty == true
            ? (data?['photo'] as String).trim()
            : user?.photoURL;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: _TopBarTitle(username: username, photoUrl: photoUrl),
            actions: const [_CoinBadge(), SizedBox(width: 16)],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _TournamentBanner(),
              const SizedBox(height: 22),
              _PrimaryPlayButton(
                onTap: _showPlayOptions,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Daily Battles',
                      icon: Icons.bolt_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily Battles tapped'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _QuickActionButton(
                      title: 'Weekly Battles',
                      icon: Icons.calendar_today_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Weekly Battles tapped'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Active Room',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              const _MyBattleRoomsSection(),
            ],
          ),
        );
      },
    );
  }
}

class _TopBarTitle extends StatelessWidget {
  const _TopBarTitle({required this.username, required this.photoUrl});

  final String username;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: primaryColor.withValues(alpha: 0.14),
          backgroundImage: (photoUrl ?? '').isEmpty
              ? null
              : NetworkImage(photoUrl!),
          child: (photoUrl ?? '').isEmpty
              ? const Icon(Icons.person, color: primaryColor)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              Text(
                username,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TournamentBanner extends StatelessWidget {
  const _TournamentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6A38), primaryColor, Color(0xFF8F2A0A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FF4B11),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mega Tournament',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Win Big Rewards',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Join Now tapped'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Join Now',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPlayButton extends StatelessWidget {
  const _PrimaryPlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 0,
        ),
        child: Text(
          'Play Now',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isDark ? cardBackground : Colors.grey.shade100,
          border: Border.all(color: primaryColor.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayOptionTile extends StatelessWidget {
  const _PlayOptionTile({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  final String label;
  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isDark ? cardBackground : Colors.grey.shade100,
          border: Border.all(color: primaryColor.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.flash_on_rounded, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                amount == 0 ? 'FREE' : '$amount',
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyBattleRoomsSection extends StatelessWidget {
  const _MyBattleRoomsSection();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: BattleService.myBattlesStream(),
      builder: (context, snapshot) {
        final docs = (snapshot.data ?? const [])
            .where((doc) {
              final data = doc.data();
              final status = data['status'] as String? ?? 'waiting';
              final dismissedBy = List<String>.from(data['dismissedBy'] as List<dynamic>? ?? []);
              return uid != null &&
                  !dismissedBy.contains(uid) &&
                  (status == 'waiting' || status == 'matched' || status == 'ongoing');
            })
            .toList();
        if (docs.isEmpty) {
          return const Text('No active rooms right now');
        }

        final doc = docs.first;
        return _BattleRoomTile(data: doc.data(), battleId: doc.id);
      },
    );
  }
}

class _BattleRoomTile extends StatelessWidget {
  const _BattleRoomTile({
    required this.data,
    required this.battleId,
  });

  final Map<String, dynamic> data;
  final String battleId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final players = Map<String, dynamic>.from(
      (data['players'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
    String opponentName = 'Waiting for opponent...';
    for (final entry in players.entries) {
      if (entry.key != uid) {
        final player = Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
        opponentName = (player['name'] as String?) ?? opponentName;
        break;
      }
    }
    final status = data['status'] as String? ?? 'waiting';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BattleRoomScreen(battleId: battleId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).brightness == Brightness.dark
              ? cardBackground
              : Colors.grey.shade100,
          border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.9),
                    const Color(0xFFFF7B4D),
                  ],
                ),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entry Fee: ${(data['entryFee'] as num?)?.toInt() ?? 0} coins',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: CoinService.coinStream(),
      builder: (context, snapshot) {
        final coins = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primaryColor.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      },
    );
  }
}
