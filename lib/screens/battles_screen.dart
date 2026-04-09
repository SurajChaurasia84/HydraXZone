import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screen_constants.dart';
import 'tournament_matches_screen.dart';
import 'tournament_service.dart';

class BattlesScreen extends StatelessWidget {
  const BattlesScreen({super.key});

  static const _pointsRules = [
    'Kill = 2 points',
    'Rank 1 = 10 points',
    'Rank 2-5 = 7 points',
    'Rank 6-10 = 5 points',
    'Rank 11-20 = 3 points',
    'Rank 21+ = 1 point',
    'Final score = sum of all 3 matches',
  ];
  static const _dailyRules = [
    'Entry fee: 50 coins',
    'Winner reward: 500 coins',
    'Single match with random players',
    'One user can participate only once per tournament',
  ];
  static const _weeklyRules = [
    'Entry fee: 500 coins',
    'Weekly battles go live every Sunday',
    'Other days are only for participation and registration',
    'Total 3 matches: Battle 1, Battle 2, Battle 3',
    'Final rank based on total points from all 3 matches',
    'Only registered players can participate on live day',
    'One user can participate only once per tournament',
  ];
  static const _megaRules = [
    'Entry fee: 1000 coins',
    'Mega tournament goes live on the 1st and 15th day of every month',
    'Other days are only for participation and registration',
    'Total 3 matches: Battle 1, Battle 2, Battle 3',
    'Final rank based on total points from all 3 matches',
    'Only registered players can participate on live day',
    'One user can participate only once per tournament',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battles'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.14)),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55FF4B11),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Mega'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TournamentTab(
              kind: _TournamentKind.daily,
              title: 'Daily Battles',
              subtitle: 'Quick fights with random players',
              entryFee: 50,
              rewardProducts: [],
              rules: _dailyRules,
              pointRules: _pointsRules,
              isMega: false,
              showMatches: false,
            ),
            _TournamentTab(
              kind: _TournamentKind.weekly,
              title: 'Weekly Tournament',
              subtitle: '3 battles. Highest total points wins.',
              entryFee: 500,
              rewardProducts: [
                _RewardProduct(
                  rankLabel: 'Rank 1',
                  title: 'Smart Watch',
                  assetPath: 'assets/watch.jpg',
                  amazonUrl: 'https://amzn.to/4c1TNPn',
                ),
                _RewardProduct(
                  rankLabel: 'Rank 2',
                  title: 'Premium T-shirt',
                  assetPath: 'assets/tshirt.jpg',
                  amazonUrl: 'https://amzn.to/4dzq01J',
                ),
                _RewardProduct(
                  rankLabel: 'Rank 3',
                  title: 'Bracelet Chain',
                  assetPath: 'assets/chain.jpg',
                  amazonUrl: 'https://amzn.to/4vihD0Q',
                ),
              ],
              rules: _weeklyRules,
              pointRules: _pointsRules,
              isMega: false,
              showMatches: true,
            ),
            _TournamentTab(
              kind: _TournamentKind.mega,
              title: 'Mega Tournament',
              subtitle: 'Big rewards every 15 days',
              entryFee: 1000,
              rewardProducts: [
                _RewardProduct(
                  rankLabel: 'Rank 1',
                  title: 'Boat earbuds',
                  assetPath: 'assets/boat.jpg',
                  amazonUrl: 'https://amzn.to/4dzDb2E',
                ),
                _RewardProduct(
                  rankLabel: 'Rank 2',
                  title: 'Smart watch',
                  assetPath: 'assets/watch.jpg',
                  amazonUrl: 'https://amzn.to/4c1TNPn',
                ),
                _RewardProduct(
                  rankLabel: 'Rank 3',
                  title: 'Premium T-shirt',
                  assetPath: 'assets/tshirt.jpg',
                  amazonUrl: 'https://amzn.to/4dzq01J',
                ),
              ],
              rules: _megaRules,
              pointRules: _pointsRules,
              isMega: true,
              showMatches: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentTab extends StatefulWidget {
  const _TournamentTab({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.entryFee,
    required this.rewardProducts,
    required this.rules,
    required this.pointRules,
    required this.isMega,
    required this.showMatches,
  });

  final _TournamentKind kind;
  final String title;
  final String subtitle;
  final int entryFee;
  final List<_RewardProduct> rewardProducts;
  final List<String> rules;
  final List<String> pointRules;
  final bool isMega;
  final bool showMatches;

  @override
  State<_TournamentTab> createState() => _TournamentTabState();
}

class _TournamentTabState extends State<_TournamentTab> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _TournamentCycle.forKind(widget.kind, _now);
    final countStream = FirebaseFirestore.instance
        .collection('tournament_registrations')
        .doc(cycle.id)
        .collection('participants')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final registrationStream = uid == null
        ? const Stream<DocumentSnapshot<Map<String, dynamic>>?>.empty()
        : FirebaseFirestore.instance
            .collection('tournament_registrations')
            .doc(cycle.id)
            .collection('participants')
            .doc(uid)
            .snapshots();

    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, countSnapshot) {
        final registeredCount = countSnapshot.data ?? 0;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          stream: registrationStream,
          builder: (context, registrationSnapshot) {
            final isRegistered = registrationSnapshot.data?.exists == true;
            final buttonLabel = _buttonLabel(
              kind: widget.kind,
              isRegistered: isRegistered,
              isLiveDay: cycle.isLiveDay,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _HeaderCard(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  entryFee: widget.entryFee,
                  isMega: widget.isMega,
                ),
                const SizedBox(height: 16),
                _CountdownCard(cycle: cycle),
                const SizedBox(height: 16),
                if (widget.isMega) ...[
                  const _MegaRewardPreview(),
                  const SizedBox(height: 16),
                ],
                _InfoCard(
                  title: 'Rewards',
                  icon: Icons.workspace_premium_rounded,
                  child: widget.rewardProducts.isEmpty
                      ? const _BulletRow(text: 'Winner: 500 coins')
                      : Column(
                          children: [
                            for (final reward in widget.rewardProducts) ...[
                              _RewardProductCard(product: reward),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
                if (widget.showMatches) ...[
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Match Structure',
                    icon: Icons.sports_mma_rounded,
                    child: const Row(
                      children: [
                        Expanded(child: _MatchPill(label: 'Battle 1')),
                        SizedBox(width: 10),
                        Expanded(child: _MatchPill(label: 'Battle 2')),
                        SizedBox(width: 10),
                        Expanded(child: _MatchPill(label: 'Battle 3')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Points System',
                  icon: Icons.bar_chart_rounded,
                  child: Column(
                    children: widget.pointRules
                        .map(
                          (rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BulletRow(text: rule),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Rules',
                  icon: Icons.rule_rounded,
                  child: Column(
                    children: widget.rules
                        .map(
                          (rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _BulletRow(text: rule),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '$registeredCount registered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _canRegister(
                    kind: widget.kind,
                    isRegistered: isRegistered,
                    isLiveDay: cycle.isLiveDay,
                  )
                      ? () => _register(cycle, isRegistered)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canRegister({
    required _TournamentKind kind,
    required bool isRegistered,
    required bool isLiveDay,
  }) {
    if (isRegistered && (kind == _TournamentKind.daily || isLiveDay)) return true;
    if (isRegistered) return false;
    if (kind == _TournamentKind.daily) return true;
    return !isLiveDay;
  }

  String _buttonLabel({
    required _TournamentKind kind,
    required bool isRegistered,
    required bool isLiveDay,
  }) {
    if (isRegistered && kind == _TournamentKind.daily) {
      return 'Open Battle';
    }
    if (isRegistered && isLiveDay) {
      return 'Open 3 Battles';
    }
    if (isRegistered) {
      return kind == _TournamentKind.daily ? 'Already Joined' : 'Registered';
    }
    if (kind != _TournamentKind.daily && isLiveDay) {
      return 'Registration Closed';
    }
    return switch (kind) {
      _TournamentKind.daily => 'Join Daily Battle',
      _TournamentKind.weekly => 'Register Weekly',
      _TournamentKind.mega => 'Register Mega',
    };
  }

  Future<void> _register(_TournamentCycle cycle, bool isRegistered) async {
    if (isRegistered && (widget.kind == _TournamentKind.daily || cycle.isLiveDay)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentMatchesScreen(
            title: widget.title,
            cycleId: cycle.id,
            liveStart: cycle.liveStart,
            battleCount: widget.kind == _TournamentKind.daily ? 1 : 3,
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please sign in to register'),
        ),
      );
      return;
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirm Registration'),
            content: Text(
              'Register for ${widget.title} by paying ${widget.entryFee} coins now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      await TournamentService.registerForTournament(
        cycleId: cycle.id,
        title: widget.title,
        type: widget.kind.name,
        entryFee: widget.entryFee,
        liveAt: cycle.liveStart,
        isLiveDay: cycle.isLiveDay,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryColor,
          content: Text('${widget.title} registration successful'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'already-registered' => 'You are already registered for this tournament.',
        'insufficient-coins' => 'Not enough coins to register.',
        _ => e.message ?? 'Unable to register right now.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
    }
  }
}

enum _TournamentKind { daily, weekly, mega }

class _TournamentCycle {
  const _TournamentCycle({
    required this.id,
    required this.liveStart,
    required this.liveEnd,
    required this.isLiveDay,
    required this.statusText,
    required this.countdownText,
  });

  final String id;
  final DateTime liveStart;
  final DateTime liveEnd;
  final bool isLiveDay;
  final String statusText;
  final String countdownText;

  static _TournamentCycle forKind(_TournamentKind kind, DateTime now) {
    return switch (kind) {
      _TournamentKind.daily => _daily(now),
      _TournamentKind.weekly => _weekly(now),
      _TournamentKind.mega => _mega(now),
    };
  }

  static _TournamentCycle _daily(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _TournamentCycle(
      id: 'daily-${_formatDate(start)}',
      liveStart: start,
      liveEnd: end,
      isLiveDay: true,
      statusText: 'Live today',
      countdownText: 'Ends in ${_formatDuration(end.difference(now))}',
    );
  }

  static _TournamentCycle _weekly(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final isLiveDay = now.weekday == DateTime.sunday;
    final liveStart = today.add(Duration(days: daysUntilSunday));
    final activeStart = isLiveDay ? today : liveStart;
    final activeEnd = activeStart.add(const Duration(days: 1));
    return _TournamentCycle(
      id: 'weekly-${_formatDate(activeStart)}',
      liveStart: activeStart,
      liveEnd: activeEnd,
      isLiveDay: isLiveDay,
      statusText: isLiveDay ? 'Live today' : 'Registration open',
      countdownText: isLiveDay
          ? 'Ends in ${_formatDuration(activeEnd.difference(now))}'
          : 'Live in ${_formatDuration(activeStart.difference(now))}',
    );
  }

  static _TournamentCycle _mega(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final isLiveDay = now.day == 1 || now.day == 15;
    final liveStart = _nextMegaLiveDay(today);
    final activeStart = isLiveDay ? today : liveStart;
    final activeEnd = activeStart.add(const Duration(days: 1));
    return _TournamentCycle(
      id: 'mega-${_formatDate(activeStart)}',
      liveStart: activeStart,
      liveEnd: activeEnd,
      isLiveDay: isLiveDay,
      statusText: isLiveDay ? 'Live today' : 'Registration open',
      countdownText: isLiveDay
          ? 'Ends in ${_formatDuration(activeEnd.difference(now))}'
          : 'Live in ${_formatDuration(activeStart.difference(now))}',
    );
  }

  static DateTime _nextMegaLiveDay(DateTime today) {
    if (today.day < 15) return DateTime(today.year, today.month, 15);
    return DateTime(today.year, today.month + 1, 1);
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final days = safe.inDays;
    final hours = safe.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    return '${hours}h ${minutes}m ${seconds}s';
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.cycle});

  final _TournamentCycle cycle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              cycle.isLiveDay ? Icons.bolt_rounded : Icons.timer_outlined,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(cycle.countdownText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardProduct {
  const _RewardProduct({
    required this.rankLabel,
    required this.title,
    required this.assetPath,
    required this.amazonUrl,
  });

  final String rankLabel;
  final String title;
  final String assetPath;
  final String amazonUrl;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.entryFee,
    required this.isMega,
  });

  final String title;
  final String subtitle;
  final int entryFee;
  final bool isMega;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMega
              ? const [Color(0xFFFFC14D), Color(0xFFFF7A18), Color(0xFF8A2D00)]
              : const [Color(0xFFFF6A38), primaryColor, Color(0xFF8F2A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: isMega ? const Color(0x66FFC14D) : const Color(0x55FF4B11),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMega)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'EVERY 15 DAYS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Entry Fee: $entryFee coins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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
            ),
            child: Icon(
              isMega ? Icons.rocket_launch_rounded : Icons.emoji_events_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _MegaRewardPreview extends StatelessWidget {
  const _MegaRewardPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: const Color(0xFFFFC14D).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/boat.jpg',
              height: 84,
              width: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mega Reward Highlight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rank 1 wins Boat earbuds.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Featured Reward',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RewardProductCard extends StatelessWidget {
  const _RewardProductCard({required this.product});

  final _RewardProduct product;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        return InkWell(
          onTap: () => _openProduct(context, product.amazonUrl),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: primaryColor.withValues(alpha: 0.06),
              border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              product.assetPath,
                              height: 72,
                              width: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _RewardText(product: product)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ViewProductButton(
                          onTap: () => _openProduct(context, product.amazonUrl),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          product.assetPath,
                          height: 72,
                          width: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _RewardText(product: product)),
                      const SizedBox(width: 10),
                      _ViewProductButton(
                        onTap: () => _openProduct(context, product.amazonUrl),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _openProduct(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    var opened = await launchUrl(uri);
    if (!opened) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to open product link'),
        ),
      );
    }
  }
}

class _RewardText extends StatelessWidget {
  const _RewardText({required this.product});

  final _RewardProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            product.rankLabel,
            style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'View product on Amazon',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class _ViewProductButton extends StatelessWidget {
  const _ViewProductButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      icon: const Icon(Icons.open_in_new_rounded, size: 16),
      label: const Text('View', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.16)),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 8,
          width: 8,
          decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
