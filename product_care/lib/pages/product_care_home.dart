import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../models/product.dart';
import '../services/backup_service.dart';
import '../services/data_export_service.dart';
import '../services/product_store.dart';
import '../services/reminder_notification_service.dart';
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
  final ReminderNotificationService _notificationService =
      ReminderNotificationService();
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
  String? _pendingNotificationProductId;
  bool _notificationReady = false;

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
        onOpenCalendar: _openCalendar,
        onOpenAlerts: () => _selectTab(2),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedTab != 0) {
          _selectTab(0);
          return;
        }
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
          onScan: _showScanInfo,
        ),
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Exit Product Care?')),
        content: Text(tr(context, 'Are you sure you want to exit the app?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'Exit')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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

  void _openCalendar() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(tr(context, 'Calendar')),
          ),
          body: SafeArea(
            child: CalendarPage(
              products: _store.products,
              onOpenProduct: _openProduct,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductFormSheet(
        existingNames: _store.products.map((p) => p.name).toList(),
      ),
    );
    if (product == null || !mounted) return;
    setState(() => _store.addProduct(product));
    await _persistStore();
    if (!mounted) return;
    if (_hasReminderDate(product)) {
      await _rescheduleNotifications(requestPermission: true);
      await _notificationService.checkAndTriggerImmediateAlert(
        product: product,
        store: _store,
      );
    }
    if (!mounted) return;
    _showMessage(
      tr(context, '{name} added to your products.', {'name': product.name}),
    );
  }

  Future<void> _editProduct(Product product) async {
    final edited = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductFormSheet(
        product: product,
        existingNames: _store.products.map((p) => p.name).toList(),
      ),
    );
    if (edited == null || !mounted) return;
    final updated = _store.updateProduct(edited);
    if (!updated) {
      _showMessage(tr(context, 'This product is no longer available.'));
      return;
    }
    setState(() {});
    await _persistStore();
    if (!mounted) return;
    if (_hasReminderDate(edited)) {
      await _rescheduleNotifications(requestPermission: true);
    } else {
      await _rescheduleNotifications();
    }
    if (mounted) _showMessage(tr(context, 'Product details saved.'));
  }

  bool _hasReminderDate(Product product) =>
      product.serviceStartDate != null ||
      product.serviceEndDate != null ||
      (product.kind == ProductKind.storable &&
          product.quantity > 0 &&
          product.expiry != null);

  void _openProduct(Product product) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => ProductDetailsSheet(
        product: product,
        onRecordLoss: () => _recordLoss(product),
        onAddStock: () => _addStock(product),
        onEdit: () => _editProduct(product),
        onRemove: () {
          setState(() => _store.products.remove(product));
          _persistStore();
          _rescheduleNotifications();
          _showMessage(tr(context, '{name} removed.', {'name': product.name}));
        },
        onRestock: () => _showRestockSearch(product),
      ),
    );
  }

  Future<void> _addStock(Product product) async {
    final result = await showAddStockDialog(context, product);
    if (result == null || !mounted) return;
    if (product.kind == ProductKind.storable) {
      if (result.isNewBatch) {
        product.batches.add(ProductBatch(
          batchNumber: result.batchNumber,
          quantity: result.quantity,
          expiry: result.expiry,
        ));
      } else {
        final existingBatch = product.batches.firstWhere(
          (b) => b.batchNumber == result.batchNumber,
          orElse: () {
            final b = ProductBatch(
              batchNumber: result.batchNumber,
              quantity: 0,
              expiry: result.expiry,
            );
            product.batches.add(b);
            return b;
          },
        );
        existingBatch.quantity += result.quantity;
      }
    } else {
      product.quantity += result.quantity;
    }
    setState(() {});
    await _persistStore();
    if (!mounted) return;
    await _rescheduleNotifications();
    if (!mounted) return;
    final batchText =
        product.kind == ProductKind.storable ? ' (${result.batchNumber})' : '';
    _showMessage(
      tr(
        context,
        '{quantity} {unit} added to {name}{batch}. Total stock: {total}.',
        {
          'quantity': result.quantity,
          'unit': product.unit,
          'name': product.name,
          'batch': batchText,
          'total': product.quantity,
        },
      ),
    );
  }

  Future<void> _recordLoss(Product product) async {
    final result = await showRecordLossDialog(context, product);
    if (result == null || !mounted) return;
    final recorded = _store.recordLoss(
      product,
      result.quantity,
      batchNumber: result.batchNumber,
    );
    if (!recorded) {
      _showMessage(
        tr(context, 'Stock changed before the loss could be recorded.'),
      );
      return;
    }
    setState(() {});
    await _persistStore();
    if (!mounted) return;
    await _rescheduleNotifications();
    if (!mounted) return;
    _showMessage(
      tr(
        context,
        '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.',
        {
          'quantity': result.quantity,
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

  Future<void> _showNotificationStatus() async {
    final granted = await _notificationService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      _showMessage(
        tr(context, 'Allow notifications in device settings to receive reminders.'),
      );
      return;
    }
    await _rescheduleNotifications();
    final sent = await _notificationService.sendTestNotification(_store);
    if (!mounted) return;
    _showMessage(
      sent
          ? tr(context, 'A test reminder was sent to your device.')
          : tr(context, 'Add an expiry or service date to test reminders.'),
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
      if (loaded.loadError == null) {
        try {
          await _notificationService.initialize(
            onNotificationTap: _handleNotificationTap,
          );
          _notificationReady = true;
          await _notificationService.syncSchedule(_store);
        } catch (_) {
          _startupMessage = 'Device reminders could not be initialized.';
        }
      }
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
    final pendingId = _pendingNotificationProductId;
    if (pendingId != null) {
      _pendingNotificationProductId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNotificationProduct(pendingId);
      });
    }
  }

  Future<void> _persistStore() async {
    try {
      await _store.persist();
    } catch (_) {
      if (mounted) {
        _showMessage(tr(context, 'Could not save local Product Care data.'));
      }
    }
  }

  void _updateReminderDays(Set<int> days) {
    setState(() => _reminderDays = Set<int>.of(days));
    _store.setReminderDays(days);
    _persistStore();
    _rescheduleNotifications(requestPermission: true);
  }

  void _updateLanguage(String code) {
    setState(() => _store.setLanguageCode(code));
    widget.onLanguageChanged(code);
    _persistStore();
    _rescheduleNotifications(forceReschedule: true);
  }

  Future<void> _rescheduleNotifications({
    bool requestPermission = false,
    bool forceReschedule = false,
  }) async {
    if (!_notificationReady) return;
    try {
      if (requestPermission) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          if (mounted) {
            _showMessage(
              tr(context, 'Allow notifications in device settings to receive reminders.'),
            );
          }
          return;
        }
      }
      final scheduled = await _notificationService.syncSchedule(
        _store,
        forceReschedule: forceReschedule,
      );
      if (!scheduled && requestPermission && mounted) {
        _showMessage(tr(context, 'Notifications are not enabled.'));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(tr(context, 'Reminders could not be scheduled.'));
      }
    }
  }

  void _handleNotificationTap(String? productId) {
    if (productId == null) return;
    if (!_storeLoaded || _showSplash) {
      _pendingNotificationProductId = productId;
      return;
    }
    _openNotificationProduct(productId);
  }

  void _openNotificationProduct(String productId) {
    final product = _store.products.where((entry) => entry.id == productId);
    if (product.isEmpty) {
      _selectTab(2);
      _showMessage(tr(context, 'This product is no longer available.'));
      return;
    }
    _selectTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openProduct(product.first);
    });
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
      if (mounted) {
        _showMessage(tr(context, 'Excel export could not be created.'));
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      await _store.persist();
      final file = await _backupService.createBackup(_store);
      if (!mounted) return;
      final fileName = _fileName(file);
      _showMessage(
        tr(context, 'Backup saved: {name}', {'name': fileName}),
      );
      final size = MediaQuery.sizeOf(context);
      final titleText = tr(
        context,
        'Product Care backup: {name}',
        {'name': fileName},
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              name: fileName,
              mimeType: 'application/json',
            ),
          ],
          title: titleText,
          text: titleText,
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height),
        ),
      );
    } catch (_) {
      if (mounted) _showMessage(tr(context, 'Backup could not be created.'));
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final backups = await _backupService.listBackups();
      if (!mounted) return;

      final selectedSource = await showModalBottomSheet<_BackupSource?>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Text(
                  tr(context, 'Choose or import a backup'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.file_open_outlined,
                  color: brandGreen,
                ),
                title: Text(tr(context, 'Import from device')),
                subtitle: Text(tr(context, 'Import backup file')),
                onTap: () => Navigator.pop(
                  sheetContext,
                  const _DeviceFileBackupSource(),
                ),
              ),
              if (backups.isNotEmpty) ...[
                const Divider(),
                ...backups.map(
                  (file) => ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: Text(_fileName(file)),
                    subtitle: Text(
                      tr(context, 'Products, loss history, and reminder days'),
                    ),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      _LocalFileBackupSource(file),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      if (selectedSource == null || !mounted) return;

      ProductCareSnapshot snapshot;
      String backupName;

      if (selectedSource is _DeviceFileBackupSource) {
        final pickedFiles = await FilePicker.pickFiles(
          type: FileType.any,
        );
        if (pickedFiles.isEmpty || !mounted) return;
        final picked = pickedFiles.first;
        backupName = picked.name;

        String? content;
        if (picked.path != null) {
          try {
            final f = File(picked.path!);
            if (await f.exists()) {
              content = await f.readAsString();
            }
          } catch (_) {}
        }
        if (content == null || content.isEmpty) {
          try {
            final bytes = await picked.readAsBytes();
            if (bytes.isNotEmpty) {
              content = utf8.decode(bytes);
            }
          } catch (_) {}
        }
        if (content == null || content.isEmpty) {
          try {
            content = await picked.xFile.readAsString();
          } catch (_) {}
        }
        if (content == null || content.trim().isEmpty) {
          throw const FormatException('Could not read the selected backup file.');
        }
        snapshot = _backupService.parseBackupString(content);
      } else if (selectedSource is _LocalFileBackupSource) {
        backupName = _fileName(selectedSource.file);
        snapshot = await _backupService.readBackup(selectedSource.file);
      } else {
        return;
      }

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr(context, 'Restore this backup?')),
          content: Text(
            tr(
              context,
              'This replaces the products, stock-loss history, and reminder days currently saved in Product Care with data from {name}.',
              {'name': backupName},
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
      widget.onLanguageChanged(snapshot.languageCode);
      _showMessage(
        tr(context, 'Backup restored from {name}.', {
          'name': backupName,
        }),
      );
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(
          tr(context, 'Backup was rejected: {reason}', {
            'reason': tr(context, error.message),
          }),
        );
      }
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
          if (!opened && mounted) {
            _showSearchFallback(product);
          }
        },
        onCopy: () async {
          await _restockSearchService.copyQuery(product);
          if (sheetContext.mounted) {
            Navigator.pop(sheetContext);
          }
          if (mounted) {
            _showMessage(tr(context, 'Product search terms copied.'));
          }
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
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                _showMessage(tr(context, 'Product search terms copied.'));
              }
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

sealed class _BackupSource {
  const _BackupSource();
}

class _DeviceFileBackupSource extends _BackupSource {
  const _DeviceFileBackupSource();
}

class _LocalFileBackupSource extends _BackupSource {
  const _LocalFileBackupSource(this.file);
  final File file;
}

