import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/notification_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _paymentMethod = 0; // 0 for Credit Card, 1 for Cash
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('إتمام الطلب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('معلومات الشحن والتوصيل', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField('الدولة', 'مصر', Icons.public)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTextField('المحافظة', 'القاهرة', Icons.map)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField('المدينة / المنطقة', '', Icons.location_city),
                const SizedBox(height: 15),
                _buildTextField('اسم الشارع', '', Icons.edit_road),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField('رقم العمارة', '', Icons.apartment)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildTextField('الدور', '', Icons.layers)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField('رقم الهاتف للتواصل', '', Icons.phone_android),
                const SizedBox(height: 25),

                const Text('تحديد موعد التوصيل', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildSelectionField('التاريخ', '14/5/2026', Icons.calendar_today)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSelectionField('الساعة', '10:00 AM', Icons.access_time)),
                  ],
                ),
                const SizedBox(height: 25),

                const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethod(0, 'بطاقة بنكية', Icons.credit_card, _paymentMethod == 0),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildPaymentMethod(1, 'عند الاستلام', Icons.payments_outlined, _paymentMethod == 1),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                if (_paymentMethod == 0) ...[
                  const Text('بيانات البطاقة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                  const SizedBox(height: 10),
                  _buildTextField('رقم البطاقة', '', Icons.credit_card),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('تاريخ الانتهاء', 'MM/YY', Icons.calendar_month)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField('CVV', '', Icons.lock_outline)),
                    ],
                  ),
                ],

                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المبلغ الإجمالي:', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
                      Text('${widget.totalAmount.toStringAsFixed(1)} EGP', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3022))),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3022),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('تأكيد وطلب المنتج الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(cartServiceProvider).checkout(widget.totalAmount);
      
      // Send order notification
      await ref.read(notificationServiceProvider).sendNotification(
        title: 'تم استلام طلبك! 🎉',
        body: 'شكراً لثقتك في Agri.AI. تم استلام طلبك بنجاح وجاري تجهيزه للتوصيل. يمكنك متابعته من قسم الطلبات.',
        type: 'order',
      );

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إتمام الطلب: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.all(25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تم استلام طلبك! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022)),
            ),
            const SizedBox(height: 15),
            const Text(
              'موعد التوصيل المتوقع: خلال 48 ساعة. شكراً لثقتك في Agri.AI. يمكنك متابعة الطلب من قائمة "طلباتي".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // Go to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text('موافق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Cairo')),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B3022)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Cairo')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1B3022)),
              const SizedBox(width: 10),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(int index, String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3022) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? null : Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontFamily: 'Cairo', fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

