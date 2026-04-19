import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class LiquidDippingNavBar extends ConsumerStatefulWidget {
  const LiquidDippingNavBar({super.key});

  @override
  ConsumerState<LiquidDippingNavBar> createState() => _LiquidDippingNavBarState();
}

class _LiquidDippingNavBarState extends ConsumerState<LiquidDippingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _currentIndex = 2; // Default Player
  int _prevIndex = 2;
  bool _isJumping = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = ref.read(navigationProvider).currentIndex;
    _prevIndex = _currentIndex;

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutExpo,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isJumping = false;
          _prevIndex = _currentIndex;
        });
      }
    });
  }

  void _onTap(int index, TapDownDetails details) {
    if (index == _currentIndex || _isJumping) return;

    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
      _isJumping = true;
    });

    _controller.forward(from: 0);
    ref.read(navigationProvider.notifier).setIndex(index, tapPosition: details.globalPosition);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 100, 
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. High-Contrast Footer Surface with Persistent Force-Field Padding
              Positioned.fill(
                child: CustomPaint(
                  painter: LiquidGooeyPainter(
                    animation: _animation.value,
                    prevIndex: _prevIndex,
                    nextIndex: _currentIndex,
                    isJumping: _isJumping,
                  ),
                ),
              ),
              // 2. Interaction Layer (Icons with Ascension Logic)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.library_music_outlined),
                    _buildNavItem(1, Icons.folder_outlined),
                    _buildNavItem(2, Icons.graphic_eq),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final bool isActive = _currentIndex == index;
    
    // Icon Ascension calculation: moves up into the ball
    double currentJumpY = -55.0 * math.sin(_animation.value * math.pi);
    
    double verticalAscension;
    if (isActive) {
      if (_isJumping) {
        verticalAscension = -32.0 + currentJumpY;
      } else {
        verticalAscension = -32.0; // Persistent resting height
      }
    } else if (index == _prevIndex && _isJumping) {
      // Previous active icon returning to surface
      verticalAscension = -32.0 + (32.0 * _animation.value);
    } else {
      verticalAscension = 0.0;
    }

    return Expanded(
      child: GestureDetector(
        onTapDown: (details) => _onTap(index, details),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, verticalAscension),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isActive ? 1.3 : 1.0,
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.black45,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidGooeyPainter extends CustomPainter {
  final double animation;
  final int prevIndex;
  final int nextIndex;
  final bool isJumping;

  LiquidGooeyPainter({
    required this.animation,
    required this.prevIndex,
    required this.nextIndex,
    required this.isJumping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final surfacePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double ballRadius = 32.0;
    double itemWidth = size.width / 3;
    double getX(int index) => (index * itemWidth) + (itemWidth / 2);

    double currentX;
    double ballY;
    if (isJumping) {
      currentX = getX(prevIndex) + (getX(nextIndex) - getX(prevIndex)) * animation;
      double jumpHeight = -55.0 * math.sin(animation * math.pi);
      ballY = 22.0 + jumpHeight;
    } else {
      currentX = getX(nextIndex);
      ballY = 22.0;
    }

    // Sinking logic upgraded for persistence
    double prevSink = (1.0 - animation) * 45.0;
    double nextSink = isJumping ? (animation * 45.0) : 45.0;

    final surfacePath = Path();
    surfacePath.moveTo(0, 0);

    for (int i = 0; i < 3; i++) {
        double slotX = getX(i);
        
        // FIX: If not jumping, only the current index sinks. 
        // If jumping, previous fills up and current sinks.
        double sinkAmount = 0;
        if (isJumping) {
            sinkAmount = (i == prevIndex) ? prevSink : (i == nextIndex ? nextSink : 0);
        } else {
            sinkAmount = (i == nextIndex) ? 45.0 : 0;
        }
        
        if (sinkAmount > 0) {
            surfacePath.lineTo(slotX - 65, 0);
            surfacePath.cubicTo(
                slotX - 40, 0,
                slotX - 45, sinkAmount * 1.6, 
                slotX, sinkAmount * 1.6
            );
            surfacePath.cubicTo(
                slotX + 45, sinkAmount * 1.6,
                slotX + 40, 0,
                slotX + 65, 0
            );
        }
    }
    
    surfacePath.lineTo(size.width, 0);
    surfacePath.lineTo(size.width, size.height);
    surfacePath.lineTo(0, size.height);
    surfacePath.close();

    canvas.drawShadow(surfacePath, Colors.black.withOpacity(0.12), 15, true);
    canvas.drawPath(surfacePath, surfacePaint);

    // Draw the "Magenta Mercury Ball" with persistent Y position at rest
    Offset ballPos = Offset(currentX, ballY);
    
    final ballDecorationPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF55FF), // Lighter Magenta
          Color(0xFFCC00CC), // Deep Magenta
        ],
      ).createShader(Rect.fromCircle(center: ballPos, radius: ballRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(ballPos, ballRadius, ballDecorationPaint);

    // Draw the "Gooey String" (Bridge)
    if (isJumping && ballY < -5) {
      final bridgePath = Path();
      double bridgeWidth = 13.0 * (1.0 - (animation - 0.5).abs() * 2);
      
      Offset ballLeft = ballPos + Offset(-bridgeWidth, 5);
      Offset ballRight = ballPos + Offset(bridgeWidth, 5);
      Offset surfaceLeft = Offset(currentX - bridgeWidth * 2.5, 0);
      Offset surfaceRight = Offset(currentX + bridgeWidth * 2.5, 0);

      bridgePath.moveTo(ballLeft.dx, ballLeft.dy);
      bridgePath.quadraticBezierTo(currentX, ballY + 28, surfaceLeft.dx, surfaceLeft.dy);
      bridgePath.lineTo(surfaceRight.dx, surfaceRight.dy);
      bridgePath.quadraticBezierTo(currentX, ballY + 28, ballRight.dx, ballRight.dy);
      bridgePath.close();
      
      canvas.drawPath(bridgePath, ballDecorationPaint);
    }
  }

  @override
  bool shouldRepaint(LiquidGooeyPainter oldDelegate) => true;
}
