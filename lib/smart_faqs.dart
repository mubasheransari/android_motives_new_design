// lib/features/smart_faq/smart_faq_chat_bilingual.dart
//
// Bilingual (English/Urdu) Smart FAQ chat — offline, no AI calls.
// - Language toggle (EN / اردو) with full UI + content switching
// - Separate chat history per language (GetStorage)
// - RTL layout when Urdu selected
// - Suggestion chips, fuzzy search, synonyms (both languages)
// - Thumbs up/down feedback stored locally
//
// Requirements in pubspec.yaml:
//   get_storage: ^2.1.1
//
// Initialize GetStorage once in main():
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await GetStorage.init();
//     runApp(const MyApp());
//   }
//
// Usage:
//   Navigator.push(context,
//     MaterialPageRoute(builder: (_) => const SmartFaqChatBilingual()),
//   );

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

// ---------- THEME ----------
const _kBg = Color(0xFFF7F8FA);
const _kCard = Colors.white;
const _kText = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6C7580);
const _kAccent = Color(0xFFEA7A3B);
const _kAccentLite = Color(0xFFFFB07A);

// ---------- LANG ----------
enum FaqLang { en, ur }

extension FaqLangX on FaqLang {
  String get code => this == FaqLang.en ? 'en' : 'ur';
  TextDirection get dir => this == FaqLang.ur ? TextDirection.rtl : TextDirection.ltr;
}

