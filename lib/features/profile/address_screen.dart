import 'package:flutter/material.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('تفاصيل العنوان', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: const Center(
        child: Text(
          'قريباً: إدارة العناوين الخاصة بك',
          style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
