import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'main_screen.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    ));
    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    ));
    _titleSlide = Tween(begin: const Offset(0, 20), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
    ));
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
    ));
    _loaderOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
    ));
    _pulse = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeInOut,
    ));

    _mainCtrl.forward();

    Future.delayed(AppDurations.splash, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: AppColors.soft),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainCtrl, _pulseCtrl]),
            builder: (context, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value * _pulse.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.volunteer_activism,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Opacity(
                  opacity: _titleOpacity.value,
                  child: Transform.translate(
                    offset: _titleSlide.value,
                    child: const Text(
                      'DanaKita',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: const Text(
                    'Small acts, massive change',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Loader
                Opacity(
                  opacity: _loaderOpacity.value,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