// ---------- MODELS ----------
enum ChatRole { user, bot }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime ts;
  final List<String> suggestions;
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.ts,
    this.suggestions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'ts': ts.toIso8601String(),
        'sug': suggestions,
      };

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: j['role'] == 'user' ? ChatRole.user : ChatRole.bot,
        text: (j['text'] ?? '').toString(),
        ts: DateTime.tryParse((j['ts'] ?? '').toString()) ?? DateTime.now(),
        suggestions: (j['sug'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class FaqItem {
  final String id;

  // EN
  final String categoryEn;
  final String questionEn;
  final String answerEn;
  final List<String> tagsEn;

  // UR
  final String categoryUr;
  final String questionUr;
  final String answerUr;
  final List<String> tagsUr;

  const FaqItem({
    required this.id,
    required this.categoryEn,
    required this.questionEn,
    required this.answerEn,
    required this.tagsEn,
    required this.categoryUr,
    required this.questionUr,
    required this.answerUr,
    required this.tagsUr,
  });

  String category(FaqLang l) => l == FaqLang.en ? categoryEn : categoryUr;
  String question(FaqLang l) => l == FaqLang.en ? questionEn : questionUr;
  String answer(FaqLang l) => l == FaqLang.en ? answerEn : answerUr;
  List<String> tags(FaqLang l) => l == FaqLang.en ? tagsEn : tagsUr;
}

// ---------- DATA ----------
const _faqs = <FaqItem>[
  // Orders
  FaqItem(
    id: 'orders_01',
    categoryEn: 'Orders',
    questionEn: 'How do I place an order?',
    answerEn:
        'Open “Products”, add items, then go to “My List” and press “Confirm & Send”. You’ll see a success toast and the order will appear in Records.',
    tagsEn: ['order', 'place', 'buy', 'cart', 'bag', 'confirm', 'send'],
    categoryUr: 'آرڈرز',
    questionUr: 'آرڈر کیسے کریں؟',
    answerUr:
        '“Products” کھولیں، آئٹمز شامل کریں، پھر “My List” میں جا کر “Confirm & Send” دبائیں۔ کامیابی کا پیغام آئے گا اور آرڈر “Records” میں نظر آئے گا۔',
    tagsUr: ['آرڈر', 'خرید', 'کارٹ', 'بیگ', 'کنفرم', 'سینڈ', 'جمع'],
  ),
  FaqItem(
    id: 'orders_02',
    categoryEn: 'Orders',
    questionEn: 'Can I edit quantities before submitting?',
    answerEn:
        'Yes. In “My List” use the +/– controls to adjust quantities before pressing “Confirm & Send”.',
    tagsEn: ['qty', 'quantity', 'change', 'update', 'edit', 'cart'],
    categoryUr: 'آرڈرز',
    questionUr: 'کیا میں سبمٹ کرنے سے پہلے مقدار تبدیل کر سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ “My List” میں ہر لائن پر +/– سے مقدار تبدیل کریں، پھر “Confirm & Send” دبائیں۔',
    tagsUr: ['مقدار', 'تبدیل', 'ایڈٹ', 'کارٹ'],
  ),
  FaqItem(
    id: 'orders_03',
    categoryEn: 'Orders',
    questionEn: 'Where can I see my previous orders?',
    answerEn:
        'Open the “Records” screen from the menu. Latest orders appear at the top with status and time.',
    tagsEn: ['history', 'records', 'previous', 'past', 'orders', 'status'],
    categoryUr: 'آرڈرز',
    questionUr: 'پرانے آرڈرز کہاں دیکھ سکتا/سکتی ہوں؟',
    answerUr:
        'مینیو سے “Records” کھولیں۔ تازہ ترین آرڈرز اوپر سٹیٹس اور وقت کے ساتھ نظر آئیں گے۔',
    tagsUr: ['ریکارڈز', 'ہسٹری', 'پرانے', 'آرڈر', 'سٹیٹس'],
  ),
  FaqItem(
    id: 'orders_04',
    categoryEn: 'Orders',
    questionEn: 'Why did my order fail to submit?',
    answerEn:
        'Common causes: no network, missing user/distributor, or server maintenance. Check internet and retry. If it persists, contact support.',
    tagsEn: ['error', 'fail', 'submit', 'network', 'server'],
    categoryUr: 'آرڈرز',
    questionUr: 'میرا آرڈر سبمٹ کیوں نہیں ہوا؟',
    answerUr:
        'عام وجوہات: انٹرنیٹ نہیں، یوزر/ڈسٹری بیوٹر کی معلومات نہیں، یا سرور مینٹیننس۔ نیٹ چیک کریں اور دوبارہ کوشش کریں۔ مسئلہ برقرار رہے تو سپورٹ سے رابطہ کریں۔',
    tagsUr: ['خرابی', 'ناکام', 'نیٹ ورک', 'سرور', 'سبمٹ'],
  ),

  // Route
  FaqItem(
    id: 'route_01',
    categoryEn: 'Route',
    questionEn: 'How do I check in at a shop?',
    answerEn:
        'From “Order Menu” tap “Check In”. If location is required, allow location services. You must check in to take orders or mark reasons.',
    tagsEn: ['check-in', 'shop', 'visit', 'location', 'gps', 'route'],
    categoryUr: 'روٹ',
    questionUr: 'دکان پر چیک اِن کیسے کروں؟',
    answerUr:
        '“Order Menu” میں “Check In” دبائیں۔ اگر لوکیشن درکار ہو تو اجازت دیں۔ آرڈر لینے یا وجوہات مارک کرنے کے لیے چیک اِن ضروری ہے۔',
    tagsUr: ['چیک اِن', 'دکان', 'وزٹ', 'لوکیشن', 'جی پی ایس', 'روٹ'],
  ),
  FaqItem(
    id: 'route_02',
    categoryEn: 'Route',
    questionEn: 'I need to check out — what should I do?',
    answerEn:
        'From “Order Menu” tap “Check Out”. If a reason is required, select HOLD or NO VISIT before checking out.',
    tagsEn: ['check-out', 'reason', 'hold', 'no visit', 'route'],
    categoryUr: 'روٹ',
    questionUr: 'مجھے چیک آؤٹ کرنا ہے — کیا کروں؟',
    answerUr:
        '“Order Menu” میں “Check Out” دبائیں۔ اگر وجہ درکار ہو تو چیک آؤٹ سے پہلے HOLD یا NO VISIT منتخب کریں۔',
    tagsUr: ['چیک آؤٹ', 'وجہ', 'ہولڈ', 'نو وزٹ', 'روٹ'],
  ),
  FaqItem(
    id: 'route_03',
    categoryEn: 'Route',
    questionEn: 'What is “Order Done” on Journey Plan?',
    answerEn:
        'After a successful order, the app marks that shop as “Order Done”, checks you out locally, and increments covered routes.',
    tagsEn: ['order done', 'journey plan', 'covered routes', 'label'],
    categoryUr: 'روٹ',
    questionUr: 'جرنی پلان میں “آرڈر ڈن” کیا ہے؟',
    answerUr:
        'کامیاب آرڈر کے بعد وہ شاپ “Order Done” سے نشان زد ہوتی ہے، مقامی طور پر چیک آؤٹ ہو جاتا ہے، اور کورڈ روٹس کی گنتی بڑھتی ہے۔',
    tagsUr: ['آرڈر ڈن', 'جرنی پلان', 'کورڈ روٹس', 'لیبل'],
  ),

  // Payments
  FaqItem(
    id: 'pay_01',
    categoryEn: 'Payments',
    questionEn: 'How do I pay for an order?',
    answerEn:
        'Orders are submitted to your distributor — payments follow business rules. If “Collect Payment” is enabled, open it from Order Menu.',
    tagsEn: ['payment', 'pay', 'invoice', 'collect'],
    categoryUr: 'ادائیگیاں',
    questionUr: 'آرڈر کی ادائیگی کیسے کروں؟',
    answerUr:
        'آرڈر ڈسٹری بیوٹر کو جاتا ہے — ادائیگی آپ کے بزنس رولز کے مطابق ہوتی ہے۔ اگر “Collect Payment” فعال ہو تو وہ “Order Menu” سے کھولیں۔',
    tagsUr: ['ادائیگی', 'ان وائس', 'کلیکٹ', 'پیمنٹ'],
  ),
  FaqItem(
    id: 'pay_02',
    categoryEn: 'Payments',
    questionEn: 'Payment screen says not allowed.',
    answerEn:
        'You may not have invoice rights. Ask your admin to enable “markInvoices”.',
    tagsEn: ['not allowed', 'rights', 'invoices', 'permission'],
    categoryUr: 'ادائیگیاں',
    questionUr: 'پیمنٹ اسکرین میں “اجازت نہیں” آ رہا ہے۔',
    answerUr:
        'ممکن ہے آپ کے پاس ان وائس کی اجازت نہیں۔ ایڈمن سے “markInvoices” فعال کرنے کا کہیں۔',
    tagsUr: ['اجازت', 'رائٹس', 'ان وائس', 'پرمیژن'],
  ),

  // App
  FaqItem(
    id: 'app_01',
    categoryEn: 'App',
    questionEn: 'How do I reset my password?',
    answerEn:
        'Go to “Profile → Change Password”. Enter new and confirm passwords to update.',
    tagsEn: ['password', 'reset', 'change', 'forgot'],
    categoryUr: 'ایپ',
    questionUr: 'پاس ورڈ ری سیٹ کیسے کروں؟',
    answerUr:
        '“Profile → Change Password” پر جائیں۔ نیا اور کنفرم پاس ورڈ درج کر کے اپڈیٹ کریں۔',
    tagsUr: ['پاس ورڈ', 'ری سیٹ', 'تبدیلی', 'بھول گیا'],
  ),
  FaqItem(
    id: 'app_02',
    categoryEn: 'App',
    questionEn: 'The app isn’t syncing my actions.',
    answerEn:
        'If you’re offline, actions queue and sync when online. Keep the app open for a few seconds after internet returns.',
    tagsEn: ['offline', 'sync', 'queue', 'online'],
    categoryUr: 'ایپ',
    questionUr: 'ایپ میری کارروائیاں سنک نہیں کر رہی۔',
    answerUr:
        'آف لائن ہونے پر ایکشن قطار میں لگتے ہیں اور آن لائن ہوتے ہی سنک ہو جاتے ہیں۔ انٹرنیٹ آنے کے بعد کچھ سیکنڈ ایپ کھلی رکھیں۔',
    tagsUr: ['آف لائن', 'سنک', 'قطار', 'آن لائن'],
  ),
];

// ---------- SYNONYMS ----------
const Map<String, List<String>> _synEn = {
  'buy': ['purchase', 'order', 'checkout', 'confirm', 'send'],
  'order': ['buy', 'purchase', 'cart', 'bag', 'list'],
  'cart': ['bag', 'basket', 'list'],
  'records': ['history', 'previous', 'past'],
  'payment': ['pay', 'invoice', 'collect'],
  'checkin': ['check in', 'check-in', 'visit'],
  'checkout': ['check out', 'check-out', 'leave'],
  'gps': ['location', 'map', 'blue dot'],
  'error': ['fail', 'failure', 'issue', 'problem'],
};

const Map<String, List<String>> _synUr = {
  'آرڈر': ['خرید', 'آرڈر', 'سبمٹ', 'کنفرم', 'سینڈ', 'کارٹ', 'بیگ', 'فہرست'],
  'کارٹ': ['بیگ', 'فہرست'],
  'ریکارڈز': ['ہسٹری', 'پرانے آرڈر'],
  'ادائیگی': ['پیمنٹ', 'بل', 'ان وائس', 'کلیکٹ'],
  'چیک اِن': ['چیک ان', 'حاضری', 'وزٹ شروع'],
  'چیک آؤٹ': ['چیک اوٹ', 'نکلنا', 'وزٹ ختم'],
  'لوکیشن': ['جی پی ایس', 'نقشہ', 'بلیو ڈاٹ'],
  'خرابی': ['مسئلہ', 'ناکامی'],
  'ہولڈ': ['وقفہ', 'عارضی روک'],
  'نو وزٹ': ['کوئی وزٹ نہیں', 'وزٹ نہیں'],
};

// ---------- PREFS / STORE ----------
class FaqPrefs {
  final _box = GetStorage();
  FaqLang getLang() {
    final s = (_box.read('smartfaq_lang') as String?) ?? 'en';
    return s == 'ur' ? FaqLang.ur : FaqLang.en;
  }

  Future<void> setLang(FaqLang l) => _box.write('smartfaq_lang', l.code);
}

class FaqStore {
  static final FaqStore _i = FaqStore._();
  FaqStore._();
  factory FaqStore() => _i;

  final _box = GetStorage();

  String _histKey(FaqLang l) => 'smartfaq_history_${l.code}';
  String get _fbKey => 'smartfaq_feedback';

  // feedback: map<faqId, {up:int, down:int}>
  Map<String, dynamic> _fb() =>
      _box.read(_fbKey) as Map<String, dynamic>? ?? {};

  void thumbUp(String id) {
    final fb = Map<String, dynamic>.from(_fb());
    final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
    rec['up'] = (rec['up'] ?? 0) + 1;
    fb[id] = rec;
    _box.write(_fbKey, fb);
  }

  void thumbDown(String id) {
    final fb = Map<String, dynamic>.from(_fb());
    final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
    rec['down'] = (rec['down'] ?? 0) + 1;
    fb[id] = rec;
    _box.write(_fbKey, fb);
  }

  List<ChatMessage> loadHistory(FaqLang lang) {
    final raw = _box.read(_histKey(lang)) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ChatMessage.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHistory(FaqLang lang, List<ChatMessage> msgs) async {
    final payload = jsonEncode(msgs.map((e) => e.toJson()).toList());
    await _box.write(_histKey(lang), payload);
  }

  Future<void> clearHistory(FaqLang lang) => _box.remove(_histKey(lang));
}

// ---------- ENGINE ----------
class FaqEngine {
  final List<FaqItem> data;
  FaqLang _lang;
  final Map<String, int> _df = {}; // document frequency
  late int _n;

  FaqEngine(this.data, this._lang) {
    _rebuild();
  }

  void setLang(FaqLang l) {
    if (_lang == l) return;
    _lang = l;
    _rebuild();
  }

  void _rebuild() {
    _df.clear();
    _n = data.length;
    for (final f in data) {
      final terms = _terms(f.question(_lang)).toSet();
      for (final t in terms) {
        _df[t] = (_df[t] ?? 0) + 1;
      }
      for (final tag in f.tags(_lang)) {
        final t = _norm(tag);
        _df[t] = (_df[t] ?? 0) + 1;
      }
    }
  }

  String _norm(String s) {
    // Keep EN word chars, digits, spaces AND Urdu range U+0600..U+06FF
    final cleaned = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  List<String> _terms(String s) =>
      _norm(s).split(' ').where((e) => e.isNotEmpty).toList();

  List<String> _expandSynonyms(List<String> tokens) {
    final out = <String>[];
    final map = _lang == FaqLang.en ? _synEn : _synUr;
    for (final t in tokens) {
      out.add(t);
      map.forEach((k, vals) {
        if (t == k || vals.contains(t)) {
          out.add(k);
          out.addAll(vals);
        }
      });
    }
    return out.toSet().toList();
  }

  double _idf(String term) {
    final df = _df[term] ?? 1;
    return log((_n + 1) / df);
  }

  int _lev(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) m[i][0] = i;
    for (var j = 0; j <= b.length; j++) m[0][j] = j;
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        m[i][j] = [
          m[i - 1][j] + 1,
          m[i][j - 1] + 1,
          m[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    return m[a.length][b.length];
  }

  double _fuzzySim(String q, String s) {
    final a = _norm(q);
    final b = _norm(s);
    if (a.isEmpty || b.isEmpty) return 0;
    final d = _lev(a, b).toDouble();
    final mx = max(a.length, b.length).toDouble();
    return 1.0 - (d / mx);
  }

  double _score(String query, FaqItem f) {
    final qTokens = _expandSynonyms(_terms(query));
    final qSet = qTokens.toSet();

    final titleTokens = _terms(f.question(_lang));
    final titleSet = titleTokens.toSet();

    final tagsSet = f.tags(_lang).map(_norm).toSet();

    double overlap = 0;
    for (final t in qSet) {
      if (titleSet.contains(t) || tagsSet.contains(t)) {
        overlap += _idf(t);
      }
    }

    final fuzzy = _fuzzySim(query, f.question(_lang));
    final tagBoost = qSet.intersection(tagsSet).isNotEmpty ? 1.0 : 0.0;

    return 0.6 * overlap + 0.25 * fuzzy + 0.15 * tagBoost;
  }

  List<FaqItem> find(String query, {int topK = 4}) {
    if (query.trim().isEmpty) return const <FaqItem>[];
    final scored = <(FaqItem, double)>[];
    for (final f in data) {
      final s = _score(query, f);
      if (s > 0) scored.add((f, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(topK).map((e) => e.$1).toList();
  }

  List<String> suggestionsFor(FaqItem picked, {int max = 5}) {
    final sameCat = data
        .where((e) => e.category(_lang) == picked.category(_lang) && e.id != picked.id)
        .toList();
    return sameCat.take(max).map((e) => e.question(_lang)).toList();
  }

  List<String> starterSuggestions({int max = 8}) {
    final qs = data.map((e) => e.question(_lang)).toSet().toList();
    qs.shuffle(Random());
    return qs.take(max).toList();
  }

  List<String> categories() {
    final s = data.map((e) => e.category(_lang)).toSet().toList();
    s.sort();
    return s;
  }

  List<String> questionsInCategory(String cat, {int max = 10}) =>
      data.where((e) => e.category(_lang) == cat).map((e) => e.question(_lang)).take(max).toList();

  FaqLang get lang => _lang;
}

// ---------- LOCALIZATION STRINGS ----------
class L10n {
  final FaqLang lang;
  const L10n(this.lang);

  String get appTitle => lang == FaqLang.en ? 'Smart FAQs' : 'سمارٹ سوالات';
  String get clearChat => lang == FaqLang.en ? 'Clear chat' : 'چیٹ صاف کریں';
  String get askHint => lang == FaqLang.en
      ? 'Ask a question (e.g., “How do I place an order?”)'
      : 'سوال پوچھیں (مثلاً: “آرڈر کیسے کریں؟”)';
  String get ask => lang == FaqLang.en ? 'Ask' : 'پوچھیں';
  String get welcome =>
      lang == FaqLang.en
          ? 'Hi! Ask me anything about Orders, Route, or Payments. Tap a suggestion below to start.'
          : 'سلام! آرڈرز، روٹ یا ادائیگی سے متعلق کچھ بھی پوچھیں۔ شروع کرنے کیلئے نیچے سے کوئی سجیشن چنیں۔';
  String get thanks => lang == FaqLang.en ? 'Thanks for the feedback!' : 'فیڈبیک کا شکریہ!';
  String get noted => lang == FaqLang.en ? 'Noted. We’ll improve these answers.' : 'موصول ہوا۔ ہم ان جوابات کو بہتر بنائیں گے۔';
  String get copied => lang == FaqLang.en ? 'Answer copied to clipboard' : 'جواب کاپی ہو گیا';
  String get couldntFind =>
      lang == FaqLang.en
          ? "I couldn't find an exact answer, but try these or rephrase your question:"
          : 'ٹھیک جواب نہیں ملا، یہ آزمائیں یا سوال تھوڑا بدل دیں:';
  String get en => 'EN';
  String get ur => 'اردو';
}

// ---------- SCREEN ----------
class SmartFaqChatBilingual extends StatefulWidget {
  const SmartFaqChatBilingual({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  State<SmartFaqChatBilingual> createState() => _SmartFaqChatBilingualState();
}

class _SmartFaqChatBilingualState extends State<SmartFaqChatBilingual> {
  final _store = FaqStore();
  final _prefs = FaqPrefs();
  final _ctl = TextEditingController();
  final _scroll = ScrollController();

  late FaqEngine _engine;
  late FaqLang _lang;
  late L10n _t;

  List<ChatMessage> _messages = [];
  bool _typing = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    widget.onOpen?.call();
    _lang = _prefs.getLang();
    _t = L10n(_lang);
    _engine = FaqEngine(_faqs, _lang);
    _messages = _store.loadHistory(_lang);
    if (_messages.isEmpty) _seedWelcome();
  }

  void _seedWelcome() {
    final starters = _engine.starterSuggestions();
    _messages = [
      ChatMessage(
        id: 'm0',
        role: ChatRole.bot,
        text: _t.welcome,
        ts: DateTime.now(),
        suggestions: starters,
      )
    ];
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save() => _store.saveHistory(_lang, _messages);

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSend(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: 'u${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.user,
        text: text,
        ts: DateTime.now(),
      ));
      _typing = true;
    });
    _ctl.clear();
    _jumpToBottom();

    await Future.delayed(const Duration(milliseconds: 350));

    final hits = _engine.find(text, topK: 4);
    ChatMessage reply;

    if (hits.isEmpty) {
      final alts = _engine.starterSuggestions();
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text: _t.couldntFind,
        ts: DateTime.now(),
        suggestions: alts.take(6).toList(),
      );
    } else {
      final top = hits.first;
      final related = _engine.suggestionsFor(top, max: 5);
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text: top.answer(_lang),
        ts: DateTime.now(),
        suggestions: related,
      );
    }

    setState(() {
      _messages.add(reply);
      _typing = false;
    });
    _jumpToBottom();
    await _save();
  }

  Future<void> _onTapSuggestion(String q) async {
    _ctl.text = q;
    await _onSend(q);
  }

  void _onThumbUp(ChatMessage botMsg) {
    final item = _faqs.firstWhere(
      (f) => f.answer(_lang) == botMsg.text,
      orElse: () => const FaqItem(
        id: 'unknown',
        categoryEn: '',
        questionEn: '',
        answerEn: '',
        tagsEn: [],
        categoryUr: '',
        questionUr: '',
        answerUr: '',
        tagsUr: [],
      ),
    );
    if (item.id != 'unknown') _store.thumbUp(item.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.thanks)));
  }

  void _onThumbDown(ChatMessage botMsg) {
    final item = _faqs.firstWhere(
      (f) => f.answer(_lang) == botMsg.text,
      orElse: () => const FaqItem(
        id: 'unknown',
        categoryEn: '',
        questionEn: '',
        answerEn: '',
        tagsEn: [],
        categoryUr: '',
        questionUr: '',
        answerUr: '',
        tagsUr: [],
      ),
    );
    if (item.id != 'unknown') _store.thumbDown(item.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.noted)));
  }

  Future<void> _clearHistory() async {
    await _store.clearHistory(_lang);
    setState(() => _seedWelcome());
  }

  Future<void> _switchLang(FaqLang lang) async {
    if (_lang == lang) return;
    setState(() {
      _lang = lang;
      _t = L10n(_lang);
      _engine.setLang(_lang);
      _selectedCategory = null;
      _messages = _store.loadHistory(_lang);
      if (_messages.isEmpty) _seedWelcome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cats = _engine.categories();
    final catSuggestions = _selectedCategory == null
        ? _engine.starterSuggestions()
        : _engine.questionsInCategory(_selectedCategory!);

    return Directionality(
      textDirection: _lang.dir,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kCard,
          elevation: 0,
          title: Text(
            _t.appTitle,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
          ),
          actions: [
            _LangToggle(
              lang: _lang,
              onChanged: _switchLang,
              t: _t,
            ),
            IconButton(
              tooltip: _t.clearChat,
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline, color: _kMuted),
            ),
          ],
        ),
        body: Column(
          children: [
            // Category filter + suggestion chips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              color: _kCard,
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: _lang == FaqLang.ur, // better RTL experience
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final label = (i == 0)
                            ? (_lang == FaqLang.en ? 'All' : 'تمام')
                            : cats[i - 1];
                        final sel = (i == 0 && _selectedCategory == null) ||
                            (i > 0 && _selectedCategory == label);
                        return ChoiceChip(
                          label: Text(label, overflow: TextOverflow.ellipsis),
                          selected: sel,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory =
                                  (i == 0) ? null : label;
                            });
                          },
                          selectedColor: _kAccent,
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : _kText,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: sel ? Colors.transparent : const Color(0xFFEDEFF2),
                            ),
                          ),
                          elevation: sel ? 1 : 0,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: _lang == FaqLang.ur,
                      itemCount: catSuggestions.length.clamp(0, 12),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final q = catSuggestions[i];
                        return ActionChip(
                          label: Text(q, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => _onTapSuggestion(q),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFEDEFF2)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Chat list
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                reverse: false,
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_typing && i == _messages.length) {
                    return const _TypingBubble();
                  }
                  final m = _messages[i];
                  final isUser = m.role == ChatRole.user;
                  return Column(
                    crossAxisAlignment:
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: _ChatBubble(
                          isUser: isUser,
                          text: m.text,
                          onCopy: () => Clipboard.setData(ClipboardData(text: m.text)),
                          onShare: () => _share(context, m.text),
                          onThumbUp: isUser ? null : () => _onThumbUp(m),
                          onThumbDown: isUser ? null : () => _onThumbDown(m),
                          textDirection: _lang.dir,
                        ),
                      ),
                      if (!isUser && m.suggestions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: _lang == FaqLang.ur ? WrapAlignment.end : WrapAlignment.start,
                          children: m.suggestions.take(6).map((s) {
                            return ActionChip(
                              label: Text(
                                s,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () => _onTapSuggestion(s),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFEDEFF2)),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),

            // Composer
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: _kCard,
                boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFEDEFF2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _ctl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _onSend,
                        textDirection: _lang.dir,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _t.askHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () => _onSend(_ctl.text),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(_t.ask),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.copied)));
  }
}

