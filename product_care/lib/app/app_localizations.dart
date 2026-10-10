import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/date_formatters.dart';

class ProductCareLocalizations {
  const ProductCareLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('hi'), Locale('gu')];

  static const LocalizationsDelegate<ProductCareLocalizations> delegate =
      _ProductCareLocalizationsDelegate();

  static ProductCareLocalizations of(BuildContext context) =>
      Localizations.of<ProductCareLocalizations>(
        context,
        ProductCareLocalizations,
      )!;

  String translate(String source, [Map<String, Object?> args = const {}]) {
    final translated = _translations[locale.languageCode]?[source] ?? source;
    return args.entries.fold(
      translated,
      (text, entry) => text.replaceAll('{${entry.key}}', '${entry.value}'),
    );
  }

  static const Map<String, Map<String, String>> _translations = {
    'hi': {
      'Home': 'होम',
      'Products': 'उत्पाद',
      'Calendar': 'कैलेंडर',
      'Alerts': 'अलर्ट',
      'Settings': 'सेटिंग्स',
      'Product Care': 'प्रोडक्ट केयर',
      'Your home, well cared for': 'आपके घर की बेहतर देखभाल',
      'Good morning': 'सुप्रभात',
      'Good afternoon': 'नमस्कार',
      'Good evening': 'शुभ संध्या',
      'A little care goes a long way': 'थोड़ी सी देखभाल बहुत काम आती है',
      'You’re all caught up.': 'अभी सब ठीक है।',
      '{count} {itemLabel} need a little attention':
          '{count} चीज़ों पर थोड़ा ध्यान दें',
      '{count} item needs a little attention':
          '{count} चीज़ पर थोड़ा ध्यान दें',
      'Review products': 'उत्पाद देखें',
      'Your overview': 'आपका सारांश',
      'View all': 'सभी देखें',
      'Expiring soon': 'जल्द समाप्त होने वाले',
      'units in total': 'कुल इकाइयाँ',
      'Needs attention': 'ध्यान देने योग्य',
      'low or out of stock': 'कम या स्टॉक समाप्त',
      'Quick actions': 'त्वरित कार्रवाइयाँ',
      'Add product': 'उत्पाद जोड़ें',
      'Enter details': 'विवरण भरें',
      'Scan item': 'आइटम स्कैन करें',
      'Camera scan': 'कैमरा स्कैन',
      'Coming up': 'आने वाले',
      'All clear for now': 'अभी सब ठीक है',
      'Your products and schedules are up to date.':
          'आपके उत्पाद और समय-सारणी अपडेट हैं।',
      'items in your home': 'घर के आइटम',
      '{count} items in your home': 'घर में {count} आइटम',
      'Search products': 'उत्पाद खोजें',
      'All': 'सभी',
      'Expiring': 'समाप्ति नज़दीक',
      'In stock': 'स्टॉक में',
      'Low stock': 'कम स्टॉक',
      'Service': 'सर्विस',
      'No matching products': 'कोई मिलता-जुलता उत्पाद नहीं',
      'Try another search or add a product.':
          'दूसरी खोज करें या उत्पाद जोड़ें।',
      'Expiry dates and service reminders':
          'समाप्ति तिथियाँ और सर्विस रिमाइंडर',
      'This month': 'इस महीने',
      'Keep an eye on upcoming dates': 'आने वाली तारीख़ों पर ध्यान दें',
      'Upcoming dates': 'आने वाली तारीख़ें',
      'Nothing scheduled': 'कुछ निर्धारित नहीं है',
      'Expiry and service dates will appear here.':
          'समाप्ति और सर्विस की तारीख़ें यहाँ दिखेंगी।',
      'Mark all read': 'सभी को पढ़ा हुआ करें',
      'Expiry and service updates for your products':
          'उत्पादों की समाप्ति और सर्विस अपडेट',
      'You’re up to date': 'आप अपडेट हैं',
      'New reminders will show here when a product needs attention.':
          'ध्यान देने योग्य उत्पादों के रिमाइंडर यहाँ दिखेंगे।',
      'Stock loss recorded': 'स्टॉक हानि दर्ज की गई',
      'Reminder scheduling': 'रिमाइंडर शेड्यूलिंग',
      'Local notification delivery is not configured yet.':
          'डिवाइस नोटिफिकेशन अभी सेट नहीं हैं।',
      'Expiry reminder: {name}': 'समाप्ति रिमाइंडर: {name}',
      'Service reminder: {name}': 'सर्विस रिमाइंडर: {name}',
      '{name} expires today. Review the product details.':
          '{name} आज समाप्त होगा। उत्पाद विवरण देखें।',
      '{name} expires in {days} days. Review the product details.':
          '{name} {days} दिनों में समाप्त होगा। विवरण देखें।',
      '{name} is past its expiry date. Review the product details.':
          '{name} की समाप्ति तिथि बीत चुकी है। विवरण देखें।',
      '{name} is due for service. Review the product details.':
          '{name} की सर्विस का समय है। विवरण देखें।',
      '{name} requires servicing in {days} days. Review the product details.':
          '{name} की सर्विस {days} दिनों में करनी है। विवरण देखें।',
      'All alerts marked as read': 'सभी अलर्ट पढ़े हुए चिह्नित किए',
      'Make Product Care feel like yours': 'प्रोडक्ट केयर को अपने अनुसार बनाएँ',
      'Appearance': 'दिखावट',
      'Choose light, dark, or system theme': 'लाइट, डार्क या सिस्टम थीम चुनें',
      'Light': 'लाइट',
      'Dark': 'डार्क',
      'System': 'सिस्टम',
      'Reminders': 'रिमाइंडर',
      'Shared reminder preferences': 'साझा रिमाइंडर सेटिंग',
      'Remind me before': 'पहले रिमाइंड करें',
      'Test notifications': 'नोटिफिकेशन जाँचें',
      'Preview an expiry reminder': 'समाप्ति रिमाइंडर का पूर्वावलोकन',
      'Language': 'भाषा',
      'English': 'अंग्रेज़ी',
      'Hindi': 'हिंदी',
      'Gujarati': 'ગુજરાતી',
      'Choose language': 'भाषा चुनें',
      'Backup & restore': 'बैकअप और पुनर्स्थापना',
      'Back up or restore your local data':
          'स्थानीय डेटा का बैकअप लें या पुनर्स्थापित करें',
      'Create backup now': 'अभी बैकअप बनाएँ',
      'Restore a backup': 'बैकअप पुनर्स्थापित करें',
      'Choose a backup saved on this device': 'इस डिवाइस पर सहेजा बैकअप चुनें',
      'PRODUCT CARE  ·  YOUR HOME, WELL CARED FOR':
          'प्रोडक्ट केयर · आपके घर की बेहतर देखभाल',
      'Reminder interval': 'रिमाइंडर अंतराल',
      'Shared for expiry and service reminders.':
          'समाप्ति और सर्विस रिमाइंडर के लिए साझा।',
      '{days} day before': '{days} दिन पहले',
      '{days} days before': '{days} दिन पहले',
      'Custom days': 'कस्टम दिन',
      'Enter days (1–365)': 'दिन दर्ज करें (1–365)',
      'Save reminder': 'रिमाइंडर सहेजें',
      'Enter a valid number of days.': 'दिनों की सही संख्या दर्ज करें।',
      'Done': 'हो गया',
      'Product details': 'उत्पाद विवरण',
      'Available stock': 'उपलब्ध स्टॉक',
      'Best before': 'समाप्ति तिथि',
      'Next service': 'अगली सर्विस',
      'Restock product': 'उत्पाद फिर से खरीदें',
      'Remove product': 'उत्पाद हटाएँ',
      'Add a product': 'उत्पाद जोड़ें',
      'Product name *': 'उत्पाद का नाम *',
      'Brand or manufacturer': 'ब्रांड या निर्माता',
      'Category': 'श्रेणी',
      'Product type': 'उत्पाद का प्रकार',
      'Storable': 'भंडारण योग्य',
      'General': 'सामान्य',
      'Quantity': 'मात्रा',
      'Unit cost (₹)': 'प्रति इकाई लागत (₹)',
      'Choose next service date': 'अगली सर्विस तिथि चुनें',
      'Choose expiry date': 'समाप्ति तिथि चुनें',
      'Save product': 'उत्पाद सहेजें',
      'Add a name and a valid quantity.': 'नाम और सही मात्रा दर्ज करें।',
      'Scan a product': 'उत्पाद स्कैन करें',
      'Camera and product recognition are not connected yet. You can add product details manually.': 'कैमरा और उत्पाद पहचान अभी उपलब्ध नहीं हैं। आप विवरण स्वयं जोड़ सकते हैं।',
      'Close': 'बंद करें',
      'Enter manually': 'स्वयं दर्ज करें',
      'Record stock loss': 'स्टॉक हानि दर्ज करें',
      'Available: {quantity} {unit}': 'उपलब्ध: {quantity} {unit}',
      'Quantity to mark as lost': 'हानि के रूप में दर्ज मात्रा',
      'Cancel': 'रद्द करें',
      'Confirm loss': 'हानि की पुष्टि करें',
      'Enter a quantity from 1 to {quantity}.':
          '1 से {quantity} तक मात्रा दर्ज करें।',
      'Google Search': 'Google खोज',
      'Search the web': 'वेब पर खोजें',
      'Search product listings': 'उत्पाद सूची खोजें',
      'Search groceries': 'किराने का सामान खोजें',
      'Copy search terms': 'खोज शब्द कॉपी करें',
      'Use in another shopping app': 'दूसरे शॉपिंग ऐप में उपयोग करें',
      'Search results are provided by external services. Product availability is not verified in Product Care.': 'खोज नतीजे बाहरी सेवाओं से आते हैं। उपलब्धता की पुष्टि प्रोडक्ट केयर नहीं करता।',
      'Test preview shown in Alerts. Device notifications are not configured yet.': 'अलर्ट में परीक्षण पूर्वावलोकन दिखाया गया। डिवाइस नोटिफिकेशन अभी सेट नहीं हैं।',
      'Reminder preview is not sent: device notifications are not configured yet.':
          'रिमाइंडर नहीं भेजा गया: डिवाइस नोटिफिकेशन सेट नहीं हैं।',
      'There are no expiry or service dates available to preview.':
          'पूर्वावलोकन के लिए समाप्ति या सर्विस तिथि उपलब्ध नहीं है।',
      'Could not open that search': 'खोज नहीं खुल सकी',
      'Try Google Search or copy the product search terms.':
          'Google खोज आज़माएँ या खोज शब्द कॉपी करें।',
      'Google Search could not be opened.': 'Google खोज नहीं खुल सकी।',
      'Product search terms copied.': 'उत्पाद खोज शब्द कॉपी किए गए।',
      'Backup saved: {name}': 'बैकअप सहेजा गया: {name}',
      'Backup could not be created.': 'बैकअप नहीं बन सका।',
      'No Product Care backups are saved on this device yet.':
          'इस डिवाइस पर अभी कोई प्रोडक्ट केयर बैकअप नहीं है।',
      'Choose a backup to restore': 'पुनर्स्थापना के लिए बैकअप चुनें',
      'Products, loss history, and reminder days':
          'उत्पाद, हानि इतिहास और रिमाइंडर दिन',
      'Restore this backup?': 'यह बैकअप पुनर्स्थापित करें?',
      'This replaces the products, stock-loss history, and reminder days currently saved in Product Care.': 'इससे अभी सहेजे उत्पाद, स्टॉक हानि इतिहास और रिमाइंडर दिन बदल जाएँगे।',
      'Restore backup': 'बैकअप पुनर्स्थापित करें',
      'Backup restored from {name}.': '{name} से बैकअप पुनर्स्थापित हुआ।',
      'Backup was rejected: {reason}': 'बैकअप अस्वीकार हुआ: {reason}',
      'Backup could not be restored. Your saved data was kept.':
          'बैकअप पुनर्स्थापित नहीं हुआ। आपका सहेजा डेटा सुरक्षित है।',
      'Today': 'आज',
      'Expiry': 'समाप्ति',
      'No expiry date': 'समाप्ति तिथि नहीं',
      'Expired': 'समाप्त हो गया',
      'Service expired': 'सर्विस समाप्त हो गई',
      'Warranty expired': 'वारंटी समाप्त हो गई',
      'Service due today': 'आज सर्विस होनी है',
      'Exit Product Care?': 'प्रोडक्ट केयर से बाहर निकलें?',
      'Are you sure you want to exit the app?': 'क्या आप वाकई ऐप बंद करना चाहते हैं?',
      'Exit': 'बाहर निकलें',
      'Add stock': 'स्टॉक जोड़ें',
      'Scan': 'स्कैन',
      'Out of stock': 'स्टॉक समाप्त',
      'units': 'इकाइयां',
      'pieces': 'टुकड़े',
      'kg': 'किग्रा',
      'g': 'ग्राम',
      'L': 'लीटर',
      'mL': 'मिली',
      'packets': 'पैकेट',
      'bottles': 'बोतलें',
      'boxes': 'डिब्बे',
      'bags': 'थैलियां',
      'dozen': 'दर्जन',
      'sets': 'सेट',
      'other': 'अन्य',
      'Other': 'अन्य',
      'Enter other UOM': 'अन्य इकाई दर्ज करें',
      'Import backup file': 'फ़ाइल आयात करें',
      'Import from device': 'डिवाइस से बैकअप आयात करें',
      'Choose or import a backup': 'बैकअप चुनें या आयात करें',
      'Expires today': 'आज समाप्त होगा',
      'Expires in {days} days': '{days} दिनों में समाप्त होगा',
      'Service in {days} days': '{days} दिनों में सर्विस',
      '{type} · Today': '{type} · आज',
      '{type} · {days} days left': '{type} · {days} दिन शेष',
      '{count} items need a little attention':
          '{count} चीज़ों पर थोड़ा ध्यान दें',
      '{name} added to your products.': '{name} आपके उत्पादों में जोड़ा गया।',
      '{name} removed.': '{name} हटा दिया गया।',
      'Stock changed before the loss could be recorded.':
          'हानि दर्ज होने से पहले स्टॉक बदल गया।',
      '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.':
          '{quantity} {unit} की हानि दर्ज। शेष स्टॉक: {remaining}।',
      'Saved data could not be loaded. Restore a local backup.':
          'सहेजा डेटा लोड नहीं हुआ। स्थानीय बैकअप पुनर्स्थापित करें।',
      'Could not save local Product Care data.':
          'प्रोडक्ट केयर का स्थानीय डेटा सहेजा नहीं जा सका।',
      'Sharing is unavailable on this device.':
          'इस डिवाइस पर साझा करना उपलब्ध नहीं है।',
      'Excel export could not be created.': 'Excel निर्यात नहीं बन सका।',
      'Export and share Excel': 'Excel निर्यात करें और साझा करें',
      'Share products and stock-loss data':
          'उत्पाद और स्टॉक हानि डेटा साझा करें',
      'Shared reminders updated for this session.':
          'इस सत्र के लिए साझा रिमाइंडर अपडेट हुए।',
      'Off': 'बंद',
      'Dairy': 'डेयरी',
      'Pantry': 'रसोई',
      'Health': 'स्वास्थ्य',
      'Household': 'घरेलू सामान',
      'Appliances': 'उपकरण',
      'Jan': 'जन',
      'Feb': 'फ़र',
      'Mar': 'मार्च',
      'Apr': 'अप्रै',
      'May': 'मई',
      'Jun': 'जून',
      'Jul': 'जुल',
      'Aug': 'अग',
      'Sep': 'सित',
      'Oct': 'अक्टू',
      'Nov': 'नव',
      'Dec': 'दिस',
      'Excel file shared.': 'Excel फ़ाइल साझा की गई।',
      'Product': 'उत्पाद',
      'Brand': 'ब्रांड',
      'Unit': 'इकाई',
      'Expiry date': 'समाप्ति तिथि',
      'Unit cost': 'इकाई लागत',
      'Stock losses': 'स्टॉक हानि',
      'Stock loss history': 'स्टॉक हानि इतिहास',
      'No stock losses recorded': 'कोई स्टॉक हानि दर्ज नहीं है',
      'Setting': 'सेटिंग',
      'Value': 'मान',
      'Reminder preference saved.': 'रिमाइंडर सेटिंग सहेजी गई।',
      'Product actions': 'उत्पाद कार्रवाइयाँ',
      'Unbranded': 'बिना ब्रांड वाला',
      'Saved Product Care data is invalid.':
          'सहेजा गया प्रोडक्ट केयर डेटा अमान्य है।',
      'This backup format is not supported.':
          'यह बैकअप प्रारूप समर्थित नहीं है।',
      'The backup is missing required data.': 'बैकअप में आवश्यक डेटा नहीं है।',
      'A product record in the backup is invalid.':
          'बैकअप में उत्पाद रिकॉर्ड अमान्य है।',
      'Unknown product type.': 'अज्ञात उत्पाद प्रकार।',
      'A product record is missing valid fields.':
          'उत्पाद रिकॉर्ड में आवश्यक जानकारी नहीं है।',
      'Invalid product date.': 'उत्पाद की तारीख अमान्य है।',
      'The backup contains invalid settings or history.':
          'बैकअप में सेटिंग या इतिहास अमान्य है।',
      'The backup file is not valid JSON data.':
          'बैकअप फ़ाइल का JSON डेटा अमान्य है।',
      'That file is not a Product Care backup.':
          'यह फ़ाइल प्रोडक्ट केयर बैकअप नहीं है।',
      'Product Care Excel export': 'प्रोडक्ट केयर Excel निर्यात',
      'Product inventory and stock-loss data': 'उत्पाद सूची और स्टॉक हानि डेटा',
    },
    'gu': {
      'Home': 'હોમ',
      'Products': 'ઉત્પાદનો',
      'Calendar': 'કૅલેન્ડર',
      'Alerts': 'ચેતવણીઓ',
      'Settings': 'સેટિંગ્સ',
      'Product Care': 'પ્રોડક્ટ કેર',
      'Your home, well cared for': 'તમારા ઘરની સારી સંભાળ',
      'Good morning': 'સુપ્રભાત',
      'Good afternoon': 'શુભ બપોર',
      'Good evening': 'શુભ સાંજ',
      'A little care goes a long way': 'થોડી સંભાળ ઘણો ફરક લાવે છે',
      'You’re all caught up.': 'હાલ બધું બરાબર છે.',
      '{count} {itemLabel} need a little attention':
          '{count} વસ્તુઓ પર થોડું ધ્યાન આપો',
      '{count} item needs a little attention':
          '{count} વસ્તુ પર થોડું ધ્યાન આપો',
      'Review products': 'ઉત્પાદનો જુઓ',
      'Your overview': 'તમારો સારાંશ',
      'View all': 'બધું જુઓ',
      'Expiring soon': 'ટૂંક સમયમાં સમાપ્ત',
      'Available stock': 'ઉપલબ્ધ જથ્થો',
      'units in total': 'કુલ એકમો',
      'Needs attention': 'ધ્યાન આપવાની જરૂર',
      'low or out of stock': 'ઓછો કે ખાલી જથ્થો',
      'Quick actions': 'ઝડપી ક્રિયાઓ',
      'Add product': 'ઉત્પાદન ઉમેરો',
      'Enter details': 'વિગતો દાખલ કરો',
      'Scan item': 'વસ્તુ સ્કેન કરો',
      'Camera scan': 'કેમેરા સ્કેન',
      'Coming up': 'આગામી',
      'All clear for now': 'હાલ બધું બરાબર છે',
      'Your products and schedules are up to date.':
          'તમારા ઉત્પાદનો અને સમયપત્રક અપડેટ છે.',
      'items in your home': 'ઘરની વસ્તુઓ',
      '{count} items in your home': 'ઘરમાં {count} વસ્તુઓ',
      'Search products': 'ઉત્પાદનો શોધો',
      'All': 'બધા',
      'Expiring': 'સમાપ્તિ નજીક',
      'In stock': 'જથ્થામાં ઉપલબ્ધ',
      'Low stock': 'ઓછો જથ્થો',
      'Service': 'સર્વિસ',
      'No matching products': 'મેળ ખાતા ઉત્પાદનો નથી',
      'Try another search or add a product.':
          'બીજી શોધ કરો અથવા ઉત્પાદન ઉમેરો.',
      'Expiry dates and service reminders':
          'સમાપ્તિ તારીખો અને સર્વિસ રિમાઇન્ડર',
      'This month': 'આ મહિને',
      'Keep an eye on upcoming dates': 'આગામી તારીખો પર ધ્યાન રાખો',
      'Upcoming dates': 'આગામી તારીખો',
      'Nothing scheduled': 'કંઈ નિર્ધારિત નથી',
      'Expiry and service dates will appear here.':
          'સમાપ્તિ અને સર્વિસની તારીખો અહીં દેખાશે.',
      'Mark all read': 'બધાને વાંચેલા તરીકે ચિહ્નિત કરો',
      'Expiry and service updates for your products':
          'તમારા ઉત્પાદનોના સમાપ્તિ અને સર્વિસ અપડેટ',
      'You’re up to date': 'તમે અપડેટ છો',
      'New reminders will show here when a product needs attention.':
          'ઉત્પાદન પર ધ્યાન આપવાનું હશે ત્યારે રિમાઇન્ડર અહીં દેખાશે.',
      'Stock loss recorded': 'જથ્થાનું નુકસાન નોંધાયું',
      'Reminder scheduling': 'રિમાઇન્ડર સમયપત્રક',
      'Local notification delivery is not configured yet.':
          'ડિવાઇસ નોટિફિકેશન હજી સેટ નથી.',
      'Expiry reminder: {name}': 'સમાપ્તિ રિમાઇન્ડર: {name}',
      'Service reminder: {name}': 'સર્વિસ રિમાઇન્ડર: {name}',
      '{name} expires today. Review the product details.':
          '{name} આજે સમાપ્ત થાય છે. વિગતો જુઓ.',
      '{name} expires in {days} days. Review the product details.':
          '{name} {days} દિવસમાં સમાપ્ત થાય છે. વિગતો જુઓ.',
      '{name} is past its expiry date. Review the product details.':
          '{name}ની સમાપ્તિ તારીખ વીતી ગઈ છે. વિગતો જુઓ.',
      '{name} is due for service. Review the product details.':
          '{name}ની સર્વિસ બાકી છે. વિગતો જુઓ.',
      '{name} requires servicing in {days} days. Review the product details.':
          '{name}ની સર્વિસ {days} દિવસમાં કરાવવી પડશે. વિગતો જુઓ.',
      'All alerts marked as read': 'બધી ચેતવણીઓ વાંચેલી તરીકે ચિહ્નિત થઈ',
      'Make Product Care feel like yours': 'પ્રોડક્ટ કેરને તમારા મુજબ બનાવો',
      'Appearance': 'દેખાવ',
      'Choose light, dark, or system theme':
          'લાઇટ, ડાર્ક અથવા સિસ્ટમ થીમ પસંદ કરો',
      'Light': 'લાઇટ',
      'Dark': 'ડાર્ક',
      'System': 'સિસ્ટમ',
      'Reminders': 'રિમાઇન્ડર',
      'Shared reminder preferences': 'સાંઝા રિમાઇન્ડર પસંદગીઓ',
      'Remind me before': 'પહેલાં યાદ અપાવો',
      'Test notifications': 'નોટિફિકેશન તપાસો',
      'Preview an expiry reminder': 'સમાપ્તિ રિમાઇન્ડરનું પૂર્વાવલોકન',
      'Language': 'ભાષા',
      'English': 'અંગ્રેજી',
      'Hindi': 'હિન્દી',
      'Gujarati': 'ગુજરાતી',
      'Choose language': 'ભાષા પસંદ કરો',
      'Backup & restore': 'બેકઅપ અને પુનઃસ્થાપિત કરો',
      'Back up or restore your local data':
          'સ્થાનિક ડેટાનો બેકઅપ લો અથવા પુનઃસ્થાપિત કરો',
      'Create backup now': 'હમણાં બેકઅપ બનાવો',
      'Restore a backup': 'બેકઅપ પુનઃસ્થાપિત કરો',
      'Choose a backup saved on this device':
          'આ ડિવાઇસ પર સાચવેલો બેકઅપ પસંદ કરો',
      'PRODUCT CARE  ·  YOUR HOME, WELL CARED FOR':
          'પ્રોડક્ટ કેર · તમારા ઘરની સારી સંભાળ',
      'Reminder interval': 'રિમાઇન્ડર અંતર',
      'Shared for expiry and service reminders.':
          'સમાપ્તિ અને સર્વિસ રિમાઇન્ડર માટે એકસરખું.',
      '{days} day before': '{days} દિવસ પહેલાં',
      '{days} days before': '{days} દિવસ પહેલાં',
      'Custom days': 'પસંદગીના દિવસો',
      'Enter days (1–365)': 'દિવસ દાખલ કરો (1–365)',
      'Save reminder': 'રિમાઇન્ડર સાચવો',
      'Enter a valid number of days.': 'દિવસોની માન્ય સંખ્યા દાખલ કરો.',
      'Done': 'થઈ ગયું',
      'Product details': 'ઉત્પાદન વિગતો',
      'Best before': 'સમાપ્તિ તારીખ',
      'Next service': 'આગામી સર્વિસ',
      'Restock product': 'ઉત્પાદન ફરીથી ખરીદો',
      'Record stock loss': 'જથ્થાનું નુકસાન નોંધો',
      'Remove product': 'ઉત્પાદન દૂર કરો',
      'Add a product': 'ઉત્પાદન ઉમેરો',
      'Product name *': 'ઉત્પાદનનું નામ *',
      'Brand or manufacturer': 'બ્રાન્ડ અથવા ઉત્પાદક',
      'Category': 'શ્રેણી',
      'Product type': 'ઉત્પાદનનો પ્રકાર',
      'Storable': 'સંગ્રહ કરી શકાય તેવું',
      'General': 'સામાન્ય',
      'Quantity': 'જથ્થો',
      'Unit cost (₹)': 'એકમ દીઠ કિંમત (₹)',
      'Choose next service date': 'આગામી સર્વિસ તારીખ પસંદ કરો',
      'Choose expiry date': 'સમાપ્તિ તારીખ પસંદ કરો',
      'Save product': 'ઉત્પાદન સાચવો',
      'Add a name and a valid quantity.': 'નામ અને યોગ્ય જથ્થો દાખલ કરો.',
      'Scan a product': 'ઉત્પાદન સ્કેન કરો',
      'Close': 'બંધ કરો',
      'Enter manually': 'મેન્યુઅલી દાખલ કરો',
      'Available: {quantity} {unit}': 'ઉપલબ્ધ: {quantity} {unit}',
      'Quantity to mark as lost': 'નુકસાન તરીકે નોંધવાનો જથ્થો',
      'Cancel': 'રદ કરો',
      'Confirm loss': 'નુકસાનની પુષ્ટિ કરો',
      'Enter a quantity from 1 to {quantity}.':
          '1 થી {quantity} સુધીનો જથ્થો દાખલ કરો.',
      'Google Search': 'Google શોધ',
      'Search the web': 'વેબ પર શોધો',
      'Search product listings': 'ઉત્પાદનોની સૂચિ શોધો',
      'Search groceries': 'કરિયાણું શોધો',
      'Copy search terms': 'શોધના શબ્દો કૉપી કરો',
      'Use in another shopping app': 'બીજી શોપિંગ એપમાં વાપરો',
      'Search results are provided by external services. Product availability is not verified in Product Care.': 'શોધ પરિણામો બાહ્ય સેવાઓ આપે છે. પ્રોડક્ટ કેર ઉપલબ્ધતાની ખાતરી આપતું નથી.',
      'Could not open that search': 'શોધ ખોલી શકાઈ નથી',
      'Try Google Search or copy the product search terms.':
          'Google શોધ અજમાવો અથવા શોધના શબ્દો કૉપી કરો.',
      'Google Search could not be opened.': 'Google શોધ ખોલી શકાઈ નથી.',
      'Product search terms copied.': 'ઉત્પાદન શોધના શબ્દો કૉપી થયા.',
      'Backup saved: {name}': 'બેકઅપ સાચવાયો: {name}',
      'Backup could not be created.': 'બેકઅપ બની શક્યો નથી.',
      'No Product Care backups are saved on this device yet.':
          'આ ડિવાઇસ પર હજી પ્રોડક્ટ કેરનો બેકઅપ નથી.',
      'Choose a backup to restore': 'પુનઃસ્થાપિત કરવા બેકઅપ પસંદ કરો',
      'Products, loss history, and reminder days':
          'ઉત્પાદનો, નુકસાનનો ઇતિહાસ અને રિમાઇન્ડરના દિવસો',
      'Restore this backup?': 'આ બેકઅપ પુનઃસ્થાપિત કરવો છે?',
      'This replaces the products, stock-loss history, and reminder days currently saved in Product Care.': 'આ પ્રોડક્ટ કેરમાં હાલ સાચવેલા ઉત્પાદનો, નુકસાનનો ઇતિહાસ અને રિમાઇન્ડરના દિવસો બદલી દેશે.',
      'Restore backup': 'બેકઅપ પુનઃસ્થાપિત કરો',
      'Backup restored from {name}.': '{name}માંથી બેકઅપ પુનઃસ્થાપિત થયો.',
      'Backup was rejected: {reason}': 'બેકઅપ નામંજૂર થયો: {reason}',
      'Backup could not be restored. Your saved data was kept.':
          'બેકઅપ પુનઃસ્થાપિત થયો નથી. તમારો સાચવેલો ડેટા સુરક્ષિત છે.',
      'Today': 'આજે',
      'Expiry': 'સમાપ્તિ',
      'No expiry date': 'સમાપ્તિ તારીખ નથી',
      'Expired': 'સમાપ્ત થયું',
      'Service expired': 'સર્વિસ સમાપ્ત થઈ ગઈ',
      'Warranty expired': 'વોરંટી સમાપ્ત થઈ ગઈ',
      'Service due today': 'આજે સર્વિસ થવાની છે',
      'Exit Product Care?': 'પ્રોડક્ટ કેરમાંથી બહાર નીકળો?',
      'Are you sure you want to exit the app?': 'શું તમે ખરેખર એપ બંધ કરવા માંગો છો?',
      'Exit': 'બહાર નીકળો',
      'Add stock': 'સ્ટોક ઉમેરો',
      'Scan': 'સ્કેન',
      'Out of stock': 'સ્ટોક ખાલી',
      'units': 'એકમ',
      'pieces': 'ટુકડા',
      'kg': 'કિલો',
      'g': 'ગ્રામ',
      'L': 'લિટર',
      'mL': 'મિલી',
      'packets': 'પેકેટ',
      'bottles': 'બોટલ',
      'boxes': 'બોક્સ',
      'bags': 'થેલીઓ',
      'dozen': 'ડઝન',
      'sets': 'સેટ',
      'other': 'અન્ય',
      'Other': 'અન્ય',
      'Enter other UOM': 'અન્ય માપન એકમ દાખલ કરો',
      'Import backup file': 'ફાઇલ આયાત કરો',
      'Import from device': 'ડિવાઇસમાંથી બેકઅપ આયાત કરો',
      'Choose or import a backup': 'બેકઅપ પસંદ કરો અથવા આયાત કરો',
      'Expires today': 'આજે સમાપ્ત થાય છે',
      'Expires in {days} days': '{days} દિવસમાં સમાપ્ત થાય છે',
      'Service in {days} days': '{days} દિવસમાં સર્વિસ',
      '{type} · Today': '{type} · આજે',
      '{type} · {days} days left': '{type} · {days} દિવસ બાકી',
      '{count} items need a little attention':
          '{count} વસ્તુઓ પર થોડું ધ્યાન આપો',
      '{name} added to your products.': '{name} તમારા ઉત્પાદનોમાં ઉમેરાયું.',
      '{name} removed.': '{name} દૂર થયું.',
      'Stock changed before the loss could be recorded.':
          'નુકસાન નોંધાય તે પહેલાં જથ્થો બદલાયો.',
      '{quantity} {unit} recorded as loss. Remaining stock: {remaining}.':
          '{quantity} {unit}નું નુકસાન નોંધાયું. બાકી જથ્થો: {remaining}.',
      'Saved data could not be loaded. Restore a local backup.':
          'સાચવેલો ડેટા લોડ થયો નથી. સ્થાનિક બેકઅપ પુનઃસ્થાપિત કરો.',
      'Could not save local Product Care data.':
          'પ્રોડક્ટ કેરનો સ્થાનિક ડેટા સાચવી શકાયો નથી.',
      'Sharing is unavailable on this device.':
          'આ ડિવાઇસ પર શેરિંગ ઉપલબ્ધ નથી.',
      'Excel export could not be created.': 'Excel નિકાસ બનાવી શકાઈ નથી.',
      'Export and share Excel': 'Excel નિકાસ કરો અને શેર કરો',
      'Share products and stock-loss data':
          'ઉત્પાદનો અને જથ્થાના નુકસાનનો ડેટા શેર કરો',
      'Shared reminders updated for this session.':
          'આ સત્ર માટે સાંઝા રિમાઇન્ડર અપડેટ થયા.',
      'Off': 'બંધ',
      'Dairy': 'ડેરી',
      'Pantry': 'રસોડું',
      'Health': 'આરોગ્ય',
      'Household': 'ઘરગથ્થુ',
      'Appliances': 'ઉપકરણો',
      'Jan': 'જાન્યુ',
      'Feb': 'ફેબ્રુ',
      'Mar': 'માર્ચ',
      'Apr': 'એપ્રિલ',
      'May': 'મે',
      'Jun': 'જૂન',
      'Jul': 'જુલાઈ',
      'Aug': 'ઑગસ્ટ',
      'Sep': 'સપ્ટે',
      'Oct': 'ઑક્ટો',
      'Nov': 'નવે',
      'Dec': 'ડિસે',
      'Camera and product recognition are not connected yet. You can add product details manually.':
          'કેમેરા અને ઉત્પાદન ઓળખ હજી ઉપલબ્ધ નથી. તમે વિગતો જાતે ઉમેરી શકો છો.',
      'Reminder preview is not sent: device notifications are not configured yet.':
          'રિમાઇન્ડર મોકલાયો નથી: ડિવાઇસ નોટિફિકેશન સેટ નથી.',
      'There are no expiry or service dates available to preview.':
          'પૂર્વાવલોકન માટે સમાપ્તિ અથવા સર્વિસ તારીખ ઉપલબ્ધ નથી.',
      'Excel file shared.': 'Excel ફાઇલ શેર થઈ.',
      'Product': 'ઉત્પાદન',
      'Brand': 'બ્રાન્ડ',
      'Unit': 'એકમ',
      'Expiry date': 'સમાપ્તિ તારીખ',
      'Unit cost': 'એકમ કિંમત',
      'Stock losses': 'જથ્થાનું નુકસાન',
      'Stock loss history': 'જથ્થાના નુકસાનનો ઇતિહાસ',
      'No stock losses recorded': 'જથ્થાનું કોઈ નુકસાન નોંધાયું નથી',
      'Setting': 'સેટિંગ',
      'Value': 'મૂલ્ય',
      'Reminder preference saved.': 'રિમાઇન્ડર પસંદગી સાચવાઈ.',
      'Product actions': 'ઉત્પાદન ક્રિયાઓ',
      'Unbranded': 'બ્રાન્ડ વિનાનું',
      'Saved Product Care data is invalid.':
          'સાચવેલો પ્રોડક્ટ કેર ડેટા અમાન્ય છે.',
      'This backup format is not supported.': 'આ બેકઅપ ફોર્મેટ સપોર્ટેડ નથી.',
      'The backup is missing required data.': 'બેકઅપમાં જરૂરી ડેટા નથી.',
      'A product record in the backup is invalid.':
          'બેકઅપમાં ઉત્પાદન રેકોર્ડ અમાન્ય છે.',
      'Unknown product type.': 'ઉત્પાદનનો પ્રકાર અજ્ઞાત છે.',
      'A product record is missing valid fields.':
          'ઉત્પાદન રેકોર્ડમાં જરૂરી માહિતી નથી.',
      'Invalid product date.': 'ઉત્પાદનની તારીખ અમાન્ય છે.',
      'The backup contains invalid settings or history.':
          'બેકઅપમાં સેટિંગ અથવા ઇતિહાસ અમાન્ય છે.',
      'The backup file is not valid JSON data.':
          'બેકઅપ ફાઇલનું JSON ડેટા અમાન્ય છે.',
      'That file is not a Product Care backup.':
          'આ ફાઇલ પ્રોડક્ટ કેર બેકઅપ નથી.',
      'Product Care Excel export': 'પ્રોડક્ટ કેર Excel નિકાસ',
      'Product inventory and stock-loss data':
          'ઉત્પાદન યાદી અને જથ્થાના નુકસાનનો ડેટા',
    },
  };
}

class _ProductCareLocalizationsDelegate
    extends LocalizationsDelegate<ProductCareLocalizations> {
  const _ProductCareLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ProductCareLocalizations.supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<ProductCareLocalizations> load(Locale locale) =>
      SynchronousFuture(ProductCareLocalizations(locale));

  @override
  bool shouldReload(_ProductCareLocalizationsDelegate old) => false;
}

String tr(
  BuildContext context,
  String source, [
  Map<String, Object?> args = const {},
]) => ProductCareLocalizations.of(context).translate(source, args);

String localizedShortDate(BuildContext context, DateTime date) =>
    '${date.day} ${tr(context, monthName(date))}';

String localizedFullDate(BuildContext context, DateTime date) =>
    '${date.day} ${tr(context, monthName(date))} ${date.year}';
