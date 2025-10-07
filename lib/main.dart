import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'screens/auth_screen.dart';
import 'screens/product_catalog_screen.dart';
import 'services/cart_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out');
      },
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase is already initialized, continue
    } else {
      try {
        await Firebase.initializeApp();
      } catch (e2) {
        // Continue without Firebase - limited functionality
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Stream provider for authentication state
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        // ChangeNotifierProxyProvider for CartService that depends on User
        ChangeNotifierProxyProvider<User?, CartService>(
          create: (_) => CartService(),
          update: (context, user, previous) {
            final cartService = previous ?? CartService();
            // Initialize cart service with new user context
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cartService.initialize(user);
            });
            return cartService;
          },
        ),
      ],
      child: Consumer<User?>(
        builder: (context, user, child) {
          return MaterialApp(
            title: 'SmartMart',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF1976D2),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1976D2),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF1976D2),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1976D2),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: ThemeMode.system,
            routes: {
              ProductCatalogScreen.routeName: (context) => const ProductCatalogScreen(),
            },
            // Use AuthWrapper to handle authentication state
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that handles authentication state and cart initialization
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<User?>(
      builder: (context, user, child) {
        // Always return AuthScreen which handles the navigation logic
        return const AuthScreen();
      },
    );
  }
}


