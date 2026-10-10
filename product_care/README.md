# Project: AI-Powered Product, Expiry, Service & Stock Loss Management App

## Current app implementation

The Flutter client is in this folder. Run it with `flutter pub get` and `flutter run` from `product_care/`. See
[`ARCHITECTURE.md`](ARCHITECTURE.md) for the source tree and a feature-by-feature implementation overview.

The current app includes the Product Care branded dashboard and five main destinations (Home, Products, Calendar,
Alerts, and Settings), a short animated splash, sample household products, product entry and filtering, expiry/service
overview, stock-loss quantity confirmation, and light/dark/system appearance selection. The supplied
`app_icon_1.png` is used for the app branding and launcher icons. Android, iOS, and web display the name **Product Care**.

This is the first UI and interaction pass over the Flutter starter project. Product data and preferences currently live
in memory for the session. Local database persistence, camera/OCR scanning, operating-system notifications, language
packs, backup/restore, and external restock search links still need implementation before the production-oriented
requirements below are complete. Buttons for unavailable integrations explain their current status rather than
pretending those services are active.

## 1. Project Overview

Develop a complete, production-oriented Flutter mobile application that helps users manage products, track expiry dates, schedule service reminders, monitor stock, and record expired or damaged inventory as losses.

The application must use AI-powered scanning to detect product details automatically, allow users to review and correct detected information, and send local notifications for upcoming expiry dates and service schedules.

The application should work offline for all core functionality, use a reliable local database, and provide a polished, modern, responsive user interface.

**Primary objectives:**
- AI-based product scanning and detail extraction.
- Multi-product scanning with individual verification and rescan options.
- Product, stock, expiry, and service management.
- Configurable reminders and notification history.
- Expired stock loss recording with proper inventory updates.
- Light mode, dark mode, and language selection.
- Smooth navigation, animations, and a professional splash screen.
- Reliable local storage and robust error handling.

## 2. Technology Stack

Use the following technologies unless an existing project requires a justified alternative.

- Framework: Flutter.
- Language: Dart.
- Local database: SQLite using Drift or Sqflite.
- State management: Riverpod or Bloc.
- Image processing: Camera integration.
- Product identification: OCR, barcode scanning, and AI-based image recognition.
- Notifications: Flutter local notifications with appropriate platform configuration.
- Image storage: Local files with database references.
- Architecture: Clean, modular, maintainable, and testable.
- Platforms: Android first, with architecture that can support iOS.

Do not require a backend for basic product management, reminders, stock tracking, or notification history.

External AI services must be optional and integrated through a replaceable service layer. Never hardcode API keys or secrets in the application.

## 3. Critical UI Layout and Overflow Protection

**UI overflow prevention is a mandatory requirement.** Pay particular attention to Flutter's RenderFlex overflow, clipped text, inaccessible buttons, and layout problems on different screen sizes.

Before implementing screens, define reusable layout components and responsive design rules.

Requirements:

- Prevent horizontal and vertical RenderFlex overflow.
- Do not use fixed widths or heights when content can vary significantly.
- Use Expanded, Flexible, Wrap, LayoutBuilder, SingleChildScrollView, and appropriate scrolling layouts where necessary.
- Use SafeArea to prevent content from overlapping system UI.
- Ensure text remains readable at different system font sizes.
- Handle long product names, large prices, lengthy categories, and translated text.
- Keep action buttons accessible and prevent them from being clipped.
- Use ellipsis or controlled wrapping only where appropriate.
- Ensure dialogs, bottom sheets, forms, cards, grids, and lists fit different device sizes.
- Avoid nested scrollable widgets with conflicting scroll physics.
- Make empty states, loading states, and error messages fit their containers.
- Support narrow phones and larger screens without breaking the layout.

Do not fix overflow problems simply by hiding content or disabling clipping warnings. Fix the actual layout constraints.

Run the application in different screen sizes and orientations where supported. Review Flutter debug output and fix every identified layout overflow before considering the UI complete.

## 4. Light and Dark Theme System

Implement a complete theme system with three settings:

- Light mode.
- Dark mode.
- System default.

Requirements:

- Use Flutter ThemeData and Material 3 consistently.
- Create centralized light and dark color schemes.
- Persist the selected theme locally.
- Apply the theme immediately when changed.
- Ensure the selected theme remains active after restarting the application.
- Support every screen, dialog, bottom sheet, form, dropdown, calendar, notification history screen, and dashboard.
- Ensure all text, icons, borders, input fields, cards, and buttons have sufficient contrast.
- Do not hardcode colors directly throughout widgets.
- Avoid black text on dark backgrounds or white text on light backgrounds.
- Ensure status bars, navigation bars, and system overlays match the active theme.
- Maintain consistent semantic colors for verified, needs-review, failed, expired, and unread states in both themes.

Test every screen in both light and dark modes. No text, icon, field, or control should become invisible or difficult to read after switching themes.

## 5. Splash Screen and Hero Animation

Create a professional splash screen that appears when the application launches.

### Required behavior

1. Display the application logo and name against a polished background.
2. Use a smooth hero-style animation, such as logo scaling, fading, or a subtle animated reveal.
3. Add a tasteful secondary effect, such as a soft glow, expanding circle, or subtle background motion.
4. Transition smoothly from the splash screen to the main application.
5. Target approximately two seconds for the splash experience.

Use Flutter's native animation system, including AnimationController, CurvedAnimation, Hero, or suitable implicit animations where appropriate.

The splash screen must not introduce unnecessary delays, block initialization indefinitely, or interfere with Android's native launch screen.

If essential initialization is required, handle it safely and avoid showing a blank screen. The application should remain responsive and should not display the splash screen again unexpectedly when returning from the background.

## 6. Application Branding and APK Configuration

Give the application a proper, professional identity.

Requirements:

- Use a meaningful, configurable application name.
- Configure the Android APK's visible application name correctly.
- Create a custom application icon suitable for the product and expiry management concept.
- Configure the launcher icon for supported Android icon formats and densities.
- Use a consistent icon design across the launcher, splash screen, and application branding.
- Set the Android application ID/package name appropriately.
- Ensure the application icon is not the default Flutter logo.
- Configure notification icons separately from the launcher icon.

### Notification icon requirements

Use a custom Android notification small icon rather than the default Flutter icon.

Android small notification icons generally require a simple, monochrome white silhouette with a transparent background. Create and configure the appropriate Android notification icon resource and ensure it displays correctly in the status bar.

Use the full-color application icon where supported for notification large icons or expanded notification content.

Test the actual notification appearance on Android. Do not assume the launcher icon and notification small icon can be used interchangeably.

## 7. Product Management and Product Fields

Create a proper product model with clearly defined fields and validation.

Each product should support:

- Product ID.
- Product name.
- Brand or manufacturer.
- Product image.
- Barcode or SKU.
- Product category.
- Product type.
- Storage type or storage requirements.
- Purchase date.
- Manufacturing date, if available.
- Expiry date or best-before date, if applicable.
- Unit of measure.
- Initial quantity.
- Current available quantity.
- Unit purchase cost.
- Selling price, if applicable.
- Currency.
- Supplier or purchase source, if applicable.
- Service type, if applicable.
- Service interval or next service date, if applicable.
- Reminder enabled/disabled.
- Notes and additional details.
- Created and updated timestamps.

Use appropriate data types, validation, and database relationships.

### Product type and category

Keep product category and product type as separate concepts.

Examples of categories:

- Food and beverages.
- Personal care.
- Household items.
- Electronics.
- Medical supplies.
- Appliances.

Examples of product types:

- Expirable product.
- Service-based product.
- Non-expirable product.
- Periodically maintained asset.

Also support storage classifications such as room temperature, refrigerated, frozen, or custom storage requirements where relevant.

Do not force every product to have an expiry date. Some products require maintenance instead, while others need neither expiry tracking nor servicing.

Provide suitable forms for adding, editing, searching, filtering, and viewing products.

## 8. AI-Based Multi-Product Scanning

Implement a camera scanning workflow that can identify multiple products in one session.

Extract available details such as product name, brand, category, barcode, dates, and other recognizable information.

### Scanning review example

Suppose the user scans four products. Display all four detected products on a review screen.

Use these statuses:

- Green: Verified by the user.
- Orange: Needs review or contains uncertain details.
- Red: Scan failed or important details could not be identified.

AI detection alone must never automatically mean that a product is verified.

Provide the following actions for each product:

- Retake scan.
- View details.
- Edit detected information.
- Enter details manually.
- Verify product.
- Remove product.

If one product fails, preserve the other three successful results. The user must be able to rescan the failed product without repeating the entire session.