// ---------- LANG TOGGLE WIDGET ----------
class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.lang, required this.onChanged, required this.t});
  final FaqLang lang;
  final ValueChanged<FaqLang> onChanged;
  final L10n t;

  @override
  Widget build(BuildContext context) {
    final selEn = lang == FaqLang.en;
    final selUr = lang == FaqLang.ur;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEDEFF2)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _segBtn(label: t.en, selected: selEn, onTap: () => onChanged(FaqLang.en)),
        _segBtn(label: t.ur, selected: selUr, onTap: () => onChanged(FaqLang.ur)),
      ]),
    );
  }

  Widget _segBtn({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _kText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------- BUBBLES ----------
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.isUser,
    required this.text,
    this.onCopy,
    this.onShare,
    this.onThumbUp,
    this.onThumbDown,
    required this.textDirection,
  });

  final bool isUser;
  final String text;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onThumbUp;
  final VoidCallback? onThumbDown;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? _kAccent : _kCard;
    final textColor = isUser ? Colors.white : _kText;

    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isUser ? 14 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 14),
        ),
        border: isUser ? null : Border.all(color: const Color(0xFFEDEFF2)),
        boxShadow: isUser
            ? const []
            : const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.28)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCopy != null)
                  _MiniIconButton(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy!),
                if (onShare != null) const SizedBox(width: 6),
                if (onShare != null)
                  _MiniIconButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare!),
                if (onThumbUp != null || onThumbDown != null) const SizedBox(width: 6),
                if (onThumbUp != null)
                  _MiniIconButton(icon: Icons.thumb_up_outlined, label: 'Helpful', onTap: onThumbUp!),
                if (onThumbDown != null) const SizedBox(width: 6),
                if (onThumbDown != null)
                  _MiniIconButton(icon: Icons.thumb_down_outlined, label: 'Not helpful', onTap: onThumbDown!),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).textTheme.bodySmall?.copyWith(color: _kMuted);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: _kMuted),
          const SizedBox(width: 4),
          Text(label, style: c),
        ]),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEDEFF2)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const _Dots(),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final v = (sin(_ctl.value * 2 * pi) + 1) / 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final s = 6.0 + (i == 0 ? v : i == 1 ? (1 - v) : v) * 3;
            return Container(
              width: s,
              height: s,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(color: _kMuted, shape: BoxShape.circle),
            );
          }),
        );
      },
    );
  }
}
