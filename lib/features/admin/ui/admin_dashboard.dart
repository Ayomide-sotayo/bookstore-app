// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int totalUsers = 0;
  int totalBooks = 0;
  int totalOrders = 0;
  double totalRevenue = 0;
  double profitRate = 0;
  bool isLoading = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);

    final userSnap = await FirebaseFirestore.instance.collection('users').get();
    totalUsers = userSnap.size;

    final bookSnap = await FirebaseFirestore.instance.collection('books').get();
    totalBooks = bookSnap.size;

    double allTimeRevenue = 0;
    double thisMonthRevenue = 0;
    double lastMonthRevenue = 0;
    int ordersCount = 0;

    for (var userDoc in userSnap.docs) {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('orders')
          .get();

      ordersCount += ordersSnap.size;

      for (var order in ordersSnap.docs) {
        final orderData = order.data();
        final orderDate = (orderData['timestamp'] as Timestamp?)?.toDate();
        final price = (orderData['totalPrice'] ?? 0).toDouble();

        allTimeRevenue += price;

        if (orderDate != null) {
          if (orderDate.isAfter(firstDayThisMonth)) {
            thisMonthRevenue += price;
          } else if (orderDate.isAfter(firstDayLastMonth) &&
              orderDate.isBefore(lastDayLastMonth.add(const Duration(days: 1)))) {
            lastMonthRevenue += price;
          }
        }
      }
    }

    if (lastMonthRevenue > 0) {
      profitRate = ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;
    } else if (thisMonthRevenue > 0) {
      profitRate = 100;
    } else {
      profitRate = 0;
    }

    setState(() {
      totalOrders = ordersCount;
      totalRevenue = allTimeRevenue;
      isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ADMIN',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dashboard Overview',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dashboard Content
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : SlideTransition(
                      position: _slideAnimation,
                      child: _buildDashboardContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard data...',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildDashboardCard(
                "Total Users",
                totalUsers.toString(),
                Icons.people_rounded,
                const Color(0xFF4FC3F7),
                Colors.blue.withOpacity(0.1),
              ),
              _buildDashboardCard(
                "Books Available",
                totalBooks.toString(),
                Icons.menu_book_rounded,
                const Color(0xFF66BB6A),
                Colors.green.withOpacity(0.1),
              ),
              _buildDashboardCard(
                "Total Orders",
                totalOrders.toString(),
                Icons.shopping_bag_rounded,
                const Color(0xFFFF9800),
                Colors.orange.withOpacity(0.1),
              ),
              _buildDashboardCard(
                "Total Revenue",
                "₦${totalRevenue.toStringAsFixed(0)}",
                Icons.attach_money_rounded,
                const Color(0xFF9C27B0),
                Colors.purple.withOpacity(0.1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Profit Rate Card (Full Width)
          _buildProfitCard(),

          const SizedBox(height: 20),

          // Recent Activity Section
          _buildRecentActivitySection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color backgroundColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor,
              ),
            ),
            
            const Spacer(),
            
            // Value
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard() {
    final profitColor = profitRate >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
    final profitIcon = profitRate >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: profitColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: profitColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              profitIcon,
              size: 30,
              color: profitColor,
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Growth Rate',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: profitColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      profitRate >= 0 ? 'vs last month' : 'vs last month',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Add New Book',
                  Icons.add_rounded,
                  const Color(0xFF4FC3F7),
                  () {
                    // Navigate to add book screen
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'View Orders',
                  Icons.receipt_long_rounded,
                  const Color(0xFF66BB6A),
                  () {
                    // Navigate to orders screen
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}