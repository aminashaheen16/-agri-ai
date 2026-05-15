import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Simulate registration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري إنشاء الحساب...')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'انضم إلى مجتمع Agri.AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 30),
                
                // Full Name
                _buildTextField(_nameController, 'الاسم بالكامل', Icons.person_outline),
                const SizedBox(height: 15),
                
                // Phone Number
                _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 15),
                
                // Email
                _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 15),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.black87, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                const Text(
                  'تفاصيل العنوان',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    fontFamily: 'Cairo',
                  ),
                ),
                const Divider(color: Color(0xFF4CAF50)),
                const SizedBox(height: 15),
                
                // Country & Governorate
                Row(
                  children: [
                    Expanded(child: _buildTextField(_countryController, 'الدولة', Icons.public)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_governorateController, 'المحافظة', Icons.map_outlined)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // City & Area
                Row(
                  children: [
                    Expanded(child: _buildTextField(_cityController, 'المدينة', Icons.location_city_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_areaController, 'المنطقة', Icons.location_on_outlined)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Street
                _buildTextField(_streetController, 'الشارع', Icons.add_road_outlined),
                const SizedBox(height: 15),
                
                // Building & Floor
                Row(
                  children: [
                    Expanded(child: _buildTextField(_buildingController, 'العمارة', Icons.apartment_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_floorController, 'الدور', Icons.layers_outlined)),
                  ],
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إنشاء الحساب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }
}