Prevent duplicate products where possible by comparing barcodes, identifiers, and other relevant details.

Do not invent missing dates or silently save uncertain information as confirmed. Allow the user to confirm, correct, or skip fields that are not applicable.

## 9. Dashboard and Product Navigation

Create a modern dashboard with summary cards for:

- Total products.
- Available stock.
- Expiring soon.
- Expired products.
- Upcoming services.
- Products requiring attention.
- Total stock loss.

Include product search, filters, sorting, and category-based views.

### Horizontal navigation

Implement a smooth, animated horizontal navigation experience for the main navigation items or category tabs.

Requirements:

- Allow users to scroll horizontally through navigation items when they exceed the available width.
- Animate tab selection and indicator movement.
- Automatically scroll the selected tab into view when necessary.
- Support touch gestures and smooth scrolling.
- Keep the selected navigation item visually clear.
- Preserve the selected state while navigating where appropriate.
- Prevent navigation labels from being clipped or overlapping.
- Support both light and dark themes.

Use suitable Flutter widgets such as TabBar, SingleChildScrollView with horizontal scrolling, or another appropriate navigation component.

Do not force the entire application's page content into a horizontal scrolling layout. Horizontal scrolling should be used for navigation elements or content collections that benefit from it. Main forms and product details should remain accessible through appropriate vertical scrolling.

Ensure every navigation item and action opens the correct screen. Back navigation must behave consistently.

## 10. Expiry Management and Stock Loss Recording

Implement a dedicated workflow for expired, damaged, or otherwise unusable stock.

**Important: Stock must not automatically become a loss merely because a product's expiry date has passed. The user must explicitly record the loss.**

### Record Expired Stock as Loss

Add an action such as "Record Stock Loss" to eligible product details or stock management screens.

When the user selects this action, open a form containing:

- Product name.
- Current available quantity.
- Quantity to mark as lost.
- Unit cost.
- Total loss value.
- Loss reason.
- Loss date.
- Notes.
- Confirmation action.

Suggested loss reasons:

- Expired.
- Damaged.
- Contaminated.
- Spoiled.
- Missing stock.
- Other.

### Stock update logic

For example:

- Original product stock: 10 units.
- Quantity marked as expired: 4 units.
- Remaining available stock: 6 units.
- Loss record: 4 units.
- Loss value: 4 × unit cost.

After the user confirms the loss, decrease the original product's available quantity by the recorded loss quantity and create a separate, permanent loss transaction containing the product details at the time of the transaction.

If all 10 units are marked as lost, the original product's available quantity must become zero.

If only four units are lost, the remaining six units must stay available.

Do not automatically set stock to zero unless the entire remaining quantity is explicitly marked as lost.

### Loss management screen

Create a dedicated loss history screen showing:

- Product name.
- Product category.
- Quantity lost.
- Unit cost.
- Total loss amount.
- Loss reason.
- Loss date.
- Associated original product.
- Notes.

Allow users to filter and search loss records and calculate total loss values over selected periods.

Preserve historical loss records even if the original product is subsequently edited or deleted. Use database transactions to update stock and create loss records atomically.

Prevent negative stock, duplicate loss processing, and invalid quantities. The loss transaction must not be created if the stock update fails.

Use a transaction history rather than simply deleting expired products. Expired inventory, remaining inventory, and recorded losses must be clearly distinguishable.

## 11. Expiry and Service Reminder Configuration

Implement one shared default reminder configuration for both expiry and service notifications.

**Do not create separate global reminder-day settings for expiry and service.**

### Reminder settings

Provide configurable reminder intervals such as:

- 1 day before.
- 2 days before.
- 3 days before.
- 5 days before.
- 7 days before.
- 14 days before.
- 30 days before.
- Custom number of days.

Allow users to select multiple reminder intervals or choose a custom interval.

For example, if the user selects 3 days and 1 day, the application should schedule those reminders for both eligible expiry dates and service dates.

Persist these settings locally.

If product-specific overrides are supported later, keep them optional and separate from the shared default configuration.

### Reminder processing

- Schedule reminders based on the relevant product date.
- Reschedule notifications when the date or shared reminder configuration changes.
- Avoid duplicate notifications.
- Cancel obsolete notifications.
- Handle dates that have already passed.
- Prevent notifications for disabled reminders.
- Support recurring service schedules.
- Respect device notification permissions and platform scheduling restrictions.

## 12. Different Notification Types and Titles

