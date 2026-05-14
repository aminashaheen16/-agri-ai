import 'package:flutter/material.dart';
import 'login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    
    _controller.forward().then((value) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Placeholder - Using an Icon for now as I don't have the assets yet
            const Icon(
              Icons.agriculture_rounded,
              size: 120,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 20),
            Text(
              'Agri.AI',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: const Color(0xFF4CAF50),
                    letterSpacing: 2.0,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'نحو زراعة ذكية ومستدامة',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ],
        ),
      ),
    );
  }
}
