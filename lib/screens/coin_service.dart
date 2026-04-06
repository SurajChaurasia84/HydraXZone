import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  static const int signupBonus = 500;

  static DocumentReference<Map<String, dynamic>>? get _userRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  static Stream<int> coinStream() {
    final ref = _userRef;
    if (ref == null) {
      return const Stream<int>.empty();
    }

    return ref.snapshots().map((snapshot) {
      final data = snapshot.data();
      final coins = data?['coins'];
      if (coins is int) return coins;
      if (coins is num) return coins.toInt();
      return 0;
    });
  }

  static Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final ref = _userRef;
    if (ref == null) return;

    await ref.set({
      'coins': FieldValue.increment(amount),
    }, SetOptions(merge: true));
  }

  static Future<void> useCoins(int amount) async {
    if (amount <= 0) return;
    final ref = _userRef;
    if (ref == null) return;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      final currentCoins = (data?['coins'] as num?)?.toInt() ?? 0;
      if (currentCoins < amount) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'insufficient-coins',
          message: 'Not enough coins.',
        );
      }

      transaction.set(ref, {
        'coins': currentCoins - amount,
      }, SetOptions(merge: true));
    });
  }
}
