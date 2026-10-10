# Product Care app structure

The Flutter client is split by responsibility so page layout, shared widgets, and product behavior can evolve without
collecting everything in `main.dart`.

```text
lib/
├── main.dart                    # Flutter entry point
├── app/
│   ├── product_care_app.dart    # MaterialApp and active theme mode
│   └── app_theme.dart           # Shared light and dark Material 3 themes
├── data/
│   └── sample_products.dart     # Demo product records
├── models/
│   └── product.dart             # Product fields and expiry calculation
├── pages/
│   ├── product_care_home.dart   # Navigation shell and app-level callbacks
│   ├── dashboard_page.dart      # Summary cards, upcoming items, quick actions
│   ├── products_page.dart       # Product search, filters, and list
│   ├── calendar_page.dart       # Upcoming expiry and service dates
│   ├── alerts_page.dart         # Reminder preview and stock-loss history
│   └── settings_page.dart       # Theme and reminder settings UI
├── services/
│   └── product_store.dart       # In-memory product actions and stock-loss updates
├── utils/
│   └── date_formatters.dart     # Shared date display helpers
└── widgets/
    ├── attention_card.dart     # Shared expiry/service event card
    ├── empty_state_card.dart   # Shared empty state
    ├── product_card.dart       # Product list row
    ├── product_details_sheet.dart
    ├── product_form_sheet.dart
    ├── product_icon.dart
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

- **Home:** product/stock summaries, upcoming expiry and service items, add and scan entry points.
- **Products:** search, status filters, add-product form, product details and removal.
- **Calendar:** upcoming expiry and service dates.
- **Alerts:** expiry reminders preview and stock-loss history.
- **Settings:** immediate light, dark, or system theme selection and reminder interval UI.
- **Stock loss:** quantity validation and stock reduction after confirmation.

## Next implementation layer

`ProductStore` is intentionally a small in-memory service for this first UI pass. Replace it with a repository backed by
SQLite/Drift or Sqflite to preserve products and loss history after restart. The camera/OCR flow, scheduled local
notifications, persisted settings, localization, backup/restore, and shopping search integrations are not connected
yet. Keep those integrations behind services/repositories, and keep page widgets focused on displaying data and
forwarding user intent through callbacks.