Service reminders and expiry reminders must be clearly distinguishable.

### Expiry notification example

Title: `Expiry Reminder: Milk`

Message: `Your milk expires in 3 days. Review the product details.`

### Service notification example

Title: `Service Reminder: Air Conditioner`

Message: `Your air conditioner requires servicing in 3 days.`

Use suitable titles, messages, and notification icons based on the notification type.

Every notification must contain a reference to the associated product and the appropriate action or record identifier.

When the user taps a notification:

1. Open the application.
2. Navigate to the relevant product details or service record.
3. Mark the notification as read.
4. Update the notification history immediately.
5. Prevent the same notification from remaining unread after it has been opened.

Handle notification taps when the application is closed, in the background, or already running.

If a related product has been deleted, open an appropriate history or unavailable-record screen instead of crashing.

## 13. Notification History

Store notification history in the local database.

Each notification record should contain:

- Unique notification ID.
- Related product ID, when available.
- Notification type.
- Title.
- Message.
- Scheduled or event date.
- Creation timestamp.
- Read/unread status.
- Optional delivery and interaction timestamps.

### UI behavior

- Unread notifications should be highlighted.
- Read notifications should appear in a muted style.
- Display an unread notification count.
- Provide All, Unread, Read, Expiry, and Service filters.
- Allow marking one notification or all notifications as read.
- Open the relevant record when a notification is tapped.
- Preserve history after the notification is dismissed or opened.

Read notifications should be visually subdued, not made inaccessible or genuinely disabled if users still need to open their history.

Distinguish between a scheduled notification, a notification displayed by the operating system, and a notification read by the user. Do not assume delivery or reading succeeded simply because a notification was scheduled.

## 14. Test Notification Feature

Add a dedicated **"Test Notifications"** button in the notification settings screen.

This feature must allow users to test notification functionality immediately without waiting for the configured reminder interval.

When pressed:

1. Inspect locally stored products and their current expiry and service dates.
2. Identify expired products, products approaching expiry, and services that are due or approaching their scheduled dates.
3. Prepare suitable test notification content for each relevant notification type.
4. Send a test notification immediately using the local notification system.
5. Use clear test-related labeling so users can distinguish test notifications from ordinary scheduled reminders.
6. Provide feedback if no relevant products or services are available to test.
7. Handle notification permission denial or scheduling errors gracefully.

The test feature must not modify product dates, stock quantities, service schedules, or actual reminder configurations.

Do not generate false claims about notifications being delivered. Explain whether the test was scheduled or submitted to the operating system, as applicable.

Prevent accidental duplicate test notifications and provide a useful result message.

## 15. Language Settings and Localization

Implement a dedicated language setting screen.

Requirements:

- Support English initially.
- Structure the application to support Gujarati, Hindi, and additional languages.
- Allow users to switch languages from the settings screen.
- Persist the selected language locally.
- Apply the language consistently throughout the application.
- Translate navigation labels, buttons, dialogs, forms, validation messages, notification titles, notification bodies, and empty states.
- Format dates, numbers, and currency appropriately for the selected locale.
- Ensure long translated strings do not cause layout overflow.
- Apply language changes without requiring an application reinstall.

Use Flutter's localization system, ARB files, and generated localization classes where appropriate.

Do not hardcode user-facing strings throughout widgets. Notification content should use the selected language when the notification is generated.

## 16. Local Database and Data Integrity

Design proper database models and relationships for:

- Products.
- Product categories.
- Service schedules.
- Shared reminder settings.
- Notification history.
- Stock transactions.
- Loss records.
- Application preferences.
- Scan sessions, if needed.

Requirements:

- Persist all important records across application restarts.
- Use stable IDs and appropriate indexes.
- Validate all quantities, prices, and dates.
- Use atomic database transactions for stock changes and loss creation.
- Preserve loss history when product information changes.
- Avoid duplicate reminders.
- Support schema migrations.
- Handle database failures gracefully.
- Avoid unnecessary image duplication.
- Use consistent date and time handling.
- Maintain consistency between local database records and scheduled notifications.

Store monetary values using a suitable precision-safe representation, such as integer minor currency units or an appropriate decimal strategy. Never rely on binary floating-point calculations for financial totals without proper handling.

## 17. Security, Reliability, and Error Handling

The application must be robust under normal and unexpected conditions.

Handle:

