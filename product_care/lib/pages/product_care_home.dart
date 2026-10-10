import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import '../services/backup_service.dart';
import '../services/data_export_service.dart';
import '../services/product_store.dart';
import '../services/restock_search_service.dart';
import '../widgets/product_details_sheet.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/product_care_splash.dart';
import '../widgets/product_care_navigation_bar.dart';
import '../widgets/record_loss_dialog.dart';
import '../widgets/restock_search_sheet.dart';
import 'alerts_page.dart';
import 'calendar_page.dart';
import 'dashboard_page.dart';
import 'products_page.dart';
import 'settings_page.dart';

class ProductCareHome extends StatefulWidget {
  const ProductCareHome({
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<ProductCareHome> createState() => _ProductCareHomeState();
}

class _ProductCareHomeState extends State<ProductCareHome> {
  ProductStore _store = ProductStore();
  final BackupService _backupService = const BackupService();
  final DataExportService _dataExportService = const DataExportService();
  final RestockSearchService _restockSearchService =
      const RestockSearchService();
  final PageController _pageController = PageController();
  int _selectedTab = 0;
  String _productFilter = 'All';
  Set<int> _reminderDays = {3};
  bool _showSplash = true;
  bool _splashDelayDone = false;
  bool _storeLoaded = false;
  String? _startupMessage;

  @override
  void initState() {
    super.initState();
    _loadStore();
    Timer(const Duration(milliseconds: 1800), () {
      _splashDelayDone = true;
      _finishStartup();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const ProductCareSplash();

    final pages = [
      DashboardPage(
        products: _store.products,
        expiringCount: _store.expiringSoon,
        lowStockCount: _store.lowStock,
        totalUnits: _store.totalUnits,
        onOpenProducts: () => _openProductsWithFilter('All'),
        onOpenExpiring: () => _openProductsWithFilter('Expiring'),
        onOpenInStock: () => _openProductsWithFilter('In stock'),
        onOpenLowStock: () => _openProductsWithFilter('Low stock'),
        onOpenCalendar: () => _selectTab(2),
        onOpenAlerts: () => _selectTab(3),
        onOpenProduct: _openProduct,
        onAddProduct: _addProduct,
        onScan: _showScanInfo,
      ),
      ProductsPage(
        key: ValueKey(_productFilter),
        products: _store.products,
        initialFilter: _productFilter,
        onOpenProduct: _openProduct,
      ),
      CalendarPage(products: _store.products, onOpenProduct: _openProduct),
      AlertsPage(
        products: _store.products,
        losses: _store.losses,
        reminderDays: _reminderDays,
        onOpenProduct: _openProduct,
      ),
      SettingsPage(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        onTestNotifications: _showNotificationStatus,
        reminderDays: _reminderDays,
        onReminderDaysChanged: _updateReminderDays,
        onCreateBackup: _createBackup,
        onRestoreBackup: _restoreBackup,
        onExportExcel: _exportExcel,
        languageCode: _store.languageCode,
        onLanguageChanged: _updateLanguage,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) => setState(() => _selectedTab = index),
          children: pages,
        ),
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'Add product')),
            )
          : null,
      bottomNavigationBar: ProductCareNavigationBar(
        selectedIndex: _selectedTab,
        onSelected: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openProductsWithFilter(String filter) {
    setState(() => _productFilter = filter);
    _selectTab(1);
  }

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ProductFormSheet(),
    );
    if (product == null || !mounted) return;
    setState(() => _store.addProduct(product));
    await _persistStore();
    _showMessage(
      tr(context, '{name} added to your products.', {'name': product.name}),
    );
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
          _persistStore();
          _showMessage(tr(context, '{name} removed.', {'name': product.name}));
        },
        onRestock: () => _showRestockSearch(product),
      ),
    );
  }

  Future<void> _recordLoss(Product product) async {
    final quantity = await showRecordLossDialog(context, product);
    if (quantity == null || !mounted) return;
    final recorded = _store.recordLoss(product, quantity);
    if (!recorded) {
      _showMessage(
        tr(context, 'Stock changed before the loss could be recorded.'),
      );
      return;
    }
    setState(() {});
    await _persistStore();
    _showMessage(
      tr(
        context,
        '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.',
        {
          'quantity': quantity,
          'unit': product.unit,
          'remaining': product.quantity,
        },
      ),
    );
  }

  void _showScanInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Scan a product')),
        content: Text(
          tr(
            context,
            'Camera and product recognition are not connected yet. You can add product details manually.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, 'Close')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addProduct();
            },
            child: Text(tr(context, 'Enter manually')),
          ),
        ],
      ),
    );
  }

  void _showNotificationStatus() {
    _showMessage(
      _store.products.any(
            (product) =>
                product.service != null ||
                (product.kind == ProductKind.storable &&
                    product.quantity > 0 &&
                    product.expiry != null),
          )
          ? tr(
              context,
              'Reminder preview is not sent: device notifications are not configured yet.',
            )
          : tr(
              context,
              'There are no expiry or service dates available to preview.',
            ),
    );
  }

  Future<void> _loadStore() async {
    try {
      final loaded = await ProductStore.open();
      if (!mounted) return;
      _store = loaded;
      _reminderDays = Set<int>.of(loaded.reminderDays);
      widget.onLanguageChanged(loaded.languageCode);
      _startupMessage = loaded.loadError;
    } on Object catch (_) {
      // Keep the sample session available if the local data file cannot be read.
      _startupMessage =
          'Saved data could not be loaded. Restore a local backup.';
    }
    _storeLoaded = true;
    _finishStartup();
  }

  void _finishStartup() {
    if (!_splashDelayDone || !_storeLoaded || !_showSplash || !mounted) return;
    setState(() => _showSplash = false);
    final message = _startupMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(tr(context, message));
      });
    }
  }

  Future<void> _persistStore() async {
    try {
      await _store.persist();
    } catch (_) {
      if (mounted)
        _showMessage(tr(context, 'Could not save local Product Care data.'));
    }
  }

  void _updateReminderDays(Set<int> days) {
    setState(() => _reminderDays = Set<int>.of(days));
    _store.setReminderDays(days);
    _persistStore();
  }

  void _updateLanguage(String code) {
    setState(() => _store.setLanguageCode(code));
    widget.onLanguageChanged(code);
    _persistStore();
  }

  Future<void> _exportExcel() async {
    try {
      final size = MediaQuery.sizeOf(context);
      final result = await _dataExportService.exportAndShare(
        context,
        _store,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
      if (!mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        _showMessage(tr(context, 'Sharing is unavailable on this device.'));
      } else if (result.status == ShareResultStatus.success) {
        _showMessage(tr(context, 'Excel file shared.'));
      }
    } catch (_) {
      if (mounted)
        _showMessage(tr(context, 'Excel export could not be created.'));
    }
  }

  Future<void> _createBackup() async {
    try {
      await _store.persist();
      final file = await _backupService.createBackup(_store);
      if (mounted)
        _showMessage(
          tr(context, 'Backup saved: {name}', {'name': _fileName(file)}),
        );
    } catch (_) {
      if (mounted) _showMessage(tr(context, 'Backup could not be created.'));
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final backups = await _backupService.listBackups();
      if (!mounted) return;
      if (backups.isEmpty) {
        _showMessage(
          tr(context, 'No Product Care backups are saved on this device yet.'),
        );
        return;
      }
      final selected = await showModalBottomSheet<File>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Text(
                  tr(context, 'Choose a backup to restore'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ...backups.map(
                (file) => ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(_fileName(file)),
                  subtitle: Text(
                    tr(context, 'Products, loss history, and reminder days'),
                  ),
                  onTap: () => Navigator.pop(sheetContext, file),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      final snapshot = await _backupService.readBackup(selected);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(context, 'Restore this backup?')),
          content: Text(
            tr(
              context,
              'This replaces the products, stock-loss history, and reminder days currently saved in Product Care.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(context, 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr(context, 'Restore backup')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _store.restore(snapshot);
      if (!mounted) return;
      setState(() => _reminderDays = Set<int>.of(snapshot.reminderDays));
      _showMessage(
        tr(context, 'Backup restored from {name}.', {
          'name': _fileName(selected),
        }),
      );
    } on FormatException catch (error) {
      if (mounted)
        _showMessage(
          tr(context, 'Backup was rejected: {reason}', {
            'reason': error.message,
          }),
        );
    } catch (_) {
      if (mounted) {
        _showMessage(
          tr(
            context,
            'Backup could not be restored. Your saved data was kept.',
          ),
        );
      }
    }
  }

  Future<void> _showRestockSearch(Product product) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => RestockSearchSheet(
        product: product,
        onSelectPlatform: (platform) async {
          Navigator.pop(sheetContext);
          final opened = await _restockSearchService.open(platform, product);
          if (!opened && mounted) _showSearchFallback(product);
        },
        onCopy: () async {
          await _restockSearchService.copyQuery(product);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          if (mounted)
            _showMessage(tr(context, 'Product search terms copied.'));
        },
      ),
    );
  }

  void _showSearchFallback(Product product) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Could not open that search')),
        content: Text(
          tr(context, 'Try Google Search or copy the product search terms.'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _restockSearchService.copyQuery(product);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted)
                _showMessage(tr(context, 'Product search terms copied.'));
            },
            child: Text(tr(context, 'Copy search terms')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final opened = await _restockSearchService.open(
                ShoppingPlatform.google,
                product,
              );
              if (!opened && mounted) {
                _showMessage(tr(context, 'Google Search could not be opened.'));
              }
            },
            child: Text(tr(context, 'Google Search')),
          ),
        ],
      ),
    );
  }

  String _fileName(File file) => file.uri.pathSegments.last;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
