import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const UHeader({
    super.key,
    required this.child,
    this.height = 450,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Dark background container
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.85,
              decoration: const BoxDecoration(
                color: AppTheme.deepDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(160),
                  bottomRight: Radius.circular(160),
                ),
              ),
            ),
          ),
          
          // Header Controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.white, size: 30),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.white, size: 30),
                  onPressed: onMenu,
                ),
              ],
            ),
          ),

          // Central Artwork in Oval Cutout
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 260,
                  height: 380,
                  decoration: BoxDecoration(
                    color: AppTheme.deepDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(130),
                      bottom: Radius.circular(130),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentNeon.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
                const SizedBox(height: 25),
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
