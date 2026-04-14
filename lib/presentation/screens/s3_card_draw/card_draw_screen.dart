import 'package:flutter/material.dart';
import '../../components/card_draw/card_draw_screen.dart';

/// S3 Card Draw Screen - Entry point
/// Delegates to the card_draw components implementation
class CardDrawScreenEntry extends StatelessWidget {
  const CardDrawScreenEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardDrawScreen();
  }
}
