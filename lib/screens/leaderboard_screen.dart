import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'screen_constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
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
        body: TabBarView(
          children: [
            _LeaderboardTab(
              kind: _TournamentKind.daily,
              now: _now,
              title: 'Daily Battles',
            ),
            _LeaderboardTab(
              kind: _TournamentKind.weekly,
              now: _now,
              title: 'Weekly Tournament',
            ),
            _LeaderboardTab(
              kind: _TournamentKind.mega,
              now: _now,
              title: 'Mega Tournament',
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    required this.kind,
    required this.now,
    required this.title,
  });

  final _TournamentKind kind;
  final DateTime now;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cycle = _TournamentCycle.forKind(kind, now);
    final stream = FirebaseFirestore.instance
        .collection('tournament_registrations')
        .doc(cycle.id)
        .collection('participants')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final players = docs
            .map((doc) => _LeaderboardPlayer.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) {
            final pointCompare = b.points.compareTo(a.points);
            if (pointCompare != 0) return pointCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            _LeaderboardTopRow(
              chipLabel: cycle.countdownText,
            ),
            const SizedBox(height: 16),
            if (players.isEmpty)
              const _EmptyLeaderboard()
            else ...[
              _TopThreeRow(players: players.take(3).toList()),
              const SizedBox(height: 16),
              if (players.length > 3) _OtherRanksList(players: players.skip(3).toList()),
            ],
          ],
        );
      },
    );
  }
}

class _LeaderboardTopRow extends StatelessWidget {
  const _LeaderboardTopRow({
    required this.chipLabel,
  });

  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
          ),
          child: Text(
            chipLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _TopThreeRow extends StatelessWidget {
  const _TopThreeRow({required this.players});

  final List<_LeaderboardPlayer> players;

  @override
  Widget build(BuildContext context) {
    final arranged = [
      players.length > 1 ? players[1] : null,
      players.isNotEmpty ? players[0] : null,
      players.length > 2 ? players[2] : null,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumCard(
            player: arranged[0],
            rank: 2,
            height: 154,
            accent: const Color(0xFFC0C7D1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PodiumCard(
            player: arranged[1],
            rank: 1,
            height: 186,
            accent: const Color(0xFFFFC14D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PodiumCard(
            player: arranged[2],
            rank: 3,
            height: 142,
            accent: const Color(0xFFC98A62),
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.player,
    required this.rank,
    required this.height,
    required this.accent,
  });

  final _LeaderboardPlayer? player;
  final int rank;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: player == null
          ? Center(
              child: Text(
                'Rank $rank',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Rank $rank',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: rank == 1 ? 28 : 24,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  backgroundImage: player!.photoUrl.isEmpty
                      ? null
                      : NetworkImage(player!.photoUrl),
                  child: player!.photoUrl.isEmpty
                      ? Icon(Icons.person, color: accent)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  player!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${player!.points} pts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
    );
  }
}

class _OtherRanksList extends StatelessWidget {
  const _OtherRanksList({required this.players});

  final List<_LeaderboardPlayer> players;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < players.length; i++) ...[
            _RankTile(player: players[i], rank: i + 4),
            if (i != players.length - 1)
              Divider(
                height: 1,
                color: primaryColor.withValues(alpha: 0.08),
              ),
          ],
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.player,
    required this.rank,
  });

  final _LeaderboardPlayer player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        height: 42,
        width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$rank',
          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        player.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: Text('${player.points} points'),
      trailing: CircleAvatar(
        radius: 22,
        backgroundColor: primaryColor.withValues(alpha: 0.12),
        backgroundImage: player.photoUrl.isEmpty ? null : NetworkImage(player.photoUrl),
        child: player.photoUrl.isEmpty
            ? const Icon(Icons.person, color: primaryColor)
            : null,
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.emoji_events_outlined, color: primaryColor),
          ),
          const SizedBox(height: 14),
          Text(
            'No leaderboard data yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This will update automatically after live battles end and points are saved.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPlayer {
  const _LeaderboardPlayer({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.points,
  });

  final String id;
  final String name;
  final String photoUrl;
  final int points;

  factory _LeaderboardPlayer.fromMap(String id, Map<String, dynamic> data) {
    final totalPoints = (data['totalPoints'] as num?)?.toInt();
    final fallbackPoints = (data['points'] as num?)?.toInt();
    final computedPoints =
        _battlePoints(data['battle1']) + _battlePoints(data['battle2']) + _battlePoints(data['battle3']);

    return _LeaderboardPlayer(
      id: id,
      name: ((data['name'] as String?)?.trim().isNotEmpty == true)
          ? (data['name'] as String).trim()
          : 'Player',
      photoUrl: (data['photo'] as String?)?.trim() ?? '',
      points: totalPoints ?? fallbackPoints ?? computedPoints,
    );
  }

  static int _battlePoints(dynamic battle) {
    if (battle is! Map<String, dynamic>) return 0;
    return (battle['points'] as num?)?.toInt() ?? 0;
  }
}

enum _TournamentKind { daily, weekly, mega }

class _TournamentCycle {
  const _TournamentCycle({
    required this.id,
    required this.statusText,
    required this.countdownText,
  });

  final String id;
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
      statusText: 'Live today',
      countdownText: 'Updates in ${_formatDuration(end.difference(now))}',
    );
  }

  static _TournamentCycle _weekly(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final isLiveDay = now.weekday == DateTime.sunday;
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final liveStart = today.add(Duration(days: daysUntilSunday));
    final activeStart = isLiveDay ? today : liveStart;
    return _TournamentCycle(
      id: 'weekly-${_formatDate(activeStart)}',
      statusText: isLiveDay ? 'Live today' : 'Current cycle',
      countdownText: isLiveDay
          ? 'Updates after today'
          : 'Live in ${_formatDuration(activeStart.difference(now))}',
    );
  }

  static _TournamentCycle _mega(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final isLiveDay = now.day == 1 || now.day == 15;
    final liveStart = _nextMegaLiveDay(today);
    final activeStart = isLiveDay ? today : liveStart;
    return _TournamentCycle(
      id: 'mega-${_formatDate(activeStart)}',
      statusText: isLiveDay ? 'Live today' : 'Current cycle',
      countdownText: isLiveDay
          ? 'Updates after today'
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