- Camera permission denial.
- Notification permission denial.
- Unavailable AI services.
- Invalid OCR results.
- Missing product details.
- Database read/write failures.
- Invalid dates and quantities.
- Duplicate product scans.
- Empty search results.
- Missing related records.
- Notification scheduling failures.
- Interrupted scanning sessions.
- Application restarts.
- Theme or language changes.
- Stock update conflicts.

Provide understandable user-facing messages and log useful technical details for debugging without exposing sensitive information.

Never silently discard user data. Ask for confirmation before destructive operations.

Do not suppress exceptions, hide Flutter layout warnings, or use empty catch blocks simply to make the application appear error-free.

## 18. UI Design and Visual Deliverables

Before implementation, create consistent mobile UI mockups for the following screens:

1. Splash screen with animated logo.
2. Dashboard.
3. AI camera scanner.
4. Multi-product review screen with four sample products.
5. Product details and editing.
6. Manual product entry.
7. Product list and horizontal navigation.
8. Expiry calendar.
9. Service schedule.
10. Notification center.
11. Reminder settings and test notification.
12. Stock loss confirmation form.
13. Stock loss history.
14. Language settings.
15. Light and dark theme examples.

Use a consistent design system with suitable typography, spacing, colors, icons, and responsive layouts.

The mockups must demonstrate real UI states, including loading, empty, error, verified, needs-review, expired, unread, and read states.

After generating the mockups, implement the screens in Flutter. Do not stop after producing static designs.

## 19. Testing and Acceptance Criteria

The application is complete only when these scenarios work correctly:

1. Scan four products and display each product's individual detection status.
2. Rescan one failed product without losing other results.
3. Manually enter missing details and verify products.
4. Save, edit, search, and delete products correctly.
5. Switch between light and dark modes without invisible content.
6. Change languages without breaking the layout.
7. Navigate between screens using smooth horizontal navigation where applicable.
8. Display the splash animation and transition to the application in approximately two seconds under normal conditions.
9. Schedule expiry and service notifications using the same shared reminder configuration.
10. Tap a notification, open its corresponding record, and mark it as read.
11. Test notifications immediately without waiting for the configured number of days.
12. Record a partial stock loss and correctly reduce available stock.
13. Record a full stock loss and set available stock to zero.
14. Prevent negative stock and duplicate loss transactions.
15. Preserve historical loss records after product deletion.
16. Restart the application and retain product data, settings, and notification history.
17. Use core functionality offline.
18. Prevent UI overflow on different screen sizes.
19. Handle missing permissions and service failures gracefully.
20. Verify that the custom launcher icon and notification small icon display correctly on Android.
21. Build and launch a working Android APK.
22. Verify that no known critical crashes, broken navigation actions, or unresolved layout overflow errors remain.

Include unit tests for business logic, widget tests for important screens, and integration tests for critical workflows.

## 20. Final Development Instructions

Before writing code, inspect the existing repository, identify the current architecture, and check dependencies and platform configuration.

Then implement the application in structured phases:

1. Project setup, branding, theme system, localization, and architecture.
2. Splash screen and navigation.
3. Database schema and product management.
4. AI scanning and multi-product verification.
5. Expiry and service schedules.
6. Local notifications and notification history.
7. Stock transactions and loss management.
8. Test notifications and settings.
9. Responsive UI verification and automated tests.
10. Android icon configuration, release build, and APK validation.

Use reusable widgets and maintain a clear separation between presentation, business logic, database access, notifications, and AI services.

Do not introduce unnecessary dependencies. Do not leave non-functional buttons, fake data in production screens, unfinished navigation, or placeholder implementations presented as complete features.

After implementation, provide:

- A concise summary of implemented functionality.
- Project structure and important architectural decisions.
- Required setup instructions.
- Any external API or permission requirements.
- Tests performed and their results.
- The final APK build location and build instructions.

**Final objective:** Deliver a fully functional, professionally branded Flutter application for AI-assisted product management, expiry and service reminders, notification history, and manually confirmed stock-loss tracking, with reliable offline storage, smooth animations, proper localization, complete light/dark themes, and a polished Android experience.


# Additional Features for Product Care

## 1. Smart Product Health Status

Implement an intelligent product health status system that helps users quickly identify which household products require attention.

Assign a status to each product based on its expiry date, service schedule, stock condition, and relevant user-confirmed information.

### Product Statuses

