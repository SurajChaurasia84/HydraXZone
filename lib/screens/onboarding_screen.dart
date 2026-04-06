import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'coin_service.dart';
import 'screen_constants.dart';
import 'system_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.existingUser,
    this.existingData,
  });

  final VoidCallback onCompleted;
  final User? existingUser;
  final Map<String, dynamic>? existingData;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _usernamePattern = RegExp(r'^[a-z][a-z0-9._]*$');
  static const _games = [
    _GameOption('BGMI', 'assets/bgmi.jpg', Icons.sports_esports),
    _GameOption('Free Fire', 'assets/ff.jpg', Icons.local_fire_department),
  ];

  late final PageController _pageController;
  late final TextEditingController _gameIdController;
  late final TextEditingController _usernameController;

  User? _signedInUser;
  String? _selectedGame;
  int _currentStep = 0;
  bool _isSigningIn = false;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _signedInUser = widget.existingUser;
    _selectedGame = widget.existingData?['game'] as String?;
    _gameIdController = TextEditingController(
      text: widget.existingData?['gameId'] as String? ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.existingData?['username'] as String? ?? '',
    );
    _currentStep = _signedInUser == null
        ? 0
        : ((_selectedGame ?? '').isEmpty || _gameIdController.text.trim().isEmpty)
            ? 1
            : 2;
    _pageController = PageController(initialPage: _currentStep);
    if (_signedInUser != null) {
      Future.microtask(() => _saveBasicUser(_signedInUser!));
    }
  }

  Future<void> _saveBasicUser(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final snapshot = await ref.get();
      final basic = {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photo': user.photoURL ?? '',
      };
      if (snapshot.exists) {
        await ref.set({
          ...basic,
          'coins': snapshot.data()?['coins'] ?? 0,
        }, SetOptions(merge: true));
      } else {
        await ref.set({
          ...basic,
          'coins': CoinService.signupBonus,
          'signupBonusPending': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _firebaseMessage(e, 'Unable to save profile.'));
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_signedInUser != null) {
      await _goTo(1);
      return;
    }
    setState(() {
      _isSigningIn = true;
      _errorText = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception();
      await _saveBasicUser(user);
      if (!mounted) return;
      setState(() => _signedInUser = user);
      await _goTo(1);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Unable to continue with Google.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _saveGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final gameId = _gameIdController.text.trim();
    if (user == null || _selectedGame == null || gameId.isEmpty) {
      setState(() => _errorText = 'Select a game and enter your game ID.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'game': _selectedGame,
        'gameId': gameId,
      }, SetOptions(merge: true));
      if (!mounted) return;
      await _goTo(2);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _firebaseMessage(e, 'Unable to save your game details.'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Unable to save your game details.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finish() async {
    final user = FirebaseAuth.instance.currentUser;
    final username = _usernameController.text.trim();
    if (user == null || username.isEmpty) {
      setState(() => _errorText = 'Enter a username to continue.');
      return;
    }
    if (!_usernamePattern.hasMatch(username)) {
      setState(
        () => _errorText =
            'Username must start with a letter and use only lowercase letters, numbers, _ or .',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
      }, SetOptions(merge: true));
      if (!mounted) return;
      widget.onCompleted();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _firebaseMessage(e, 'Unable to finish onboarding.'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Unable to finish onboarding.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _firebaseMessage(FirebaseException e, String fallback) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore permission denied. Check your Firebase rules.';
      case 'unavailable':
        return 'Firestore is unavailable right now. Check your internet connection.';
      case 'unauthenticated':
        return 'You are signed out. Please continue with Google again.';
      default:
        return e.message?.trim().isNotEmpty == true ? e.message!.trim() : fallback;
    }
  }

  Future<void> _goTo(int step) async {
    setState(() {
      _currentStep = step;
      _errorText = null;
    });
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gameIdController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topColor = isDark ? darkBackground : const Color(0xFFFFF4EF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(topColor),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [darkBackground, Color(0xFF1D120C), Color(0xFF120F0E)]
                  : const [Color(0xFFFFF4EF), Colors.white, Color(0xFFFFEEE8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _StepHeader(step: _currentStep + 1),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(
                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
                        _welcomeStep(context),
                        _gameStep(context),
                        _usernameStep(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeStep(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 110,
          width: 110,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6A38), primaryColor],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66FF4B11),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Image.asset('assets/icon.png'),
        ),
        const SizedBox(height: 28),
        Text(
          'DuelXZone',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Play. Win. Achieve.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .72),
              ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6A38), primaryColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF4B11),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _isSigningIn ? null : _continueWithGoogle,
              icon: _isSigningIn
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata, size: 30),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              label: Text(
                _signedInUser == null ? 'Continue with Google' : 'Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gameStep(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your arena',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick your game and add your player ID.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .72),
                ),
          ),
          const SizedBox(height: 24),
          for (final game in _games) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _GameCard(
                option: game,
                selected: _selectedGame == game.name,
                onTap: () => setState(() {
                  _selectedGame = game.name;
                  _errorText = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _selectedGame == null
                ? const SizedBox.shrink()
                : Column(
                    key: ValueKey(_selectedGame),
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        controller: _gameIdController,
                        decoration: InputDecoration(
                          labelText: '${_selectedGame!} ID',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveGame,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _usernameStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Create your username',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'This name will be visible in battles and on the leaderboard.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .72),
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _usernameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
            helperText: 'Start with a letter. Use lowercase letters, numbers, _ or .',
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Finish'),
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$step/3',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: step / 3,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
              valueColor: const AlwaysStoppedAnimation(primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameOption {
  const _GameOption(this.name, this.assetPath, this.icon);

  final String name;
  final String assetPath;
  final IconData icon;
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _GameOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.01 : 1,
      duration: const Duration(milliseconds: 220),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? primaryColor : Colors.white.withValues(alpha: .10),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              if (selected)
                const BoxShadow(
                  color: Color(0x66FF4B11),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
            ],
            image: DecorationImage(
              image: AssetImage(option.assetPath),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .10),
                      Colors.black.withValues(alpha: .72),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: .26),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: .26),
                    ],
                    stops: const [0, .18, .82, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: selected
                            ? primaryColor
                            : Colors.white.withValues(alpha: .18),
                        child: Icon(option.icon, color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      option.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selected ? 'Selected' : 'Tap to select',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: .82),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isProfileComplete(Map<String, dynamic>? data) {
  if (data == null) return false;
  final game = (data['game'] as String?)?.trim() ?? '';
  final gameId = (data['gameId'] as String?)?.trim() ?? '';
  final username = (data['username'] as String?)?.trim() ?? '';
  return game.isNotEmpty && gameId.isNotEmpty && username.isNotEmpty;
}
