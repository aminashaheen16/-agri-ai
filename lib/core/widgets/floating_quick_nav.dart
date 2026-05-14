import 'package:flutter/material.dart';
import '../../features/store/store_screen.dart';
import '../../features/ai_chat/chat_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';

class FloatingQuickNav extends StatefulWidget {
  const FloatingQuickNav({super.key});

  @override
  State<FloatingQuickNav> createState() => _FloatingQuickNavState();
}

class _FloatingQuickNavState extends State<FloatingQuickNav> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _buildItem(Icons.home_rounded, 'الرئيسية', Colors.green, () => _navTo(const DashboardScreen())),
          const SizedBox(height: 12),
          _buildItem(Icons.chat_bubble_rounded, 'المساعد', Colors.blue, () => _navTo(const ChatScreen())),
          const SizedBox(height: 12),
          _buildItem(Icons.storefront_rounded, 'المتجر', Colors.orange, () => _navTo(const StoreScreen())),
          const SizedBox(height: 12),
          _buildItem(Icons.person_rounded, 'الملف', Colors.purple, () => _navTo(const ProfileScreen())),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: const Color(0xFF1B3022),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _expandAnimation,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _navTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _toggle();
  }

  Widget _buildItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
            ),
            child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
