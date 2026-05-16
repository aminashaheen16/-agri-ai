import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_ai/core/services/cart_service.dart';
import 'package:agri_ai/core/services/notification_service.dart';
import 'package:agri_ai/core/services/paymob_service.dart';
import 'package:agri_ai/core/providers/address_provider.dart';
import 'package:agri_ai/core/providers/order_provider.dart';
import 'package:agri_ai/core/providers/profile_provider.dart';
import 'package:agri_ai/features/profile/address_management_screen.dart';
import 'package:agri_ai/features/store/paymob_webview.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _paymentMethod = 0; // 0 for Paymob, 1 for Cash
  bool _isProcessing = false;
  String? _selectedAddressId;
  final PaymobService _paymobService = PaymobService();

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressProvider);

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
                const Text('عنوان التوصيل', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                const SizedBox(height: 15),
                
                addressesAsync.when(
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return _buildEmptyAddress(context);
                    }
                    _selectedAddressId ??= addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first).id;

                    return Column(
                      children: [
                        ...addresses.map((addr) => _buildAddressSelectionTile(addr)),
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة عنوان جديد', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading addresses: $e'),
                ),

                const SizedBox(height: 25),
                const Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethod(0, 'الدفع بالبطاقة', Icons.credit_card, _paymentMethod == 0),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildPaymentMethod(1, 'الدفع عند الاستلام', Icons.payments_outlined, _paymentMethod == 1),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                if (_paymentMethod == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text('سيتم توجيهك إلى صفحة الدفع الآمنة (Paymob) لإتمام العملية بالبطاقة البنكية.', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.blue))),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green.withOpacity(0.2))),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text('سيتم دفع المبلغ نقداً عند استلام الطلب من مندوب التوصيل.', style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.green))),
                      ],
                    ),
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
                  child: Text(_paymentMethod == 0 ? 'الانتقال للدفع' : 'تأكيد الطلب الآن', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
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

  Widget _buildEmptyAddress(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.2))),
      child: Column(
        children: [
          const Text('لا يوجد عنوان شحن مسجل!', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressManagementScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أضف عنوان للتوصيل', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelectionTile(AddressModel addr) {
    final isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addr.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addr.label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  Text(addr.fullAddress, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار عنوان التوصيل', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }

    if (_paymentMethod == 0) {
      _startPaymobPayment();
    } else {
      _placeRealOrder();
    }
  }

  Future<void> _startPaymobPayment() async {
    setState(() => _isProcessing = true);
    try {
      final profile = ref.read(profileProvider);
      final addresses = ref.read(addressProvider).value;
      final selectedAddr = addresses?.firstWhere((a) => a.id == _selectedAddressId);
      final cartItems = ref.read(cartItemsProvider).value ?? [];

      // 1. Auth
      final token = await _paymobService.getAuthToken();
      
      // 2. Create Order
      final orderId = await _paymobService.createOrder(
        token: token,
        amount: widget.totalAmount,
        items: cartItems.map((e) => {
          'name': e.product.name,
          'amount_cents': (e.product.price * 100).toInt().toString(),
          'description': e.product.description ?? '',
          'quantity': e.quantity.toString(),
        }).toList(),
      );

      // 3. Payment Key
      final paymentKey = await _paymobService.getPaymentKey(
        token: token,
        orderId: orderId,
        amount: widget.totalAmount,
        billingData: {
          'name': profile?.fullName ?? 'Guest',
          'email': profile?.email ?? 'test@test.com',
          'phone': profile?.phone ?? '01000000000',
          'address': selectedAddr?.fullAddress ?? 'NA',
        },
      );

      setState(() => _isProcessing = false);

      // 4. Open WebView
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PaymobWebView(url: _paymobService.getPaymentUrl(paymentKey))),
      );

      if (success == true) {
        _placeRealOrder();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشلت عملية الدفع، يرجى المحاولة مرة أخرى', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في عملية الدفع: $e')));
      }
    }
  }

  Future<void> _placeRealOrder() async {
    setState(() => _isProcessing = true);
    try {
      final cartItemsAsync = ref.read(cartItemsProvider);
      final items = cartItemsAsync.maybeWhen(
        data: (list) => list.map((e) => {
          'id': e.product.id,
          'name': e.product.name,
          'price': e.product.price,
          'quantity': e.quantity,
          'image_url': e.product.imageUrl,
        }).toList(),
        orElse: () => <Map<String, dynamic>>[],
      );

      await ref.read(orderProvider.notifier).placeOrder(
        items: items,
        total: widget.totalAmount,
        addressId: _selectedAddressId!,
      );

      await ref.read(cartServiceProvider).clearCart();
      ref.invalidate(cartItemsProvider);

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
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              _paymentMethod == 0 ? 'تم الدفع والاستلام بنجاح! 🎉' : 'تم استلام طلبك بنجاح! 🎉',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF1B3022)),
            ),
            const SizedBox(height: 15),
            Text(
              _paymentMethod == 0 
                ? 'شكراً لك! تم تأكيد دفعك وجاري تجهيز الطلب للتوصيل.' 
                : 'سيتم دفع المبلغ نقداً عند استلام الطلب. يمكنك متابعة الحالة الآن.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3022), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
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
