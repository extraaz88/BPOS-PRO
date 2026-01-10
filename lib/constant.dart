import 'package:bijoy_helper/bijoy_helper.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

const kMainColor = Color(0xFF0073CF);
const kGreyTextColor = Color(0xFF828282);
const kBackgroundColor = Color(0xffF5F3F3);
const kBorderColorTextField = Color(0xFF0073CF);
const kDarkWhite = Color(0xFFF1F7F7);
const kWhite = Color(0xFFffffff);
const kBorderColor = Color(0xFF0073CF);
const kSuccessColor = Colors.green;
const kPremiumPlanColor = Color(0xFF0056B3);
const kPremiumPlanColor2 = Color(0xFF00A8FF);
const kTitleColor = Color(0xFF000000);
const kNeutralColor = Color(0xFF4D4D4D);
const kBorder = Color(0xFF999999);
const updateBorderColor = Color(0xFF0073CF);
bool isPrintEnable = false;
// const String appVersion = '4.9';
String noProductImageUrl = 'images/no_product_image.png';

///__________SharedPreference Keys_______________________________
const String kZeroStockRestrictionKey = 'restrict_zero_stock_transactions';
const String kSalesInvoiceEditToggleKey = 'enable_sales_invoice_edit';
const String kSalesRoundOffToggleKey = 'enable_sales_round_off';
const String kSalesBillSummaryToggleKey = 'enable_sales_bill_summary';

///_______Purchase_Code________________________________________
String purchaseCode = 'Enter your purchase code';

///---------update information---------------

const String splashLogo = 'images/BharatBill.png';
const String onboard1 = 'images/onbord1.png';
const String onboard2 = 'images/onbord2.png';
const String onboard3 = 'images/onbord3.png';
const String logo = 'images/Bharat Bill ( White  BG ) 1.png';
const String appsName = 'BharatBill';
const String companyWebsite = 'https://extraaaz.com/';
const String companyName = 'Extraaaz';

bool connected = false;

const kButtonDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(
    Radius.circular(5),
  ),
);

const kInputDecoration = InputDecoration(
  hintStyle: TextStyle(color: kGreyTextColor),
  floatingLabelBehavior: FloatingLabelBehavior.always,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    borderSide: BorderSide(color: kBorderColor, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6.0)),
    borderSide: BorderSide(color: kBorderColor, width: 1),
  ),
);

// final gTextStyle = GoogleFonts.poppins(
//   color: Colors.white,
// );

OutlineInputBorder outlineInputBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(1.0),
    borderSide: const BorderSide(color: kBorderColorTextField),
  );
}

final otpInputDecoration = InputDecoration(
  contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
  border: outlineInputBorder(),
  focusedBorder: outlineInputBorder(),
  enabledBorder: outlineInputBorder(),
);

///__________Language________________________________
Map<String, String> languageMap = {
  'English': 'en',
  'Afrikaans': 'af',
  'Amharic': 'am',
  'Arabic': 'ar',
  'Assamese': 'as',
  'Azerbaijani': 'az',
  'Belarusian': 'be',
  'Bulgarian': 'bg',
  'Bengali': 'bn',
  'Bosnian': 'bs',
  'Catalan Valencian': 'ca',
  'Czech': 'cs',
  'Welsh': 'cy',
  'Danish': 'da',
  'German': 'de',
  'Modern Greek': 'el',
  'Spanish Castilian': 'es',
  'Estonian': 'et',
  'Basque': 'eu',
  'Persian': 'fa',
  'Finnish': 'fi',
  'Filipino Pilipino': 'fil',
  'French': 'fr',
  'Galician': 'gl',
  'Swiss German Alemannic Alsatian': 'gsw',
  'Gujarati': 'gu',
  'Hebrew': 'he',
  'Hindi': 'hi',
  'Croatian': 'hr',
  'Hungarian': 'hu',
  'Armenian': 'hy',
  'Indonesian': 'id',
  'Icelandic': 'is',
  'Italian': 'it',
  'Japanese': 'ja',
  'Georgian': 'ka',
  'Kazakh': 'kk',
  'Khmer Central Khmer': 'km',
  'Kannada': 'kn',
  'Korean': 'ko',
  'Kirghiz Kyrgyz': 'ky',
  'Lao': 'lo',
  'Lithuanian': 'lt',
  'Latvian': 'lv',
  'Macedonian': 'mk',
  'Malayalam': 'ml',
  'Mongolian': 'mn',
  'Marathi': 'mr',
  'Malay': 'ms',
  'Burmese': 'my',
  'Norwegian Bokmål': 'nb',
  'Nepali': 'ne',
  'Dutch Flemish': 'nl',
  'Norwegian': 'no',
  'Oriya': 'or',
  'Panjabi Punjabi': 'pa',
  'Polish': 'pl',
  'Pushto Pashto': 'ps',
  'Portuguese': 'pt',
  'Romanian Moldavian Moldovan': 'ro',
  'Russian': 'ru',
  'Sinhala Sinhalese': 'si',
  'Slovak': 'sk',
  'Slovenian': 'sl',
  'Albanian': 'sq',
  'Serbian': 'sr',
  'Swedish': 'sv',
  'Swahili': 'sw',
  'Tamil': 'ta',
  'Telugu': 'te',
  'Thai': 'th',
  'Tagalog': 'tl',
  'Turkish': 'tr',
  'Ukrainian': 'uk',
  'Urdu': 'ur',
  'Uzbek': 'uz',
  'Vietnamese': 'vi',
  'Chinese': 'zh',
  'Hausa': 'ha',
  'Tatar': 'tt',
  'Zulu': 'zu',
};

