import 'package:bookstore_app/features/admin/ui/admin_buttom_nav.dart';
import 'package:bookstore_app/features/books/ui/main_app_scaffold.dart';
import 'package:bookstore_app/features/cart/ui/cart_screen.dart';
import 'package:bookstore_app/features/wishlist/ui/wishlist_screen.dart';
import 'package:flutter/material.dart';
import '../features/splash/ui/splash_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/signup_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case AppRoutes.buttomnav:
        return MaterialPageRoute(builder: (_) => const MainAppScaffold());
      case AppRoutes.adminnav:
        return MaterialPageRoute(builder: (_) => const AdminButtomNav());
      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case AppRoutes.wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      // Add more routes later (e.g., home, details, cart)
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route found')),
          ),
        );
    }
  }
}
