import 'package:bookstore_app/features/books/ui/book_catalog_screen.dart';
import 'package:bookstore_app/features/books/ui/main_app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  String _userName = '';

  // Animation controllers
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchUserName();
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
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController!, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController?.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController?.forward();
      }
    });
  }

  void _fetchUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName =
            user.displayName?.split(' ').first ??
            user.email?.split('@').first ??
            'Reader';
      });
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _cartStream() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots();
  }

  double _calculateTotal(QuerySnapshot snapshot) {
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final quantity = data['quantity'] ?? 1;
      total += ((data['price'] ?? 0).toDouble() * quantity);
    }
    return total;
  }

  int _calculateItemCount(QuerySnapshot snapshot) {
    int count = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      count += (data['quantity'] ?? 1) as int;
    }
    return count;
  }

  Future<void> _updateQuantity(
    DocumentReference docRef,
    int newQuantity,
  ) async {
    if (newQuantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQuantity});
    }
  }

  Future<void> _checkout(BuildContext context, QuerySnapshot snapshot) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (snapshot.docs.isEmpty) {
      _showSnackBar(context, "Your cart is empty", Colors.orange);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CheckoutLoadingDialog(),
    );

    try {
      // Calculate total and prepare order items
      double total = 0;
      final List<Map<String, dynamic>> orderItems = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = data['quantity'] ?? 1;
        final itemTotal = (data['price'] ?? 0).toDouble() * quantity;
        total += itemTotal;

        orderItems.add({...data, 'quantity': quantity, 'itemTotal': itemTotal});
      }

      // Create order record
      final orderRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc();

      await orderRef.set({
        'orderId': orderRef.id,
        'items': orderItems,
        'totalPrice': total,
        'itemCount': _calculateItemCount(snapshot),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear cart
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Navigator.of(context).pop(); // Close loading dialog
      _showSnackBar(
        context,
        "Order placed successfully! 🎉",
        const Color(0xFF4CAF50),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showSnackBar(context, "Checkout failed. Please try again.", Colors.red);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add null checks for animations
    if (_fadeAnimation == null || _slideAnimation == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            FadeTransition(
              opacity: _fadeAnimation!,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button and Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const MainAppScaffold(
                                      initialIndex: 0,
                                    ), // Catalog tab
                              ),
                            );
                          },

                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shopping Cart',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Review your books, $_userName',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Cart Content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation!,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _cartStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyCart();
                    }

                    return _buildCartContent(snapshot.data!);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.inter(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some books to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          _ActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const MainAppScaffold(initialIndex: 0), // Catalog tab
                ),
              );
            },

            icon: Icons.shopping_bag_outlined,
            label: 'Continue Shopping',
            isSecondary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(QuerySnapshot snapshot) {
    final total = _calculateTotal(snapshot);
    final itemCount = _calculateItemCount(snapshot);

    return Column(
      children: [
        // Cart Items Summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'} in cart',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₦${total.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _CartItem(
                data: data,
                docRef: doc.reference,
                onQuantityChanged: _updateQuantity,
              );
            },
          ),
        ),

        // Checkout Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₦${total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _ActionButton(
                  onPressed: () => _checkout(context, snapshot),
                  icon: Icons.payment_rounded,
                  label: 'Proceed to Checkout',
                  isSecondary: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final DocumentReference docRef;
  final Function(DocumentReference, int) onQuantityChanged;

  const _CartItem({
    required this.data,
    required this.docRef,
    required this.onQuantityChanged,
  });

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = widget.data['quantity'] ?? 1;
    final price = (widget.data['price'] ?? 0).toDouble();
    final itemTotal = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            children: [
              // Book Cover
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF2A2A2A),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      widget.data['imageUrl'] != null &&
                              widget.data['imageUrl'].isNotEmpty
                          ? Image.network(
                            widget.data['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildImagePlaceholder(),
                          )
                          : _buildImagePlaceholder(),
                ),
              ),

              const SizedBox(width: 16),

              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data['title'] ?? "No Title",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${price.toStringAsFixed(0)} each',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quantity Controls and Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity Controls
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove_rounded,
                              onPressed:
                                  () => widget.onQuantityChanged(
                                    widget.docRef,
                                    quantity - 1,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              quantity.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _QuantityButton(
                              icon: Icons.add_rounded,
                              onPressed:
                                  () => widget.onQuantityChanged(
                                    widget.docRef,
                                    quantity + 1,
                                  ),
                            ),
                          ],
                        ),

                        // Item Total
                        Text(
                          '₦${itemTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Delete Button
              GestureDetector(
                onTap: () => widget.onQuantityChanged(widget.docRef, 0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 30,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSecondary;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isSecondary,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isSecondary ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  widget.isSecondary
                      ? Colors.white.withOpacity(0.3)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color:
                    widget.isSecondary
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF1A1A1A),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isSecondary
                          ? Colors.white.withOpacity(0.8)
                          : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutLoadingDialog extends StatelessWidget {
  const _CheckoutLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 20),
            Text(
              'Processing your order...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we confirm your purchase',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
