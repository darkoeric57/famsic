import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/equalizer_provider.dart';

class PresetSelector extends ConsumerWidget {
  const PresetSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    
    final keys = eqPresets.keys.toList();
    final currentIndex = keys.indexOf(eqState.activePreset);
    
    // Display 'C' for Custom, otherwise the 1-based index
    final displayIndex = currentIndex == -1 ? "C" : (currentIndex + 1).toString();
    final displayName = eqState.activePreset.toUpperCase();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PresetButton(
              icon: Icons.remove,
              onPressed: () => eqNotifier.previousPreset(),
            ),
            const SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: AppTheme.pathfinderDarkDecoration(isCircular: true, borderWidth: 2.2),
              child: Center(
                child: Text(
                  displayIndex,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _PresetButton(
              icon: Icons.add,
              onPressed: () => eqNotifier.nextPreset(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          displayName,
          style: TextStyle(
            color: AppTheme.secondaryGrey.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  
  const _PresetButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: AppTheme.pathfinderDarkDecoration(isCircular: true, borderWidth: 1.8),
        child: Center(
          child: Icon(icon, color: AppTheme.neonCyan, size: 22),
        ),
      ),
    );
  }
}