String formatPointNumber(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  } else {
    return value.toStringAsFixed(2);
  }
}

String? selectedLanguage = languageMap['English'];

// Function to update the global selectedLanguage variable
void updateSelectedLanguage(String languageCode) {
  selectedLanguage = languageCode;
}

// Function to get localized text for printing based on selected language
String getLocalizedPrintText(String englishText) {
  if (selectedLanguage == null) return englishText;

  // Hindi translations
  if (selectedLanguage == 'hi') {
    switch (englishText) {
      case 'Seller':
        return 'विक्रेता';
      case 'Name':
        return 'नाम';
      case 'mobile':
        return 'मोबाइल';
      case 'Invoice':
        return 'चालान';
      case 'Item':
        return 'वस्तु';
      case 'Price':
        return 'कीमत';
      case 'Qty':
        return 'मात्रा';
      case 'Amount':
        return 'राशि';
      case 'Subtotal':
        return 'उप-योग';
      case 'Discount':
        return 'छूट';
      case 'VAT':
        return 'वैट';
      case 'Shipping Charge':
        return 'शिपिंग शुल्क';
      case 'Total':
        return 'कुल';
      case 'Rounding':
        return 'गोलाई';
      case 'Total Amount':
        return 'कुल राशि';
      case 'Return':
        return 'वापसी';
      case 'Returned Amount':
        return 'वापसी राशि';
      case 'Total Payable':
        return 'कुल देय';
      case 'Payment Type':
        return 'भुगतान प्रकार';
      case 'Partial Amount':
        return 'आंशिक राशि';
      case 'Due Amount':
        return 'बकाया राशि';
      case 'Change Amount':
        return 'बदलाव राशि';
      case 'Thank you!':
        return 'धन्यवाद!';
      case 'Note: Goods once sold will not be taken back or exchanged.':
        return 'नोट: एक बार बेचे गए सामान को वापस नहीं लिया जाएगा या बदला नहीं जाएगा।';
      case 'Developed By:':
        return 'विकसित:';
      case 'Tel:':
        return 'टेल:';
      case 'VAT No :':
        return 'वैट नंबर:';
      case 'Welcome back!':
        return 'वापसी पर स्वागत है!';
      case 'User':
        return 'वापरकर्ता';
      case 'Manage your business efficiently':
        return 'अपने व्यवसाय को कुशलतापूर्वक प्रबंधित करें';
      case 'Low Stock Alert':
        return 'कम स्टॉक चेतावनी';
      case 'products are running low on stock':
        return 'उत्पाद स्टॉक में कम हैं';
      case 'View':
        return 'देखें';
      case 'Quick Actions':
        return 'त्वरित क्रियाएं';
      case 'No actions available. Contact admin for access.':
        return 'कोई क्रियाएं उपलब्ध नहीं। पहुँच के लिए व्यवस्थापक से संपर्क करें।';
      case 'New Sale':
        return 'नई बिक्री';
      case 'Create a new sale transaction here':
        return 'यहाँ नई बिक्री लेन-देन बनाएँ';
      case 'New Purchase':
        return 'नई खरीद';
      case 'Create a new purchase transaction here':
        return 'यहाँ नई खरीद लेन-देन बनाएँ';
      case 'Add Customer/Supplier':
        return 'ग्राहक/आपूर्तिकर्ता जोड़ें';
      case 'Add new customer or supplier here':
        return 'यहाँ नया ग्राहक या आपूर्तिकर्ता जोड़ें';
      case 'Add Product':
        return 'उत्पाद जोड़ें';
      case 'Add a new product to your inventory':
        return 'अपने इन्वेंट्री में नया उत्पाद जोड़ें';
      case 'Dashboard':
        return 'डैशबोर्ड';
      case 'View your business dashboard and analytics':
        return 'अपने व्यवसाय का डैशबोर्ड और विश्लेषण देखें';
      case 'Reports':
        return 'रिपोर्ट्स';
      case 'View detailed business reports':
        return 'विस्तृत व्यवसाय रिपोर्ट देखें';
      case 'Subscribe Now':
        return 'अभी सदस्यता लें';
      case 'Days Left':
        return 'दिन शेष';
      case 'Guest':
        return 'अतिथि';
      case 'Not Provided':
        return 'उपलब्ध नहीं';
      case 'N/A':
        return 'उपलब्ध नहीं';
      case 'Admin':
        return 'प्रशासक';
      case 'Service Charge':
        return 'सेवा शुल्क';
      case 'Split':
        return 'विभाजित';
      case 'Scan to Pay via UPI':
        return 'UPI से भुगतान करने के लिए स्कैन करें';
      case 'RS':
        return '₹';
      default:
        return englishText;
    }
  }

  // Marathi translations
  if (selectedLanguage == 'mr') {
    switch (englishText) {
      case 'Seller':
        return 'विक्रेता';
      case 'Name':
        return 'नाव';
      case 'mobile':
        return 'मोबाइल';
      case 'Invoice':
        return 'चालान';
      case 'Item':
        return 'वस्तू';
      case 'Price':
        return 'किंमत';
      case 'Qty':
        return 'प्रमाण';
      case 'Amount':
        return 'रक्कम';
      case 'Subtotal':
        return 'उप-योग';
      case 'Discount':
        return 'सवलत';
      case 'VAT':
        return 'व्हॅट';
      case 'Shipping Charge':
        return 'शिपिंग शुल्क';
      case 'Total':
        return 'एकूण';
      case 'Rounding':
        return 'गोलाई';
      case 'Total Amount':
        return 'एकूण रक्कम';
      case 'Return':
        return 'परतावा';
      case 'Returned Amount':
        return 'परतावा रक्कम';
      case 'Total Payable':
        return 'एकूण देय';
      case 'Payment Type':
        return 'पेमेंट प्रकार';
      case 'Received Amount':
        return 'मिळालेली रक्कम';
      case 'Due Amount':
        return 'बाकी रक्कम';
      case 'Change Amount':
        return 'बदल रक्कम';
      case 'Thank you!':
        return 'धन्यवाद!';
      case 'Note: Goods once sold will not be taken back or exchanged.':
        return 'नोट: एकदा विकलेली वस्तू परत घेतली जाणार नाही किंवा बदलली जाणार नाही.';
      case 'Developed By:':
        return 'विकसित:';
      case 'Tel:':
        return 'टेल:';
      case 'VAT No :':
        return 'व्हॅट नंबर:';
      case 'Welcome back!':
        return 'परत स्वागत आहे!';
      case 'User':
        return 'वापरकर्ता';
      case 'Manage your business efficiently':
        return 'आपला व्यवसाय कार्यक्षमतेने व्यवस्थापित करा';
      case 'Low Stock Alert':
        return 'कमी स्टॉक सूचना';
      case 'products are running low on stock':
        return 'उत्पादांचा स्टॉक कमी होत आहे';
      case 'View':
        return 'पाहा';
      case 'Quick Actions':
        return 'जलद क्रिया';
      case 'No actions available. Contact admin for access.':
        return 'कोणत्याही क्रिया उपलब्ध नाहीत. प्रवेशासाठी प्रशासकाशी संपर्क साधा.';
      case 'New Sale':
        return 'नवीन विक्री';
      case 'Create a new sale transaction here':
        return 'येथे नवीन विक्री व्यवहार तयार करा';
      case 'New Purchase':
        return 'नवीन खरेदी';
      case 'Create a new purchase transaction here':
        return 'येथे नवीन खरेदी व्यवहार तयार करा';
      case 'Add Customer/Supplier':
        return 'ग्राहक/पुरवठादार जोडा';
      case 'Add new customer or supplier here':
        return 'येथे नवीन ग्राहक किंवा पुरवठादार जोडा';
      case 'Add Product':
        return 'उत्पाद जोडा';
      case 'Add a new product to your inventory':
        return 'आपल्या साठ्यात नवीन उत्पाद जोडा';
      case 'Dashboard':
        return 'डॅशबोर्ड';
      case 'View your business dashboard and analytics':
        return 'आपला व्यवसाय डॅशबोर्ड आणि विश्लेषण पाहा';
      case 'Reports':
        return 'अहवाल';
      case 'View detailed business reports':
        return 'सविस्तर व्यवसाय अहवाल पाहा';
      case 'Subscribe Now':
        return 'आता सदस्य व्हा';
      case 'Days Left':
        return 'उर्वरित दिवस';
      case 'Guest':
        return 'पाहुणा';
      case 'Not Provided':
        return 'उपलब्ध नाही';
      case 'N/A':
        return 'उपलब्ध नाही';
      case 'Admin':
        return 'प्रशासक';
      case 'Service Charge':
        return 'सेवा शुल्क';
      case 'Split':
        return 'विभाजित';
      case 'Scan to Pay via UPI':
        return 'UPI द्वारे पेमेंट करण्यासाठी स्कॅन करा';
      case 'RS':
        return '₹';
      default:
        return englishText;
    }
  }

  // Return English text for other languages
  return englishText;
}

