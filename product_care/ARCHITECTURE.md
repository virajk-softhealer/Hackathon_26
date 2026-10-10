# Product Care app structure

The Flutter client is split by responsibility so page layout, shared widgets, and product behavior can evolve without
collecting everything in `main.dart`.

```text
lib/
├── main.dart                    # Flutter entry point
├── app/
│   ├── product_care_app.dart    # MaterialApp and active theme mode
│   ├── app_theme.dart           # Shared light and dark Material 3 themes
│   └── app_localizations.dart   # English, Hindi, and Gujarati strings
├── data/
│   └── sample_products.dart     # Demo product records
├── models/
│   └── product.dart             # Product fields and expiry calculation
├── pages/
│   ├── product_care_home.dart   # Swipeable navigation shell and app-level state
│   ├── dashboard_page.dart      # Summary cards, upcoming items, quick actions
│   ├── products_page.dart       # Product search, filters, and list
│   ├── calendar_page.dart       # Upcoming expiry and service dates
│   ├── alerts_page.dart         # Reminder preview and stock-loss history
│   └── settings_page.dart       # Theme and reminder settings UI
├── services/
│   ├── product_store.dart       # Local JSON persistence and stock-loss updates
│   ├── backup_service.dart      # Versioned on-device backup creation and restore parsing
│   ├── restock_search_service.dart # Encoded shopping platform searches
│   └── data_export_service.dart # Excel workbook generation and platform sharing
├── utils/
│   └── date_formatters.dart     # Shared date display helpers
└── widgets/
    ├── product_care_splash.dart # Animated zoom-in launch screen
    ├── product_care_navigation_bar.dart # Colored circular destination icons
    ├── attention_card.dart     # Shared expiry/service event card
    ├── empty_state_card.dart   # Shared empty state
    ├── product_card.dart       # Product list row
    ├── product_details_sheet.dart
    ├── product_form_sheet.dart
    ├── product_icon.dart
    ├── platform_logo.dart
    ├── reminder_interval_sheet.dart
    ├── restock_search_sheet.dart
    ├── record_loss_dialog.dart
    └── section_heading.dart
```

## How the main flow works

1. `main.dart` starts `ProductCareApp`.
2. `ProductCareApp` applies the shared theme and passes theme changes to `ProductCareHome`.
3. `ProductCareHome` owns the selected destination and the `ProductStore` instance, then supplies each page with the
   records and callbacks it needs.
4. Pages display information and report user actions through callbacks. They do not directly own or mutate the shared
   product list.
5. `ProductStore` handles product additions and stock-loss updates. A confirmed loss reduces stock and records a
   separate history entry.

## Current functionality

- **Home:** tappable product/stock summaries, upcoming expiry and service items, add and scan entry points.
- **Navigation:** swipe horizontally between the five main pages or use the colored circular bottom bar.
- **Products:** search, status filters, Storable/Service/General product form, product details and removal.
- **Calendar:** upcoming expiry and service dates.
- **Alerts:** expiry reminders preview and stock-loss history.
- **Settings:** light/dark/system appearance, English/Hindi/Gujarati language selection, one shared radio/custom reminder day, local backup/restore, and Excel export/share.
- **Restock:** opens encoded product searches in Google, Amazon India, Flipkart, or Zepto with colored platform marks; copying the query is the offline fallback.
- **Excel export:** creates Products, Stock losses, and Settings sheets, then opens the platform share sheet.
- **Stock loss:** quantity validation and stock reduction after confirmation.
- **Service items:** no inventory quantity or stock value; service dates still participate in reminders.
- **Expiry alerts:** require a Storable item with available stock. Out-of-stock Storable products do not create expiry alerts.

## Next implementation layer

`ProductStore` persists JSON in the app documents folder; backup files are stored in its `ProductCareBackups`
subfolder. This supports use across app restarts on the same installation. Backups are app-private and are not yet
exported to a user-selected location or imported from another device. The camera/OCR flow, operating-system scheduled
notifications, and theme persistence are still not connected. Keep integrations behind services and
repositories, and keep page widgets focused on displaying data and forwarding user intent through callbacks.