- **Good:** Product is within its valid expiry period and has no overdue service.
- **Expiring Soon:** Product is approaching its expiry date based on the configured reminder settings.
- **Expired:** Product's expiry date has passed.
- **Service Due Soon:** A scheduled service is approaching.
- **Service Overdue:** The scheduled service date has passed without being marked complete.
- **Out of Stock:** Available quantity is zero.
- **Needs Review:** Important product information is missing, invalid, or requires confirmation.

Use green for good status, orange or yellow for upcoming attention, red for expired or overdue items, and neutral colors for other states. Maintain accessible color contrast in both light and dark themes.

### Dashboard Integration

Display summary cards for:
- Total Products.
- Products Expiring Soon.
- Expired Products.
- Upcoming Services.
- Overdue Services.
- Products Needing Attention.

Provide a dedicated "Needs Attention" section that shows the most urgent items first.

Allow users to tap a status card to view the corresponding filtered product list.

Do not treat an expired product as automatically discarded. Its stock must remain recorded until the user consumes, removes, or explicitly records the relevant quantity as lost.

Calculate status dynamically from the product's current data. Avoid storing contradictory status values when they can be derived reliably.

## 2. Warranty and Service History

Extend product management to support household appliances, electronics, furniture, and other maintainable assets.

### Warranty Information

Add optional fields for:
- Warranty start date.
- Warranty expiry date.
- Warranty provider or manufacturer.
- Warranty reference number.
- Proof-of-purchase attachment or document reference.
- Warranty notes.

Provide reminders before warranty expiry using the application's shared reminder configuration.

Do not require warranty information for ordinary consumable products.

### Service Scheduling

Allow users to create service schedules for products such as air conditioners, washing machines, refrigerators, water purifiers, and other appliances.

Each service schedule should support:
- Service type.
- Service title and description.
- Last service date.
- Next service date.
- Recurrence interval, if applicable.
- Service provider or technician.
- Estimated service cost.
- Reminder enabled/disabled.

Support one-time and recurring services.

### Service History

Create a service history screen for each maintainable product.

Record completed services with:
- Service date.
- Service type.
- Description of work performed.
- Provider or technician.
- Actual cost.
- Notes.
- Optional receipt or document reference.

When a service is marked complete, allow the user to update the next service date or calculate it from the recurring interval.

Preserve previous service records when the schedule changes.

Use separate, clearly distinguishable notification titles for expiry, warranty, and service reminders.

Examples:
- "Expiry Reminder: Milk"
- "Warranty Expiring: Washing Machine"
- "Service Reminder: Air Conditioner"

## 3. Smart Notification Center

Create a dedicated notification center that acts as the central place for product expiry alerts, warranty reminders, service reminders, and other important application notifications.

### Notification Categories

Support the following notification types:
- Product Expiry.
- Service Reminder.
- Warranty Expiry.
- Stock Alert, when enabled.
- Application and backup status notifications, where appropriate.

### Notification History

Persist notification history in the local database.

Each notification record should include:
- Unique notification ID.
- Related product ID, where applicable.
- Related batch, service, or warranty record ID, where applicable.
- Notification type.
- Title and message.
- Scheduled date and time, where applicable.
- Creation timestamp.
- Read/unread status.
- Optional delivery and interaction timestamps.

### UI and Behavior

- Highlight unread notifications.
- Display read notifications in a muted style without making them inaccessible.
- Show an unread notification count.
- Support All, Unread, Read, Expiry, Service, and Warranty filters.
- Group notifications into Today, Yesterday, and Earlier sections.
- Allow users to mark one notification or all notifications as read.
- Navigate to the associated product, service record, or warranty details when tapped.
- Mark a notification as read when the user opens it.
- Handle notification taps when the application is closed, in the background, or already running.
- Preserve notification history after notifications are dismissed from the operating system.

Avoid duplicate reminders for the same event and reminder interval.

Keep the shared reminder configuration for expiry, warranty, and service reminders. Users should be able to choose intervals such as 1, 2, 3, 7, 14, or 30 days before an event, or enter a custom number of days.

Allow notification categories to be enabled or disabled without creating separate global reminder-day settings for each category.

### Test Notifications

Retain the existing Test Notifications button in settings.

Allow the user to trigger immediate test notifications for relevant expiry, warranty, and service records without waiting for configured reminder dates.

Clearly distinguish test notifications from actual scheduled reminders, and do not modify product dates, stock quantities, warranty dates, or service schedules.

