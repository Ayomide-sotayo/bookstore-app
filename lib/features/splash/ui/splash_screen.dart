// ignore_for_file: deprecated_member_use

import 'package:bookstore_app/core/constants/admin_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    Future.delayed(const Duration(seconds: 3), _checkLogin);
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    _backgroundController.repeat(reverse: true);
    _particleController.repeat(reverse: true);
    
    // Start logo animation
    await _logoController.forward();
    
    // Small delay before text appears
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
  }

  void _checkLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      const adminEmail = AdminInfo.adminEmail;

      if (user.email == adminEmail) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminnav);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.buttomnav);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundAnimation,
          _particleAnimation,
        ]),
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A1A),
                    _backgroundAnimation.value * 0.3,
                  )!,
                  Color.lerp(
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2A2A2A),
                    _backgroundAnimation.value * 0.2,
                  )!,
                  Color.lerp(
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A1A),
                    _backgroundAnimation.value * 0.1,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ..._buildBackgroundParticles(size),
                
                // Subtle gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        const Color(0xFF4FC3F7).withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section with enhanced animations
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _logoRotationAnimation.value,
                              child: FadeTransition(
                                opacity: _logoFadeAnimation,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF4FC3F7).withOpacity(0.1),
                                        const Color(0xFF29B6F6).withOpacity(0.05),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF4FC3F7).withOpacity(0.2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4FC3F7).withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 40,
                                        spreadRadius: -10,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2A2A2A),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: const Image(
                                          image: AssetImage('assets/images/logo.png'),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      // App branding section
                      SlideTransition(
                        position: _textSlideAnimation,
                        child: FadeTransition(
                          opacity: _textOpacityAnimation,
                          child: Column(
                            children: [
                              // App name with enhanced styling
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFF4FC3F7),
                                    Color(0xFF29B6F6),
                                    Colors.white,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Bookify',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 1.1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Elegant divider
                              Container(
                                width: 80,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF4FC3F7),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tagline
                              Text(
                                'Your Digital Library Awaits',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Discover • Read • Grow',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF4FC3F7).withOpacity(0.8),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Enhanced loading section
                      FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4FC3F7).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4FC3F7),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'Preparing your reading experience...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom branding
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Center(
                      child: Text(
                        '© 2025 Bookify - Made with 📚 for book lovers',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBackgroundParticles(Size size) {
    return [
      // Floating book icons
      Positioned(
        top: size.height * 0.15 + (20 * _particleAnimation.value),
        right: size.width * 0.85 + (10 * _particleAnimation.value),
        child: Transform.rotate(
          angle: _particleAnimation.value * 0.5,
          child: Icon(
            Icons.menu_book_rounded,
            size: 16,
            color: const Color(0xFF4FC3F7).withOpacity(0.3),
          ),
        ),
      ),
      
      Positioned(
        top: size.height * 0.25 - (15 * _particleAnimation.value),
        right: size.width * 0.2 - (12 * _particleAnimation.value),
        child: Transform.rotate(
          angle: -_particleAnimation.value * 0.8,
          child: Icon(
            Icons.auto_stories_rounded,
            size: 20,
            color: const Color(0xFF29B6F6).withOpacity(0.2),
          ),
        ),
      ),

      Positioned(
        bottom: size.height * 0.35 + (25 * _particleAnimation.value),
        left: size.width * 0.1 + (8 * _particleAnimation.value),
        child: Transform.rotate(
          angle: _particleAnimation.value * 0.6,
          child: Icon(
            Icons.library_books_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),

      Positioned(
        bottom: size.height * 0.15 - (18 * _particleAnimation.value),
        right: size.width * 0.15 - (14 * _particleAnimation.value),
        child: Transform.rotate(
          angle: -_particleAnimation.value * 0.4,
          child: Icon(
            Icons.book_rounded,
            size: 18,
            color: const Color(0xFF4FC3F7).withOpacity(0.25),
          ),
        ),
      ),

      // Additional decorative dots
      Positioned(
        top: size.height * 0.3 + (10 * _particleAnimation.value),
        left: size.width * 0.8 + (5 * _particleAnimation.value),
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4FC3F7).withOpacity(0.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4FC3F7).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),

      Positioned(
        bottom: size.height * 0.4 - (12 * _particleAnimation.value),
        right: size.width * 0.8 - (6 * _particleAnimation.value),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    ];
  }
}