import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.3, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textOpacity = CurvedAnimation(parent: _textController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textController, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero));

    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressValue = CurvedAnimation(parent: _progressController, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Sequence the animations
    _logoController.forward().then((_) {
      _textController.forward();
      _progressController.forward();
    });

    // Navigate after animations complete
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) GoRouter.of(context).go('/');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628), // Navy
              Color(0xFF1A3A5C), // Deep blue
              Color(0xFF0A2540), // Dark blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) => Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Animated text
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) => SlideTransition(
                          position: _textSlide,
                          child: Opacity(
                            opacity: _textOpacity.value,
                            child: child,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'BridgeLink',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD600).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.4)),
                              ),
                              child: const Text(
                                'SERVICES',
                                style: TextStyle(
                                  color: Color(0xFFFFD600),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Smart delivery & logistics\nfor every customer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Progress bar at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressValue.value,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD600)),
                              minHeight: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _progressValue.value < 0.5
                                ? 'Loading...'
                                : _progressValue.value < 0.9
                                    ? 'Getting things ready...'
                                    : 'Almost there!',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
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