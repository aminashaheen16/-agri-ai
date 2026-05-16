import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/address_provider.dart';

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('تفاصيل العنوان', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('لا يوجد عناوين مسجلة حالياً', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _showAddAddressSheet(context, ref),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('إضافة عنوانك الأول', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressSheet(context, ref),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                address.label == 'المزرعة' ? Icons.agriculture : address.label == 'العمل' ? Icons.work : Icons.home,
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 16)),
              const Spacer(),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('افتراضي', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(address.fullAddress, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
          Text('رقم الهاتف: ${address.phone}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: () => ref.read(addressProvider.notifier).setAsDefault(address.id),
                  child: const Text('تعيين كافتراضي', style: TextStyle(fontFamily: 'Cairo', color: Colors.blue)),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => ref.read(addressProvider.notifier).deleteAddress(address.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final cityController = TextEditingController();
    final streetController = TextEditingController();
    final landmarkController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedGov = 'القاهرة';
    bool isDefault = false;

    final govs = ['القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية', 'المنوفية', 'الغربية', 'الدقهلية', 'الشرقية', 'البحيرة', 'كفر الشيخ', 'دمياط', 'بورسعيد', 'الإسماعيلية', 'السويس', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط', 'سوهاج', 'قنا', 'الأقصر', 'أسوان', 'البحر الأحمر', 'الوادي الجديد', 'مطروح', 'شمال سيناء', 'جنوب سيناء'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة عنوان جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                const SizedBox(height: 20),
                TextField(controller: labelController, decoration: const InputDecoration(labelText: 'اسم العنوان (مثلاً: المزرعة)', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedGov,
                  decoration: const InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder()),
                  items: govs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setSheetState(() => selectedGov = val!),
                ),
                const SizedBox(height: 15),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'المدينة / المنطقة', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: streetController, decoration: const InputDecoration(labelText: 'الشارع ورقم العمارة', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: landmarkController, decoration: const InputDecoration(labelText: 'علامة مميزة (اختياري)', border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف للتوصيل', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('تعيين كعنوان افتراضي', style: TextStyle(fontFamily: 'Cairo')),
                  value: isDefault,
                  onChanged: (val) => setSheetState(() => isDefault = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (labelController.text.isEmpty || cityController.text.isEmpty || streetController.text.isEmpty || phoneController.text.isEmpty) return;
                    ref.read(addressProvider.notifier).addAddress(
                      label: labelController.text,
                      governorate: selectedGov,
                      city: cityController.text,
                      street: streetController.text,
                      landmark: landmarkController.text,
                      phone: phoneController.text,
                      isDefault: isDefault,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('حفظ العنوان', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