Handle notification permissions and platform restrictions gracefully. Do not claim a notification was delivered or read merely because it was scheduled.

## 4. Expiry Calendar

Create a dedicated calendar that provides a visual overview of upcoming product expiries, warranty expiries, and service appointments.

### Calendar Views

Support:
- Monthly calendar.
- Weekly or agenda-style view where practical.
- Upcoming events list.
- Filtered views for Expiry, Service, and Warranty.

Use distinct visual indicators for each event type while maintaining readability in light and dark themes.

### Calendar Behavior

- Display events on their corresponding dates.
- Show an event summary when a date is selected.
- Allow users to tap an event to open its associated product, batch, warranty, or service record.
- Show multiple events occurring on the same day.
- Display expired products separately from upcoming expiry events.
- Support navigation between months and a quick action to return to today.
- Respect the selected language and locale for date formatting.
- Handle missing dates without creating incorrect calendar entries.

The calendar must use locally stored data and update immediately when relevant product or service information changes.

Do not rely on an external calendar service for core functionality.

## 5. Backup and Restore

Implement a reliable local backup and restore system to protect users' household product information.

### Backup Contents

Support backing up:
- Product records.
- Product batches and quantities.
- Categories and storage locations.
- Expiry and service schedules.
- Warranty information.
- Service history.
- Notification history and read/unread status.
- Shared reminder configuration.
- Relevant application preferences.
- Stock and loss transaction history.

Include product images and other local attachments where practical, using a documented archive structure.

### Backup Options

Provide:
- Manual backup.
- Export to a user-selected file location using an appropriate platform file picker.
- Restore from a previously generated backup.
- Backup creation date and last successful backup status.
- Clear feedback when backup or restore succeeds or fails.

Where practical, support a portable, versioned JSON backup format packaged with associated images and attachments.

Validate the backup format, version, required fields, and data integrity before restoring.

### Restore Behavior

Before restoring, show a confirmation dialog explaining whether the operation will merge records or replace existing application data.

Do not silently overwrite existing data.

Where supported, offer a merge option that prevents duplicate records using stable identifiers and clearly defined conflict-resolution rules.

If a restore fails, preserve the existing database and report the problem clearly. Use a transaction or staging database where appropriate to avoid partial restoration.

### Security and Privacy

Product data may contain personal household information.

- Keep backups in a user-controlled location.
- Offer encrypted backups when feasible, with secure handling of encryption keys or passwords.
- Never embed passwords or encryption keys in source code.
- Do not upload backups to a remote service without explicit user consent.
- Explain that losing an encryption password may make an encrypted backup unrecoverable.
- Exclude temporary files and unnecessary cached data.

### Scheduled Backup

Consider optional automatic local backups at configurable intervals.

Explain platform restrictions on background execution and avoid promising that backups will run at an exact time when the operating system does not guarantee it.

Provide a visible warning when no recent backup exists, and allow users to back up their data manually at any time.

## 6. Data Model and Integration Requirements

Integrate these features into the existing local-first architecture.

Extend the existing database with suitable models or tables for:
- Product health information, where information cannot be derived.
- Warranty records.
- Service schedules.
- Service history.
- Notification history.
- Calendar events, if separate event storage is necessary.
- Backup metadata.
- Stock transactions and loss records.

Avoid unnecessary duplication. Calendar events and product health statuses should preferably be derived from the source records unless a specific persistence requirement justifies separate storage.

Use stable record identifiers and explicit relationships. Preserve relevant historical information when active products or schedules are edited or deleted.

Update scheduled notifications when relevant dates or shared reminder intervals change.

Ensure that product status, notification history, service schedules, warranty records, and stock quantities remain consistent.

## 7. UI, Theme, and Navigation Integration

Integrate the new features into the existing Product Care interface.

Maintain:
- Light, dark, and system-default themes.
- Consistent colors, typography, spacing, and icons.
- Responsive layouts without Flutter RenderFlex overflow.
- Accessible text and controls in both themes.
- Smooth navigation and appropriate animations.
- Correct navigation from dashboard cards, calendar events, and notifications.
- Localization for all user-facing labels and notification messages.

Keep the five main navigation destinations as Home, Products, Calendar, Alerts, and Settings.

Access warranty and service history from the relevant product details screen. Access backup and restore from Settings.

