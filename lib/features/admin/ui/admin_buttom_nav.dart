// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';
import 'user_management.dart';
import 'add_book_screen.dart';
import 'order_managements.dart';
import 'admin_profile.dart';

class AdminButtomNav extends StatefulWidget {
  final int initialIndex; // Added for consistency

  const AdminButtomNav({
    Key? key,
    this.initialIndex = 0, // Default to 0 (Dashboard)
  }) : super(key: key);

  @override
  State<AdminButtomNav> createState() => _AdminButtomNavState();
}

class _AdminButtomNavState extends State<AdminButtomNav>
    with TickerProviderStateMixin {
  late int _currentIndex; // Changed to late so we set it in initState
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = const [
    AdminDashboard(),
    UserManagement(),
    AddBookScreen(),
    OrderManagements(),
    AdminProfile(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {
      'icon': Icons.dashboard_rounded,
      'label': "Dashboard",
    },
    {
      'icon': Icons.people_alt_rounded,
      'label': "Users",
    },
    {
      'icon': Icons.add_box_rounded,
      'label': "Add Book",
    },
    {
      'icon': Icons.receipt_long_rounded,
      'label': "Orders",
    },
    {
      'icon': Icons.person_outline_rounded,
      'label': "Profile",
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // Use initial index here

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -10),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                final isSelected = index == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (index != _currentIndex) {
                        setState(() => _currentIndex = index);
                        _animationController.reset();
                        _animationController.forward();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: isSelected
                                ? _scaleAnimation
                                : const AlwaysStoppedAnimation(1.0),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                _navItems[index]['icon'] as IconData,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                            ),
                            child: Text(
                              _navItems[index]['label'] as String,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(top: 2),
                            width: isSelected ? 16 : 0,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}