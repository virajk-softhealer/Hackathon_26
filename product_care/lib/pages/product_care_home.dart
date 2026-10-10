import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/product.dart';
import '../services/product_store.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/record_loss_dialog.dart';
import 'alerts_page.dart';
import 'calendar_page.dart';
import 'dashboard_page.dart';
import 'products_page.dart';
import 'settings_page.dart';

class ProductCareHome extends StatefulWidget {
  const ProductCareHome({
    required this.themeMode,
    required this.onThemeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<ProductCareHome> createState() => _ProductCareHomeState();
}

class _ProductCareHomeState extends State<ProductCareHome> {
  final ProductStore _store = ProductStore();
  int _selectedTab = 0;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return _buildSplash();

    final pages = [
      DashboardPage(
        products: _store.products,
        expiringCount: _store.expiringSoon,
        lowStockCount: _store.lowStock,
        totalUnits: _store.totalUnits,
        onOpenProducts: () => _selectTab(1),
        onOpenCalendar: () => _selectTab(2),
        onOpenAlerts: () => _selectTab(3),
        onOpenProduct: _openProduct,
        onAddProduct: _addProduct,
        onScan: _showScanInfo,
      ),
      ProductsPage(products: _store.products, onOpenProduct: _openProduct),
      CalendarPage(products: _store.products, onOpenProduct: _openProduct),
      AlertsPage(
        products: _store.products,
        losses: _store.losses,
        onOpenProduct: _openProduct,
      ),
      SettingsPage(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onTestNotifications: _showNotificationStatus,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedTab, children: pages),
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSplash() => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F7F3), Color(0xFFE7F0E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .78, end: 1),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withValues(alpha: .13),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/branding/product_care_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Product Care',
                style: TextStyle(
                  color: brandInk,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your home, well cared for',
                style: TextStyle(color: Color(0xFF69766F), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _selectTab(int index) => setState(() => _selectedTab = index);

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ProductFormSheet(),
    );
    if (product == null || !mounted) return;
    setState(() => _store.addProduct(product));
    _showMessage('${product.name} added to your products.');
  }

  void _openProduct(Product product) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => ProductDetailsSheet(
        product: product,
        onRecordLoss: () => _recordLoss(product),
        onRemove: () {
          setState(() => _store.products.remove(product));
          _showMessage('${product.name} removed.');
        },
        onRestock: () => _showMessage('Restock search is not connected yet.'),
      ),
    );
  }

  Future<void> _recordLoss(Product product) async {
    final quantity = await showRecordLossDialog(context, product);
    if (quantity == null || !mounted) return;
    final recorded = _store.recordLoss(product, quantity);
    if (!recorded) {
      _showMessage('Stock changed before the loss could be recorded.');
      return;
    }
    setState(() {});
    _showMessage(
      '$quantity ${product.unit} recorded as loss. Remaining stock: ${product.quantity}.',
    );
  }

  void _showScanInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Scan a product'),
        content: const Text(
          'Camera and product recognition are not connected yet. You can add product details manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addProduct();
            },
            child: const Text('Enter manually'),
          ),
        ],
      ),
    );
  }

  void _showNotificationStatus() {
    _showMessage(
      _store.products.any((product) => product.expiry != null)
          ? 'Reminder preview is not sent: device notifications are not configured yet.'
          : 'There are no expiry or service dates available to preview.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