Do not overcrowd the dashboard. Prioritize the most urgent expiry and service information and keep less frequently used functionality within the relevant detail screens.

## 8. Additional Acceptance Tests

Verify the following:

1. Product health statuses update correctly when expiry dates, quantities, and service schedules change.
2. Expired products remain in stock until the user explicitly records consumption or loss.
3. Warranty reminders are generated using the shared reminder configuration.
4. Completing a service updates its status and preserves service history.
5. Calendar events open the correct related record.
6. Notifications navigate to the correct product, service, or warranty details and update their read status.
7. Test notifications do not alter actual schedules or product information.
8. Backups preserve product records, batches, service history, and notification history.
9. Invalid or corrupted backups are rejected without damaging existing data.
10. Theme and language preferences are preserved across application restarts.
11. All new screens remain usable on narrow devices and under both light and dark themes.
12. Notification scheduling failures and unavailable permissions produce understandable feedback.

**Final requirement:** These features must be implemented as integrated, functional parts of Product Care, not isolated demo screens. Preserve the existing requirements for AI product scanning, local database storage, manual verification, stock-loss recording, the animated splash screen, custom application and notification icons, and robust error handling.

## Restock Product / Smart Shopping Search

Implement a **Restock Product** feature designed for personal and household users. Integrate it with Product Care's existing product management, stock tracking, expiry status, and dashboard.

### 1. When to Show Restock Product
- Show a **Restock Product** action for expired products, out-of-stock products, and products that users want to purchase again.
- Allow users to access the action from the product detail screen, relevant product cards, and the dashboard when appropriate.
- Do not automatically mark stock as lost or remove stock merely because a product has expired.
- Keep restocking separate from recording stock loss or consumption.

### 2. Smart Product Search
- Build the search query dynamically using available product information:
  - Product name
  - Brand
  - Model or product variant
  - Pack size, weight, or volume
  - Barcode or other useful identifiers when supported
- Example: `Amul Taaza Milk 1L`.
- Encode search terms correctly before generating URLs.
- Avoid duplicate words and gracefully handle missing product details.

### 3. Supported Search Platforms
Provide a platform-selection sheet or dialog with options such as:
- **Google Search** — broad product results and potentially nearby shops.
- **Amazon India** — search matching product listings.
- **Flipkart** — search matching product listings.
- **Grocery platforms** — such as Blinkit, Zepto, or BigBasket, when their search links or deep links are verified and supported.
- **Copy Product Name** — copy the generated search query for use in another app or website.

Use appropriate public search URLs for the initial implementation. Do not require paid APIs for basic search-link functionality. Verify platform URL patterns and gracefully handle unsupported links, missing apps, launch failures, and unavailable platforms.

### 4. Flutter Implementation
- Use a suitable Flutter URL-launching package, such as `url_launcher`, to open search links in the browser or the appropriate app when supported.
- Keep URL construction and platform-specific search logic in a dedicated service rather than duplicating it across UI screens.
- Use URL encoding correctly; do not construct search URLs by manually replacing spaces alone.
- Validate generated URLs and handle exceptions without crashing the app.
- If opening a platform fails, offer Google Search and Copy Product Name as fallbacks.
- Do not hardcode API keys or introduce unnecessary backend dependencies.
- Keep the feature modular so official shopping APIs or affiliate links can be added later if needed.

### 5. User Experience and Accuracy
- Display a clear **Restock Product** action without making the interface crowded.
- If multiple shopping platforms are supported, allow users to choose their preferred platform.
- Optionally remember the preferred platform in Settings, while keeping the other options accessible.
- Never claim that a product is in stock, available for delivery, identical to the original, or cheaper unless that information has been verified.
- Do not scrape shopping websites or represent external search results as verified in-app product data.
- Opening online search requires internet connectivity; copying the saved product name should work offline.
- Keep the feature optional and suitable for personal household shopping rather than business procurement.

### 6. Testing and Acceptance Criteria
- Test search generation with product names containing spaces, special characters, non-English text, and missing brand or pack-size details.
- Verify that each supported platform receives the correct encoded query.
- Test empty product names, invalid URLs, missing apps, failed link launches, and fallback actions.
- Verify that expired and out-of-stock products can be restocked without automatically changing stock quantities or deleting stock-loss history.
- Confirm that the feature works in both light and dark themes and does not cause layout overflow.
- Ensure that Product Care's core product, expiry, service, notification, and stock-management features continue to work offline.

