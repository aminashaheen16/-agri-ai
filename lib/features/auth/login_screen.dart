import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../dashboard/main_navigation_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F0A) : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 100,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 30),
                Text(
                  'تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'مرحباً بك مجدداً في Agri.AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 60),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E291B) : const Color(0xFFF1F5F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: const TextStyle(fontFamily: 'Cairo'),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E291B) : const Color(0xFFF1F5F1),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF2E7D32),
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                    return null;
                  },
                ),
                
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(color: Color(0xFF2E7D32), fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF2E7D32),
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'دخول الآمن',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontFamily: 'Cairo'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
