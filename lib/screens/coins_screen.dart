import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'coin_service.dart';
import 'screen_constants.dart';

class CoinsScreen extends StatelessWidget {
  const CoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: CoinService.walletStream(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? <String, dynamic>{};
        final coins = (data['coins'] as num?)?.toInt() ?? 0;
        final streak = (data['checkInStreak'] as num?)?.toInt() ?? 0;
        final dailyOpenClaimed = _isClaimedToday(data['lastOpenRewardAt']);
        final adRewardClaimed = _isClaimedToday(data['lastAdRewardAt']);
        final spinClaimed = _isClaimedToday(data['lastSpinAt']);
        final checkInClaimed = _isClaimedToday(data['lastCheckInAt']);

        return Scaffold(
          appBar: AppBar(title: const Text('Coins')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _WalletCard(coins: coins, streak: streak),
              const SizedBox(height: 22),
              Text(
                'Earn Coins',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              _RewardActionCard(
                title: 'Daily Open Reward',
                subtitle: '+${CoinService.dailyOpenReward} coins once per day',
                icon: Icons.card_giftcard_rounded,
                buttonText: dailyOpenClaimed ? 'Claimed' : 'Claim',
                enabled: !dailyOpenClaimed,
                onTap: dailyOpenClaimed
                    ? null
                    : () => _runRewardAction(
                          context,
                          () => CoinService.claimDailyOpenReward(),
                          successPrefix: 'Daily reward claimed',
                        ),
              ),
              const SizedBox(height: 12),
              _RewardActionCard(
                title: 'Watch Ad Reward',
                subtitle: '+${CoinService.adReward} coins once per day',
                icon: Icons.ondemand_video_rounded,
                buttonText: adRewardClaimed ? 'Claimed' : 'Watch',
                enabled: !adRewardClaimed,
                onTap: adRewardClaimed
                    ? null
                    : () => _runRewardAction(
                          context,
                          () => CoinService.claimAdReward(),
                          successPrefix: 'Ad reward claimed',
                        ),
              ),
              const SizedBox(height: 12),
              _RewardActionCard(
                title: 'Daily Spin',
                subtitle: 'Spin once daily to win coins',
                icon: Icons.casino_rounded,
                buttonText: spinClaimed ? 'Claimed' : 'Spin',
                enabled: !spinClaimed,
                onTap: spinClaimed
                    ? null
                    : () => _runRewardAction(
                          context,
                          () => CoinService.claimDailySpin(),
                          successPrefix: 'Spin reward won',
                        ),
              ),
              const SizedBox(height: 12),
              _RewardActionCard(
                title: '7 Day Check-In',
                subtitle: 'Check in daily. Get +${CoinService.checkInGoalReward} coins on day ${CoinService.checkInGoalDays}',
                icon: Icons.local_fire_department_rounded,
                buttonText: checkInClaimed ? 'Claimed' : 'Check In',
                enabled: !checkInClaimed,
                onTap: checkInClaimed
                    ? null
                    : () => _runRewardAction(
                          context,
                          () => CoinService.claimCheckInReward(),
                          successPrefix: 'Check-in updated',
                        ),
              ),
              const SizedBox(height: 24),
              Text(
                'Coin History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              const _CoinHistorySection(),
            ],
          ),
        );
      },
    );
  }

  bool _isClaimedToday(dynamic value) {
    if (value is! Timestamp) return false;
    final date = value.toDate();
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _runRewardAction(
    BuildContext context,
    Future<int> Function() action, {
    required String successPrefix,
  }) async {
    try {
      final amount = await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryColor,
          content: Text(
            amount > 0
                ? '$successPrefix: +$amount coins'
                : 'Check-in saved. Complete 7 days to unlock reward.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message.contains('already-claimed') || message.contains('already claimed')
                ? 'Already claimed for today'
                : message,
          ),
        ),
      );
    }
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.coins,
    required this.streak,
  });

  final int coins;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final progress = (streak / CoinService.checkInGoalDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6A38),
            primaryColor,
            Color(0xFF8F2A0A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FF4B11),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coin Wallet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                  ),
                  Text(
                    '$coins',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Check-in streak: $streak / ${CoinService.checkInGoalDays} days',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${CoinService.checkInGoalDays - streak} days left for +${CoinService.checkInGoalReward} coins',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
        ],
      ),
    );
  }
}

class _RewardActionCard extends StatelessWidget {
  const _RewardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonText,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonText;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: enabled ? 1 : 0.48,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isDark ? cardBackground : Colors.grey.shade100,
          border: Border.all(
            color: primaryColor.withValues(alpha: enabled ? 0.14 : 0.08),
          ),
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
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: enabled
                    ? primaryColor
                    : primaryColor.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinHistorySection extends StatelessWidget {
  const _CoinHistorySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoinHistoryEntry>>(
      stream: CoinService.historyStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CoinHistoryEntry>[];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Theme.of(context).brightness == Brightness.dark
                  ? cardBackground
                  : Colors.grey.shade100,
            ),
            child: const Text('No coin history yet'),
          );
        }

        return Column(
          children: [
            for (final item in items) ...[
              _HistoryTile(item: item),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final CoinHistoryEntry item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = item.amount >= 0;
    final amountColor = isPositive ? const Color(0xFF39D98A) : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? cardBackground : Colors.grey.shade100,
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.remove_rounded,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${item.amount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Just now';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year}  $hour:$minute $meridiem';
  }
}