// Function to get translated text for printing (Hindi/Marathi only, no English)
// When Hindi or Marathi is selected, returns only the translated text
String getBilingualPrintText(String englishText) {
  if (selectedLanguage == null ||
      (selectedLanguage != 'hi' && selectedLanguage != 'mr')) {
    // If not Hindi or Marathi, return only English
    return englishText;
  }

  // Get the translated text
  String translatedText = getLocalizedPrintText(englishText);

  // If translation is same as English (no translation found), return only English
  if (translatedText == englishText) {
    return englishText;
  }

  // Return only translated text (Hindi/Marathi), no English, no separator
  return translatedText;
}

//withValues extension on color with a required value alpha
extension ColorExt on Color {
  Color withValues({required double alpha}) {
    return Color.fromARGB((alpha * 255).toInt(), red, green, blue);
  }
}

pw.Widget getLocalizedPdfText(String text, pw.TextStyle textStyle,
    {pw.TextAlign? textAlignment}) {
  print('Current Language: $selectedLanguage, Text: $text');
  return pw.Text(
    selectedLanguage == "bn" ? unicodeToBijoy(text) : text,
    textAlign: textAlignment,
    style: textStyle,
  );
}

pw.Widget getLocalizedPdfTextWithLanguage(String text, pw.TextStyle textStyle,
    {pw.TextAlign? textAlignment}) {
  print('Current Language: $selectedLanguage, Text: $text');
  String detectedLanguage = detectLanguageEnhanced(text);
  return pw.Text(
    detectedLanguage == "bn" ? unicodeToBijoy(text) : text,
    textAlign: textAlignment,
    style: textStyle,
  );
}

String detectLanguageEnhanced(String text, {double threshold = 0.7}) {
  final cleanedText = text.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
  if (cleanedText.isEmpty) return 'en';

  // Count matches for each script
  final Map<String, int> counts = {
    'bn': RegExp(r'[\u0980-\u09FF]').allMatches(cleanedText).length,
    'hi': RegExp(r'[\u0900-\u097F]').allMatches(cleanedText).length,
    'mr': RegExp(r'[\u0900-\u097F]')
        .allMatches(cleanedText)
        .length, // Marathi uses Devanagari script
    'ar': RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]')
        .allMatches(cleanedText)
        .length,
    'fr': RegExp(r'[a-zA-Zéèêëàâîïôùûç]').allMatches(cleanedText).length,
  };

  // Calculate ratios
  final total = cleanedText.length;
  final ratios = counts.map((lang, count) => MapEntry(lang, count / total));

  // Determine dominant language
  for (final entry in ratios.entries) {
    if (entry.value >= threshold) return entry.key;
  }

  return 'en';
}
