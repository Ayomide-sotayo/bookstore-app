// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Welcome to Bookify",
      "description":
          "Explore and discover your next favorite book anytime, anywhere with our vast collection.",
      "image": "assets/images/onboarding1.jpg",
    },
    {
      "title": "Smart Recommendations",
      "description":
          "Get personalized book suggestions powered by AI, tailored to your unique reading taste.",
      "image": "assets/images/onboarding2.jpg",
    },
    {
      "title": "Seamless Shopping",
      "description":
          "Add books to your cart and checkout easily with secure payments and lightning-fast delivery.",
      "image": "assets/images/onboarding3.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _backgroundController.repeat(reverse: true);
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _restartAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    Future.delayed(const Duration(milliseconds: 100), () {
      _startAnimations();
    });
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2C2C2C),
                    _backgroundAnimation.value * 0.2,
                  )!,
                  Color.lerp(
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A1A),
                    _backgroundAnimation.value * 0.15,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Subtle background elements
                _buildBackgroundElements(size),

                // Main PageView
                PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _restartAnimations();
                  },
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      title: onboardingData[index]['title']!,
                      description: onboardingData[index]['description']!,
                      image: onboardingData[index]['image']!,
                      fadeAnimation: _fadeAnimation,
                      slideAnimation: _slideAnimation,
                      scaleAnimation: _scaleAnimation,
                    );
                  },
                ),

                // Skip button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  right: 20,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom navigation
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              onboardingData.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _currentPage == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Next/Get Started button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage == onboardingData.length - 1
                                          ? "Get Started"
                                          : "Continue",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1A1A1A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentPage == onboardingData.length - 1
                                          ? Icons.arrow_forward_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: const Color(0xFF1A1A1A),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildBackgroundElements(Size size) {
    return Stack(
      children: [
        // Subtle floating elements
        Positioned(
          top: size.height * 0.15,
          right: size.width * 0.1,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.4,
          left: size.width * 0.05,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          left: size.width * 0.85,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title, description, image;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 60),

          // Text content (moved higher)
          SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Divider line
                  Container(
                    width: 40,
                    height: 1,
                    color: Colors.white.withOpacity(0.4),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Image container
          Expanded(
            flex: 3,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  width: size.width * 0.85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Image with proper aspect ratio
                        Positioned.fill(
                          child: Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF2A2A2A),
                                      const Color(0xFF1A1A1A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Subtle overlay for better text contrast
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // Space to push content above button
        ],
      ),
    );
  }
}
