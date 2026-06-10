import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/private_match_provider.dart';
import '../widgets/pitch_background.dart';
import 'private_match_game_screen.dart';

class FriendModeScreen extends StatefulWidget {
  static const String routeName = '/friend-mode';

  const FriendModeScreen({super.key});

  static const Color premiumGold = Color(0xFFD9A441);
  static const Color softGold = Color(0xFFFFD36A);
  static const Color deepGold = Color(0xFF8F641D);
  static const Color premiumBlue = Color(0xFF2D8CFF);
  static const Color cardBlack = Color(0xEE050910);
  static const Color cardDark = Color(0xEE08111D);
  static const Color silverText = Color(0xFFF1F4FA);
  static const Color mutedSilver = Color(0xFFB8C2D1);
  static const Color dangerRed = Color(0xFFFF6B6B);

  @override
  State<FriendModeScreen> createState() => _FriendModeScreenState();
}

class _FriendModeScreenState extends State<FriendModeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  String _selectedDifficulty = 'random';
  bool _unlimitedTime = false;
  String? _localError;

  @override
  void initState() {
    super.initState();

    final provider = context.read<PrivateMatchProvider>();
    if (provider.displayName.trim().isNotEmpty) {
      _nameController.text = provider.displayName.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  bool _validateName() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _localError = 'Please enter your name first.';
      });
      return false;
    }

    setState(() {
      _localError = null;
    });
    return true;
  }

  Future<void> _createRoom() async {
    if (!_validateName()) return;

    final provider = context.read<PrivateMatchProvider>();

    await provider.createRoom(
      name: _nameController.text,
      selectedDifficulty: _selectedDifficulty,
      unlimitedTime: _unlimitedTime,
    );

    if (!mounted) return;

    if (provider.roomCode != null) {
      Navigator.pushNamed(context, PrivateMatchGameScreen.routeName);
    }
  }

  Future<void> _joinRoom() async {
    if (!_validateName()) return;

    final code = _roomCodeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _localError = 'Please enter the room code.';
      });
      return;
    }

    final provider = context.read<PrivateMatchProvider>();

    await provider.joinRoom(
      code: code,
      name: _nameController.text,
    );

    if (!mounted) return;

    if (provider.roomCode != null) {
      Navigator.pushNamed(context, PrivateMatchGameScreen.routeName);
    }
  }

  Future<void> _rejoinSavedRoom() async {
    final provider = context.read<PrivateMatchProvider>();

    if (provider.roomCode != null) {
      Navigator.pushNamed(context, PrivateMatchGameScreen.routeName);
    }
  }

  InputDecoration _premiumInputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      prefixIcon: Icon(
        icon,
        color: FriendModeScreen.softGold,
      ),
      filled: true,
      fillColor: const Color(0xFF050B14).withOpacity(0.82),
      hintStyle: const TextStyle(
        color: FriendModeScreen.mutedSilver,
        fontWeight: FontWeight.w800,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFFFA0A0),
        fontWeight: FontWeight.w900,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: FriendModeScreen.premiumGold.withOpacity(0.50),
          width: 1.15,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: FriendModeScreen.softGold,
          width: 1.55,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: FriendModeScreen.dangerRed,
          width: 1.25,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFFFFA0A0),
          width: 1.55,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.18),
                Colors.black.withOpacity(0.46),
                Colors.black.withOpacity(0.82),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Consumer<PrivateMatchProvider>(
                    builder: (context, provider, _) {
                      final errorText = _localError ?? provider.errorMessage;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(
                              onBack: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 16),
                            const _IntroText(),
                            const SizedBox(height: 22),
                            if (provider.roomCode != null &&
                                provider.room != null) ...[
                              _SectionCard(
                                title: 'Saved Match Found',
                                icon: Icons.history_rounded,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _RoomCodeBadge(code: provider.roomCode!),
                                    const SizedBox(height: 12),
                                    _PremiumFilledButton(
                                      label: 'Rejoin Match',
                                      icon: Icons.replay_rounded,
                                      onPressed: provider.isLoading
                                          ? null
                                          : _rejoinSavedRoom,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: FriendModeScreen.silverText,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: _premiumInputDecoration(
                                hintText: 'Your name',
                                icon: Icons.person_rounded,
                                errorText: _localError != null &&
                                        _localError!
                                            .toLowerCase()
                                            .contains('name')
                                    ? _localError
                                    : null,
                              ),
                              onChanged: (_) {
                                if (_localError != null) {
                                  setState(() {
                                    _localError = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _SectionCard(
                              title: 'Room Settings',
                              icon: Icons.tune_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Difficulty',
                                    style: TextStyle(
                                      color: FriendModeScreen.silverText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _DifficultyChoice(
                                        label: 'Random',
                                        value: 'random',
                                        selected: _selectedDifficulty,
                                        onChanged: _setDifficulty,
                                      ),
                                      _DifficultyChoice(
                                        label: 'Amateur',
                                        value: 'amateur',
                                        selected: _selectedDifficulty,
                                        onChanged: _setDifficulty,
                                      ),
                                      _DifficultyChoice(
                                        label: 'Pro',
                                        value: 'pro',
                                        selected: _selectedDifficulty,
                                        onChanged: _setDifficulty,
                                      ),
                                      _DifficultyChoice(
                                        label: 'Legend',
                                        value: 'legend',
                                        selected: _selectedDifficulty,
                                        onChanged: _setDifficulty,
                                      ),
                                      _DifficultyChoice(
                                        label: 'Expert',
                                        value: 'expert',
                                        selected: _selectedDifficulty,
                                        onChanged: _setDifficulty,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _PremiumSwitchTile(
                                    value: _unlimitedTime,
                                    onChanged: (value) {
                                      setState(() {
                                        _unlimitedTime = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PremiumFilledButton(
                              label: 'Create Room',
                              icon: Icons.add_rounded,
                              onPressed:
                                  provider.isLoading ? null : _createRoom,
                            ),
                            const SizedBox(height: 24),
                            _PremiumDivider(),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _roomCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                color: FriendModeScreen.silverText,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                              decoration: _premiumInputDecoration(
                                hintText: 'Room code',
                                icon: Icons.key_rounded,
                                errorText: _localError != null &&
                                        _localError!
                                            .toLowerCase()
                                            .contains('room code')
                                    ? _localError
                                    : null,
                              ),
                              onChanged: (_) {
                                if (_localError != null) {
                                  setState(() {
                                    _localError = null;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            _PremiumOutlinedButton(
                              label: 'Join Room',
                              icon: Icons.login_rounded,
                              onPressed: provider.isLoading ? null : _joinRoom,
                            ),
                            if (provider.isLoading) ...[
                              const SizedBox(height: 20),
                              const Center(
                                child: CircularProgressIndicator(
                                  color: FriendModeScreen.softGold,
                                ),
                              ),
                            ],
                            if (errorText != null) ...[
                              const SizedBox(height: 18),
                              _ErrorBox(text: errorText),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setDifficulty(String value) {
    setState(() {
      _selectedDifficulty = value;
    });
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleBackButton(onTap: onBack),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Play with Friend',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FriendModeScreen.silverText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 16,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Create a private room or join your friend using a room code.\n'
      'Each player has 3 attempts per round.\n'
      'The match ends if one player leaves.',
      style: TextStyle(
        color: FriendModeScreen.mutedSilver,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.35,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.35),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FriendModeScreen.softGold.withOpacity(0.82),
            FriendModeScreen.premiumBlue.withOpacity(0.22),
            FriendModeScreen.deepGold.withOpacity(0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.46),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: FriendModeScreen.premiumGold.withOpacity(0.14),
            blurRadius: 24,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FriendModeScreen.cardDark,
              FriendModeScreen.cardBlack,
              Color(0xF002050A),
            ],
          ),
          border: Border.all(
            color: Colors.white10,
            width: 0.7,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: title,
              icon: icon,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: FriendModeScreen.softGold,
          size: 18,
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                FriendModeScreen.softGold,
                Colors.white,
                FriendModeScreen.premiumGold,
              ],
            ).createShader(bounds);
          },
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DifficultyChoice extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _DifficultyChoice({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;

    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(
              Icons.check_rounded,
              size: 15,
              color: Color(0xFF05070B),
            ),
            const SizedBox(width: 5),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onChanged(value),
      selectedColor: FriendModeScreen.premiumGold,
      backgroundColor: const Color(0xFF050B14).withOpacity(0.86),
      showCheckmark: false,
      labelStyle: TextStyle(
        color:
            isSelected ? const Color(0xFF05070B) : FriendModeScreen.silverText,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? FriendModeScreen.softGold
            : FriendModeScreen.premiumGold.withOpacity(0.50),
        width: 1.05,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      pressElevation: 0,
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PremiumSwitchTile({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14).withOpacity(0.60),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? FriendModeScreen.softGold.withOpacity(0.48)
              : FriendModeScreen.premiumGold.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? FriendModeScreen.premiumGold.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              border: Border.all(
                color: value
                    ? FriendModeScreen.softGold.withOpacity(0.56)
                    : Colors.white.withOpacity(0.16),
              ),
            ),
            child: Icon(
              value ? Icons.timer_off_rounded : Icons.timer_rounded,
              color: value
                  ? FriendModeScreen.softGold
                  : FriendModeScreen.mutedSilver,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlimited time',
                  style: TextStyle(
                    color: FriendModeScreen.silverText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value
                      ? 'No 90-second limit. Clubs still reveal every 3 seconds.'
                      : 'Standard mode: 90 seconds per round.',
                  style: const TextStyle(
                    color: FriendModeScreen.mutedSilver,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: FriendModeScreen.premiumGold,
            activeTrackColor: FriendModeScreen.softGold.withOpacity(0.32),
            inactiveThumbColor: FriendModeScreen.mutedSilver,
            inactiveTrackColor: Colors.white.withOpacity(0.16),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RoomCodeBadge extends StatelessWidget {
  final String code;

  const _RoomCodeBadge({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14).withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FriendModeScreen.softGold.withOpacity(0.44),
        ),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: FriendModeScreen.softGold,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.2,
        ),
      ),
    );
  }
}

class _PremiumFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _PremiumFilledButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: disabled
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FriendModeScreen.softGold,
                  FriendModeScreen.premiumGold,
                  FriendModeScreen.deepGold,
                ],
              ),
        color: disabled ? Colors.grey.shade800 : null,
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: FriendModeScreen.premiumGold.withOpacity(0.26),
                  blurRadius: 20,
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor:
              disabled ? Colors.grey.shade500 : const Color(0xFF05070B),
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.grey.shade500,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _PremiumOutlinedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _PremiumOutlinedButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: FriendModeScreen.softGold,
          disabledForegroundColor: FriendModeScreen.mutedSilver,
          side: BorderSide(
            color: FriendModeScreen.premiumGold.withOpacity(0.78),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _PremiumDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  FriendModeScreen.premiumGold.withOpacity(0.48),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14).withOpacity(0.70),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: FriendModeScreen.premiumGold.withOpacity(0.35),
            ),
          ),
          child: const Text(
            'OR JOIN',
            style: TextStyle(
              color: FriendModeScreen.mutedSilver,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FriendModeScreen.premiumGold.withOpacity(0.48),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;

  const _ErrorBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: FriendModeScreen.dangerRed.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FriendModeScreen.dangerRed.withOpacity(0.46),
        ),
        boxShadow: [
          BoxShadow(
            color: FriendModeScreen.dangerRed.withOpacity(0.08),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFA0A0),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: FriendModeScreen.premiumGold.withOpacity(0.12),
        highlightColor: FriendModeScreen.premiumGold.withOpacity(0.06),
        onTap: onTap,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1624),
                Color(0xFF02060C),
              ],
            ),
            border: Border.all(
              color: FriendModeScreen.premiumGold.withOpacity(0.64),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.38),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: FriendModeScreen.premiumGold.withOpacity(0.14),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: FriendModeScreen.softGold,
            size: 24,
          ),
        ),
      ),
    );
  }
}
