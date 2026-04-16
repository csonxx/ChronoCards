import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Newbie guide dialog - shows on first entry explaining controls
class NewbieGuideDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const NewbieGuideDialog({
    super.key,
    required this.onComplete,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onComplete}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewbieGuideDialog(onComplete: onComplete),
    );
  }

  @override
  State<NewbieGuideDialog> createState() => _NewbieGuideDialogState();
}

class _NewbieGuideDialogState extends State<NewbieGuideDialog> {
  int _currentPage = 0;

  final List<GuidePage> _pages = [
    const GuidePage(
      icon: Icons.gamepad,
      title: 'Welcome to ChronoCards!',
      description: 'Your adventure in the time-stream begins now. Let\'s learn the basics!',
      highlightColor: AppTheme.accentGold,
    ),
    const GuidePage(
      icon: Icons.directions,
      title: 'Virtual Joystick',
      description: 'Use the joystick in the bottom-left corner to move your character around the world.',
      highlightColor: Colors.blue,
    ),
    const GuidePage(
      icon: Icons.touch_app,
      title: 'Interaction Button',
      description: 'Tap the [E] button in the bottom-right when near objects or NPCs to interact with them.',
      highlightColor: Colors.green,
    ),
    const GuidePage(
      icon: Icons.location_on,
      title: 'Explore the Map',
      description: 'Visit different locations on the map! Tap on glowing markers to start battles, get cards, or discover events.',
      highlightColor: Colors.orange,
    ),
    const GuidePage(
      icon: Icons.style,
      title: 'Collect Cards',
      description: 'Build your deck by drawing cards from the Card Emporium. Each card has unique powers!',
      highlightColor: AppTheme.accentCosmic,
    ),
    const GuidePage(
      icon: Icons.sports_kabaddi,
      title: 'Battle Enemies',
      description: 'Use your cards strategically to defeat enemies in turn-based combat. Good luck, traveler!',
      highlightColor: AppTheme.healthRed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppTheme.accentGold
                          : AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Icon with glow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _pages[_currentPage].highlightColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      _pages[_currentPage].icon,
                      size: 64,
                      color: _pages[_currentPage].highlightColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _pages[_currentPage].title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    _pages[_currentPage].description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),

                  const Spacer(),

                  // Prev button (if not first)
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: () {
                        setState(() => _currentPage--);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        setState(() => _currentPage++);
                      } else {
                        Navigator.pop(context);
                        widget.onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _pages.length - 1
                              ? 'Next'
                              : "Let's Go!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuidePage {
  final IconData icon;
  final String title;
  final String description;
  final Color highlightColor;

  const GuidePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlightColor,
  });
}
