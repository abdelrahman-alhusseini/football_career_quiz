import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/private_match_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/pitch_background.dart';
import 'private_match_game_screen.dart';

class FriendModeScreen extends StatefulWidget {
  static const String routeName = '/friend-mode';

  const FriendModeScreen({super.key});

  @override
  State<FriendModeScreen> createState() => _FriendModeScreenState();
}

class _FriendModeScreenState extends State<FriendModeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  String _selectedDifficulty = 'random';
  bool _unlimitedTime = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
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
    final provider = context.read<PrivateMatchProvider>();

    await provider.joinRoom(
      code: _roomCodeController.text,
      name: _nameController.text,
    );

    if (!mounted) return;

    if (provider.roomCode != null) {
      Navigator.pushNamed(context, PrivateMatchGameScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Consumer<PrivateMatchProvider>(
                  builder: (context, provider, _) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppTheme.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Play with Friend',
                                  style: TextStyle(
                                    color: AppTheme.text,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Create a private room or join your friend using a room code. Clubs reveal every 3 seconds. Hints require approval from the other player.',
                            style: TextStyle(
                              color: AppTheme.subText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Your name',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: 'Room Settings',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Difficulty',
                                  style: TextStyle(
                                    color: AppTheme.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _unlimitedTime,
                                  activeColor: AppTheme.pitchGreen,
                                  title: const Text(
                                    'Unlimited time',
                                    style: TextStyle(
                                      color: AppTheme.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _unlimitedTime
                                        ? 'No 90-second limit. Clubs still reveal every 3 seconds.'
                                        : 'Standard mode: 90 seconds per player.',
                                    style: const TextStyle(
                                      color: AppTheme.subText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  provider.isLoading ? null : _createRoom,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(
                                'Create Room',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.pitchGreen,
                                foregroundColor: const Color(0xFF02100A),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppTheme.border),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _roomCodeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Room code',
                              prefixIcon: Icon(Icons.key_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: provider.isLoading ? null : _joinRoom,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text(
                                'Join Room',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.text,
                                side: const BorderSide(color: AppTheme.accent),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          if (provider.isLoading) ...[
                            const SizedBox(height: 20),
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                          if (provider.errorMessage != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
    );
  }

  void _setDifficulty(String value) {
    setState(() {
      _selectedDifficulty = value;
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF02101F).withOpacity(0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
      label: Text(label),
      onSelected: (_) => onChanged(value),
      selectedColor: AppTheme.pitchGreen,
      backgroundColor: const Color(0xFF02101F).withOpacity(0.65),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF02100A) : AppTheme.text,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.pitchGreen
            : AppTheme.stadiumBlue.withOpacity(0.35),
      ),
    );
  }
}
