import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName ?? '').trim().split(' ').first;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data?['signupBonusPending'] == true) {
          _showSignupBonus();
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon.png', height: 40, width: 40),
                const SizedBox(width: 12),
                const Text('Home'),
              ],
            ),
            actions: const [
              _CoinBadge(),
              SizedBox(width: 16),
            ],
          ),
          body: Center(
            child: Text(
              firstName.isEmpty ? 'Welcome to DuelXZone' : 'Welcome, $firstName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        );
      },
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
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.22),
            ),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
