import 'package:flutter/material.dart';

class BiomeTransitionOverlay extends StatefulWidget {
  final String biomeName;
  final VoidCallback onComplete;

  const BiomeTransitionOverlay({
    super.key,
    required this.biomeName,
    required this.onComplete,
  });

  @override
  State<BiomeTransitionOverlay> createState() => _BiomeTransitionOverlayState();
}

class _BiomeTransitionOverlayState extends State<BiomeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fade in and out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
    ]).animate(_controller);

    // Slide from left
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(1.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35.0,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.9 * _fadeAnimation.value),
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative line above
                  Container(
                    width: 400,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // "ENTERING" text
                  Text(
                    'ENTERING',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      color: Colors.grey[400]!.withOpacity(_fadeAnimation.value),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Biome name
                  Text(
                    widget.biomeName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white.withOpacity(_fadeAnimation.value),
                      shadows: [
                        Shadow(
                          blurRadius: 20.0,
                          color: Colors.cyanAccent.withOpacity(_fadeAnimation.value * 0.5),
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  // Decorative line below
                  Container(
                    width: 400,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


