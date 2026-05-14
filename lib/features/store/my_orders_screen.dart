import 'package:flutter/material.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('طلباتي', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: const Center(
        child: Text(
          'لا يوجد طلبات حالياً',
          style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}
