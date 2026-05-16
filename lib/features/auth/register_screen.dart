import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/main_navigation_wrapper.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Address Controllers
  final _countryController = TextEditingController();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();

  bool _isPasswordVisible = false;

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': {
          'country': _countryController.text.trim(),
          'governorate': _governorateController.text.trim(),
          'city': _cityController.text.trim(),
          'area': _areaController.text.trim(),
          'street': _streetController.text.trim(),
          'building': _buildingController.text.trim(),
          'floor': _floorController.text.trim(),
        }
      };

      await ref.read(authProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        userData,
      );

      final authState = ref.read(authProvider);
      if (authState.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error!, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! يرجى مراجعة بريدك الإلكتروني للتفعيل إن تطلب الأمر.', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F0A) : Colors.white,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B3022),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'انضم إلى مجتمع Agri.AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 30),
                
                // Full Name
                _buildTextField(_nameController, 'الاسم بالكامل', Icons.person_outline, isDark),
                const SizedBox(height: 15),
                
                // Phone Number
                _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone_android_outlined, isDark, keyboardType: TextInputType.phone),
                const SizedBox(height: 15),
                
                // Email
                _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email_outlined, isDark, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                
                // Password
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF2E7D32),
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                const Text(
                  'تفاصيل العنوان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontFamily: 'Cairo',
                  ),
                ),
                const Divider(color: Color(0xFF2E7D32)),
                const SizedBox(height: 15),
                
                // Country & Governorate
                Row(
                  children: [
                    Expanded(child: _buildTextField(_countryController, 'الدولة', Icons.public, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_governorateController, 'المحافظة', Icons.map_outlined, isDark)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // City & Area
                Row(
                  children: [
                    Expanded(child: _buildTextField(_cityController, 'المدينة', Icons.location_city_outlined, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_areaController, 'المنطقة', Icons.location_on_outlined, isDark)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Street
                _buildTextField(_streetController, 'الشارع', Icons.add_road_outlined, isDark),
                const SizedBox(height: 15),
                
                // Building & Floor
                Row(
                  children: [
                    Expanded(child: _buildTextField(_buildingController, 'العمارة', Icons.apartment_outlined, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_floorController, 'الدور', Icons.layers_outlined, isDark)),
                  ],
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: authState.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'إنشاء الحساب',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white),
                      ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E291B) : const Color(0xFFF1F5F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }
}
