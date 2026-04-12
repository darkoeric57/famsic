import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PresetSelector extends StatelessWidget {
  const PresetSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PresetButton(icon: Icons.remove),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: AppTheme.neumorphicDecoration(borderRadius: 25, isPressed: true),
              child: const Center(
                child: Text(
                  "3",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pathfinderDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _PresetButton(icon: Icons.add),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Preset",
          style: TextStyle(
            color: AppTheme.secondaryGrey.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final IconData icon;
  const _PresetButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: AppTheme.neumorphicDecoration(borderRadius: 20),
      child: Center(
        child: Icon(icon, color: AppTheme.secondaryGrey, size: 20),
      ),
    );
  }
}
