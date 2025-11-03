import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';


// smart_faq_chat_bilingual.dart
// Full, self-contained Smart FAQs (EN/UR) with relational categories + new functional scope

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'widgets/watermark_widget.dart'; // make sure this exists in your project

// ---------- THEME ----------
const _kBg = Color(0xFFF7F8FA);
const _kCard = Colors.white;
const _kText = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6C7580);
const _kAccent = Color(0xFFEA7A3B);

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

// ---------- DATA (domain Q&As) ----------
const _faqs = <FaqItem>[
  // ===== EXISTING: Offline / Auto Sync / Status =====
  FaqItem(
    id: 'offline_after_attendance',
    categoryEn: 'App',
    questionEn: 'After marking attendance, can I work in offline mode?',
    answerEn:
        'Yes. Once your attendance is marked, you can continue your journey in either online or offline mode. Any orders, check-ins, reasons, or holds done while offline are kept in a local queue and are synced automatically when the internet comes back — no manual Sync In/Out is required.',
    tagsEn: ['offline', 'online', 'attendance', 'auto sync', 'queue', 'sync in', 'sync out'],
    categoryUr: 'ایپ',
    questionUr: 'حاضری لگانے کے بعد کیا میں آف لائن موڈ میں کام کر سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ جب آپ حاضری لگا لیتے ہیں تو آپ آن لائن یا آف لائن دونوں موڈ میں جرنی جاری رکھ سکتے ہیں۔ آف لائن رہتے ہوئے کیے گئے آرڈر، چیک اِن، وجوہات یا ہولڈ لوکل قطار (queue) میں محفوظ ہو جاتے ہیں اور انٹرنیٹ آتے ہی خودکار طریقے سے سنک ہو جاتے ہیں — کسی دستی Sync In/Out کی ضرورت نہیں ہوتی۔',
    tagsUr: ['آف لائن', 'آن لائن', 'حاضری', 'آٹو سنک', 'قطار', 'سنک اِن', 'سنک آؤٹ'],
  ),
  FaqItem(
    id: 'offline_auto_sync',
    categoryEn: 'App',
    questionEn: 'Do I need to press any button to sync offline actions?',
    answerEn:
        'No. Motives automatically syncs the queued actions (orders, reasons, payments) when the device is online again. Just keep the app open for a few seconds after the internet is restored.',
    tagsEn: ['auto sync', 'no manual sync', 'offline queue', 'online'],
    categoryUr: 'ایپ',
    questionUr: 'آف لائن میں کیے گئے ایکشن سنک کرنے کیلئے مجھے کوئی بٹن دبانا پڑے گا؟',
    answerUr:
        'نہیں۔ موٹیوز خودکار طور پر قطار میں لگے ہوئے ایکشن (آرڈر، وجوہات، پیمنٹ) کو اس وقت سنک کر دیتا ہے جب موبائل دوبارہ آن لائن ہو جائے۔ بس انٹرنیٹ آنے کے بعد چند سیکنڈ کیلئے ایپ کو کھلا رکھیں۔',
    tagsUr: ['آٹو سنک', 'بغیر بٹن', 'آف لائن قطار', 'آن لائن'],
  ),
  FaqItem(
    id: 'offline_indicator',
    categoryEn: 'App',
    questionEn: 'How will I know the app is in offline mode or syncing?',
    answerEn:
        'You can show a small banner or status chip like “Offline – will auto-sync” or “Syncing…” at the top of the screen. This helps field staff stay confident that their work is saved even without internet.',
    tagsEn: ['offline indicator', 'banner', 'syncing status', 'ui'],
    categoryUr: 'ایپ',
    questionUr: 'میں کیسے جانوں گا/گی کہ ایپ آف لائن ہے یا سنک ہو رہی ہے؟',
    answerUr:
        'آپ اسکرین کے اوپر ایک چھوٹا سا بینر یا اسٹیٹس چِپ دکھا سکتے ہیں جیسے “آف لائن – خودکار سنک ہوگا” یا “سنک ہو رہا ہے…”. اس سے فیلڈ اسٹاف کو یقین رہتا ہے کہ ان کا کام محفوظ ہے چاہے انٹرنیٹ نہ ہو۔',
    tagsUr: ['آف لائن اسٹیٹس', 'بینر', 'سنکنگ اسٹیٹس', 'یو آئی'],
  ),
  FaqItem(
    id: 'offline_limitations',
    categoryEn: 'App',
    questionEn: 'Is everything available in offline mode?',
    answerEn:
        'Core visit actions (check-in, order, no-visit, hold) are supported offline. But fetching NEW data from the server (new journey plan, fresh price list, new SKUs) requires the internet. So, go online at least once a day to stay updated.',
    tagsEn: ['offline limits', 'new data', 'journey plan', 'price list'],
    categoryUr: 'ایپ',
    questionUr: 'کیا آف لائن میں ہر چیز دستیاب ہوتی ہے؟',
    answerUr:
        'بنیادی وزٹ ایکشن (چیک اِن، آرڈر، نو وِزٹ، ہولڈ) آف لائن میں کئے جا سکتے ہیں۔ لیکن سرور سے نیا ڈیٹا (نیا جرنی پلان، نئی قیمتیں، نئے آئٹمز) لانے کیلئے انٹرنیٹ ضروری ہے۔ اس لئے دن میں کم از کم ایک بار آن لائن ضرور جائیں۔',
    tagsUr: ['آف لائن حدود', 'نیا ڈیٹا', 'جرنی پلان', 'قیمت'],
  ),
  FaqItem(
    id: 'offline_sync_troubleshoot',
    categoryEn: 'Troubleshooting',
    questionEn: 'My offline orders are not syncing, what should I check?',
    answerEn:
        'First, confirm the internet is actually working. Then open the app and stay on the screen for a few seconds so the sync worker can run. If it still does not sync, sign out/sign in or contact support — the queued data is still stored locally.',
    tagsEn: ['offline', 'sync not working', 'queue not syncing', 'troubleshoot'],
    categoryUr: 'ٹرَبل شوٹنگ',
    questionUr: 'میری آف لائن انٹریاں سنک نہیں ہو رہیں، کیا چیک کروں؟',
    answerUr:
        'پہلے دیکھیں انٹرنیٹ واقعی آن ہے۔ پھر ایپ کھول کر چند سیکنڈ اسی اسکرین پر رہیں تاکہ سنک خود چلے۔ اگر پھر بھی سنک نہ ہو تو سائن آؤٹ/سائن اِن کریں یا سپورٹ سے رابطہ کریں — قطار میں موجود ڈیٹا لوکل میں محفوظ رہتا ہے۔',
    tagsUr: ['آف لائن', 'سنک نہیں ہو رہا', 'قطار سنک نہیں', 'مسئلہ'],
  ),

  // ===== EXISTING: Overview / Flow / Guardrails / Visits / Orders / Payments / Plan / Errors =====
  FaqItem(
    id: 'ov_what_is_motives',
    categoryEn: 'Overview',
    questionEn: 'What is Motives?',
    answerEn:
        'Motives is a field-sales app for distributors to capture shop orders according to a journey plan. Riders mark attendance, start the route, then visit shops to check-in, take orders, collect payments, mark No-Visit with a reason, or put shops on Hold. You cannot end the route until the journey plan is completed.',
    tagsEn: ['motives', 'overview', 'what is', 'distributor app', 'field sales', 'route'],
    categoryUr: 'جائزہ',
    questionUr: 'موٹیوز کیا ہے؟',
    answerUr:
        'موٹیوز ڈسٹری بیوٹرز کے لئے فیلڈ سیلز ایپ ہے جس سے جرنی پلان کے مطابق دکانوں کے آرڈر لیے جاتے ہیں۔ رائیڈر حاضری لگاتا ہے، روٹ شروع کرتا ہے، پھر دکان پر چیک اِن، آرڈر، پیمنٹ، نو وِزٹ (وجہ کے ساتھ) یا ہولڈ کرتا ہے۔ جرنی پلان مکمل ہونے سے پہلے روٹ ختم نہیں کیا جا سکتا۔',
    tagsUr: ['موٹیوز', 'جائزہ', 'کیا ہے', 'ڈسٹری بیوٹر', 'فیلڈ سیلز', 'روٹ'],
  ),
  FaqItem(
    id: 'route_flow',
    categoryEn: 'Attendance & Route',
    questionEn: 'What is the correct daily flow: attendance, route, and visits?',
    answerEn:
        '1) Mark Attendance → 2) Start Route → 3) Visit shops in order → 4) At each shop: Check-In first, then take an action (Order / Collect Payment / No-Visit with reason / Hold). Repeat until all shops in the journey plan are handled.',
    tagsEn: ['attendance', 'start route', 'flow', 'daily', 'visit order'],
    categoryUr: 'حاضری اور روٹ',
    questionUr: 'روزانہ کا درست طریقہ کیا ہے: حاضری، روٹ اور وزٹس؟',
    answerUr:
        '1) حاضری لگائیں → 2) روٹ شروع کریں → 3) ترتیب کے مطابق دکانوں پر جائیں → 4) ہر دکان پر پہلے چیک اِن کریں، پھر ایکشن کریں (آرڈر / پیمنٹ / نو وِزٹ وجہ کے ساتھ / ہولڈ)۔ یہ عمل تب تک دہرائیں جب تک جرنی پلان مکمل نہ ہو۔',
    tagsUr: ['حاضری', 'روٹ شروع', 'طریقہ', 'روزانہ', 'وزٹ ترتیب'],
  ),
  FaqItem(
    id: 'cant_end_route',
    categoryEn: 'Attendance & Route',
    questionEn: "Why can't I end the route yet?",
    answerEn:
        'You can’t end the route until the full journey plan is covered. Make sure every shop in the current plan is handled (Order Done, No-Visit with reason, or Hold as needed) and you are checked-out from the last visited shop.',
    tagsEn: ['end route', 'cannot end', 'journey plan complete', 'block'],
    categoryUr: 'حاضری اور روٹ',
    questionUr: 'میں روٹ ابھی ختم کیوں نہیں کر پا رہا/رہی؟',
    answerUr:
        'جب تک مکمل جرنی پلان کور نہ ہو، روٹ ختم نہیں کیا جا سکتا۔ موجودہ پلان کی ہر دکان پر ایکشن مکمل کریں (آرڈر ڈن، نو وِزٹ وجہ کے ساتھ، یا ہولڈ) اور آخری وزٹ کی دکان سے چیک آؤٹ یقینی بنائیں۔',
    tagsUr: ['روٹ ختم', 'اختتام نہیں', 'جرنی پلان مکمل', 'بلاک'],
  ),
  FaqItem(
    id: 'checkin_first',
    categoryEn: 'Visits & Reasons',
    questionEn: 'Do I need to Check-In before taking any action at a shop?',
    answerEn:
        'Yes. Check-In is required before taking orders, collecting payments, or selecting reasons (No-Visit/Hold).',
    tagsEn: ['check in', 'required', 'visit', 'reason', 'hold', 'no visit'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'کیا دکان پر کسی بھی ایکشن سے پہلے چیک اِن ضروری ہے؟',
    answerUr:
        'جی ہاں۔ آرڈر لینے، پیمنٹ جمع کرنے یا وجوہات (نو وِزٹ/ہولڈ) منتخب کرنے سے پہلے چیک اِن لازمی ہے۔',
    tagsUr: ['چیک اِن', 'ضروری', 'وزٹ', 'وجہ', 'ہولڈ', 'نو وزٹ'],
  ),
  FaqItem(
    id: 'hold_shop',
    categoryEn: 'Visits & Reasons',
    questionEn: 'When should I mark a shop as Hold?',
    answerEn:
        'Use Hold when the owner is unavailable or the shop is temporarily closed. You can move to the next shop and return later.',
    tagsEn: ['hold', 'unavailable', 'closed', 'reason', 'pause'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'دکان کو ہولڈ کب مارک کروں؟',
    answerUr:
        'جب مالک موجود نہ ہو یا دکان عارضی طور پر بند ہو تو ہولڈ کریں۔ آپ اگلی دکان پر جا سکتے ہیں اور بعد میں واپس آ سکتے ہیں۔',
    tagsUr: ['ہولڈ', 'غیر موجود', 'بند', 'وجہ', 'وقفہ'],
  ),
  FaqItem(
    id: 'no_visit_reason',
    categoryEn: 'Visits & Reasons',
    questionEn: 'How do I mark No-Visit with a reason?',
    answerEn:
        'After Check-In, choose No-Visit and select the appropriate reason from the list, then proceed to the next shop.',
    tagsEn: ['no visit', 'reason', 'visit', 'skip'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'نو وِزٹ وجہ کے ساتھ کیسے مارک کروں؟',
    answerUr:
        'چیک اِن کے بعد نو وِزٹ منتخب کریں اور فہرست میں سے موزوں وجہ چنیں، پھر اگلی دکان پر جائیں۔',
    tagsUr: ['نو وزٹ', 'وجہ', 'وزٹ', 'اسکپ'],
  ),
  FaqItem(
    id: 'place_order',
    categoryEn: 'Orders',
    questionEn: 'How do I take/place an order after Check-In?',
    answerEn:
        'From Order Menu, open Products, add items, and in “My List” press “Confirm & Send”. On success, the shop becomes “Order Done”, you’re checked-out locally, and covered routes increment.',
    tagsEn: ['order', 'take order', 'products', 'confirm & send', 'order done'],
    categoryUr: 'آرڈرز',
    questionUr: 'چیک اِن کے بعد آرڈر کیسے لوں/کروں؟',
    answerUr:
        'آرڈر مینو سے “Products” کھولیں، آئٹمز شامل کریں، پھر “My List” میں “Confirm & Send” دبائیں۔ کامیابی پر دکان “Order Done” ہو جاتی ہے، مقامی طور پر چیک آؤٹ ہو جاتا ہے اور کورڈ روٹس کی گنتی بڑھتی ہے۔',
    tagsUr: ['آرڈر', 'پروڈکٹس', 'کنفرم سینڈ', 'آرڈر ڈن'],
  ),
  FaqItem(
    id: 'brand_filter',
    categoryEn: 'Orders',
    questionEn: 'Can I filter by brand to speed up ordering?',
    answerEn:
        'Yes. Use the brand chips at the top of the catalog and Search to quickly narrow down items.',
    tagsEn: ['brand', 'filter', 'catalog', 'chips', 'search'],
    categoryUr: 'آرڈرز',
    questionUr: 'کیا میں برانڈ فلٹر سے آرڈر تیز بنا سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ کیٹلاگ کے اوپر برانڈ چپس اور سرچ استعمال کریں تاکہ آئٹمز تیزی سے شارٹ لسٹ ہوں۔',
    tagsUr: ['برانڈ', 'فلٹر', 'کیٹلاگ', 'چپس', 'سرچ'],
  ),
  FaqItem(
    id: 'collect_payment',
    categoryEn: 'Payments',
    questionEn: 'Can I collect payment after Check-In?',
    answerEn:
        'If your account has invoice/collection rights, open “Collect Payment” from the Order Menu and follow on-screen steps.',
    tagsEn: ['payment', 'collect', 'invoice', 'rights', 'check in'],
    categoryUr: 'ادائیگیاں',
    questionUr: 'کیا چیک اِن کے بعد پیمنٹ جمع کر سکتا/سکتی ہوں؟',
    answerUr:
        'اگر آپ کے اکاؤنٹ میں ان وائس/کلیکشن کی اجازت ہے تو “Order Menu” سے “Collect Payment” کھولیں اور ہدایات پر عمل کریں۔',
    tagsUr: ['پیمنٹ', 'کلیکٹ', 'ان وائس', 'رائٹس', 'چیک اِن'],
  ),
  FaqItem(
    id: 'area_based_plan',
    categoryEn: 'Journey Plan',
    questionEn: 'How does the area-based journey plan help?',
    answerEn:
        'Shops are grouped by area so you can cover nearby stops in one visit. Use the area filter in Journey Plan to focus and finish faster.',
    tagsEn: ['journey plan', 'area', 'filter', 'efficiency', 'nearby'],
    categoryUr: 'جرنی پلان',
    questionUr: 'ایریا بیسڈ جرنی پلان کیسے مدد دیتا ہے؟',
    answerUr:
        'دکانیں ایریا کے لحاظ سے گروپ ہوتی ہیں تاکہ ایک ہی وزٹ میں قریبی جگہیں کور ہو جائیں۔ جرنی پلان میں ایریا فلٹر استعمال کریں اور کام جلد مکمل کریں۔',
    tagsUr: ['جرنی پلان', 'ایریا', 'فلٹر', 'موثر', 'قریب'],
  ),
  FaqItem(
    id: 'after_success_order',
    categoryEn: 'Journey Plan',
    questionEn: 'What happens after a successful order?',
    answerEn:
        'The shop is marked “Order Done”, local checkout is performed, and your covered-routes/visited count increases so you can continue to the next shop.',
    tagsEn: ['order done', 'visited', 'covered routes', 'checkout'],
    categoryUr: 'جرنی پلان',
    questionUr: 'کامیاب آرڈر کے بعد کیا ہوتا ہے؟',
    answerUr:
        'دکان “آرڈر ڈن” ہو جاتی ہے، مقامی چیک آؤٹ ہو جاتا ہے، اور کورڈ روٹس/وزٹڈ کاؤنٹ بڑھ جاتا ہے تاکہ آپ اگلی دکان پر چل سکیں۔',
    tagsUr: ['آرڈر ڈن', 'وزٹڈ', 'کورڈ روٹس', 'چیک آؤٹ'],
  ),
  FaqItem(
    id: 'order_fail',
    categoryEn: 'Troubleshooting',
    questionEn: 'Why did my order fail to submit?',
    answerEn:
        'Common causes: no network, missing user/distributor, or server maintenance. Check internet and retry. If it persists, contact support.',
    tagsEn: ['error', 'fail', 'submit', 'network', 'server'],
    categoryUr: 'ٹرَبل شوٹنگ',
    questionUr: 'میرا آرڈر سبمٹ کیوں نہیں ہوا؟',
    answerUr:
        'عام وجوہات: انٹرنیٹ نہیں، یوزر/ڈسٹری بیوٹر کی معلومات نہیں، یا سرور مینٹیننس۔ نیٹ چیک کریں اور دوبارہ کوشش کریں۔ مسئلہ برقرار رہے تو سپورٹ سے رابطہ کریں۔',
    tagsUr: ['خرابی', 'ناکام', 'نیٹ ورک', 'سرور', 'سبمٹ'],
  ),
  FaqItem(
    id: 'not_syncing',
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

  // ===== NEW: Daily Flow =====
  FaqItem(
    id: 'df_attendance_what_records',
    categoryEn: 'Daily Flow',
    questionEn: 'What is captured when I mark Attendance?',
    answerEn:
        'Date/time and your GPS position are recorded to clock you in. This enables Start Route and unlocks today’s journey plan.',
    tagsEn: ['attendance', 'clock in', 'gps', 'start route', 'unlock plan'],
    categoryUr: 'ڈیلی فلو',
    questionUr: 'حاضری لگانے پر کیا ریکارڈ ہوتا ہے؟',
    answerUr:
        'حاضری پر تاریخ/وقت اور جی پی ایس محفوظ ہوتے ہیں۔ اس سے اسٹارٹ روٹ فعال ہوتا ہے اور آج کا جرنی پلان کھلتا ہے۔',
    tagsUr: ['حاضری', 'کلاک اِن', 'جی پی ایس', 'اسٹارٹ روٹ', 'پلان کھلنا'],
  ),
  FaqItem(
    id: 'df_location_needed',
    categoryEn: 'Daily Flow',
    questionEn: 'Why is location permission required?',
    answerEn:
        'Attendance, Start Route, Check-In, and Checkout need GPS stamps for compliant visit logs and distance validations.',
    tagsEn: ['gps', 'location', 'compliance', 'visit logs'],
    categoryUr: 'ڈیلی فلو',
    questionUr: 'لوکیشن کی اجازت کیوں ضروری ہے؟',
    answerUr:
        'حاضری، اسٹارٹ روٹ، چیک اِن اور چیک آؤٹ کے لیے جی پی ایس اسٹیمپ درکار ہیں تاکہ درست وزٹ لاگ اور ڈسٹنس ویلیڈیشن ہو سکے۔',
    tagsUr: ['جی پی ایس', 'لوکیشن', 'کمپلائنس', 'وزٹ لاگ'],
  ),
  FaqItem(
    id: 'df_end_route_checks',
    categoryEn: 'Daily Flow',
    questionEn: 'What checks happen before End Route?',
    answerEn:
        'All shops in today’s plan must be handled (Order Done / No-Visit with reason / Hold) and you must be checked-out from the last shop.',
    tagsEn: ['end route', 'journey complete', 'validation'],
    categoryUr: 'ڈیلی فلو',
    questionUr: 'اینڈ روٹ سے پہلے کون سی شرطیں چیک ہوتی ہیں؟',
    answerUr:
        'آج کے پلان کی تمام دکانیں ہینڈل ہونی چاہییں (آرڈر ڈن / نو وزٹ وجہ کے ساتھ / ہولڈ) اور آخری دکان سے چیک آؤٹ لازمی ہو۔',
    tagsUr: ['اینڈ روٹ', 'جرنی مکمل', 'ویلیڈیشن'],
  ),

  // ===== NEW: Shop Actions =====
  FaqItem(
    id: 'sa_checkin_gate',
    categoryEn: 'Shop Actions',
    questionEn: 'Can I take any action without Check-In?',
    answerEn:
        'No. Check-In is mandatory before Order, Collect Payment, No-Visit, or Hold.',
    tagsEn: ['check in', 'mandatory', 'order', 'payment', 'reason', 'hold'],
    categoryUr: 'شاپ ایکشنز',
    questionUr: 'کیا چیک اِن کے بغیر کوئی ایکشن ممکن ہے؟',
    answerUr:
        'نہیں۔ آرڈر، پیمنٹ کلیکشن، نو وزٹ یا ہولڈ سے پہلے چیک اِن لازمی ہے۔',
    tagsUr: ['چیک اِن', 'لازمی', 'آرڈر', 'پیمنٹ', 'وجہ', 'ہولڈ'],
  ),
  FaqItem(
    id: 'sa_single_active_checkin',
    categoryEn: 'Shop Actions',
    questionEn: 'Can I be checked-in to two shops at once?',
    answerEn:
        'No. Only one active Check-In is allowed at a time to keep visit logs consistent.',
    tagsEn: ['check in', 'concurrent', 'visit control'],
    categoryUr: 'شاپ ایکشنز',
    questionUr: 'کیا ایک ہی وقت میں دو دکانوں پر چیک اِن ہو سکتا ہے؟',
    answerUr:
        'نہیں۔ وزٹ لاگز کی درستگی کیلئے ایک وقت میں صرف ایک ایکٹیو چیک اِن ممکن ہے۔',
    tagsUr: ['چیک اِن', 'ایک ساتھ', 'وزٹ کنٹرول'],
  ),
  FaqItem(
    id: 'sa_order_sku_ctn_meaning',
    categoryEn: 'Shop Actions',
    questionEn: 'What do SKU and CTN quantities mean in an order?',
    answerEn:
        'SKU is per-piece or unit quantity. CTN is the number of full cartons. You can send both for each line.',
    tagsEn: ['order', 'sku', 'ctn', 'quantities'],
    categoryUr: 'شاپ ایکشنز',
    questionUr: 'آرڈر میں SKU اور CTN مقدار کا کیا مطلب ہے؟',
    answerUr:
        'SKU فی پیس/یونٹ مقدار ہے جبکہ CTN پورے کارٹن کی گنتی ہے۔ ہر لائن پر دونوں دی جا سکتی ہیں۔',
    tagsUr: ['آرڈر', 'SKU', 'CTN', 'مقدار'],
  ),
  FaqItem(
    id: 'sa_recheckin_block_after_order',
    categoryEn: 'Shop Actions',
    questionEn: 'Why am I blocked from re-check-in after placing an order?',
    answerEn:
        'Once an order is submitted for the current visit, re-check-in is blocked to prevent duplicate orders. You can revisit later per plan.',
    tagsEn: ['order done', 'recheckin', 'duplicate prevention'],
    categoryUr: 'شاپ ایکشنز',
    questionUr: 'آرڈر کے بعد دوبارہ چیک اِن کیوں بلاک ہوتا ہے؟',
    answerUr:
        'موجودہ وزٹ میں آرڈر سبمٹ ہونے کے بعد ڈپلیکیٹ آرڈرز سے بچاؤ کیلئے ری-چیک اِن بلاک رہتا ہے۔ بعد میں پلان کے مطابق دوبارہ جا سکتے ہیں۔',
    tagsUr: ['آرڈر ڈن', 'ری چیک اِن', 'ڈپلیکیٹ سے بچاؤ'],
  ),

  // ===== NEW: Records & History =====
  FaqItem(
    id: 'rec_whats_shown',
    categoryEn: 'Records & History',
    questionEn: 'What details are shown in Records?',
    answerEn:
        'Submitted time, status (Order Done/No-Visit/Hold), total quantity, and full line-items with SKU and CTN for each order.',
    tagsEn: ['records', 'history', 'sku', 'ctn', 'status'],
    categoryUr: 'ریکارڈز اور ہسٹری',
    questionUr: 'ریکارڈز میں کیا کچھ دکھایا جاتا ہے؟',
    answerUr:
        'سبمٹ ٹائم، اسٹیٹس (آرڈر ڈن/نو وزٹ/ہولڈ)، ٹوٹل مقدار، اور آرڈر کی تمام لائنیں SKU اور CTN کے ساتھ۔',
    tagsUr: ['ریکارڈز', 'ہسٹری', 'SKU', 'CTN', 'اسٹیٹس'],
  ),

  // ===== NEW: Offline & Sync =====
  FaqItem(
    id: 'sync_when_runs',
    categoryEn: 'Offline & Sync',
    questionEn: 'When does auto-sync run and what if it fails?',
    answerEn:
        'Auto-sync runs as soon as the device is online. If a submit fails, the item stays queued and retries automatically. Keep the app open for a few seconds after internet returns.',
    tagsEn: ['auto sync', 'retry', 'queue', 'online'],
    categoryUr: 'آف لائن اور سنک',
    questionUr: 'آٹو سنک کب چلتا ہے اور فیل ہونے پر کیا ہوتا ہے؟',
    answerUr:
        'انٹرنیٹ آتے ہی آٹو سنک چلتا ہے۔ فیل ہونے پر آئٹم قطار میں رہتا ہے اور خود دوبارہ کوشش ہوتی ہے۔ انٹرنیٹ آنے کے بعد چند سیکنڈ ایپ کھلی رکھیں۔',
    tagsUr: ['آٹو سنک', 'ری ٹرائی', 'قطار', 'آن لائن'],
  ),

  // ===== NEW: Guardrails & Validation =====
  FaqItem(
    id: 'gv_no_checkin_before_route',
    categoryEn: 'Guardrails & Validation',
    questionEn: 'Can I Check-In before starting the route?',
    answerEn:
        'No. Start Route first, then Check-In. This enforces proper daily flow and accurate logs.',
    tagsEn: ['start route', 'check in', 'flow rule'],
    categoryUr: 'گارڈ ریلز اور ویلیڈیشن',
    questionUr: 'روٹ شروع کئے بغیر چیک اِن ہو سکتا ہے؟',
    answerUr:
        'نہیں۔ پہلے اسٹارٹ روٹ، پھر چیک اِن۔ اس سے درست ڈیلی فلو اور لاگز یقینی ہوتے ہیں۔',
    tagsUr: ['اسٹارٹ روٹ', 'چیک اِن', 'فلو رول'],
  ),
  FaqItem(
    id: 'gv_end_route_blocked',
    categoryEn: 'Guardrails & Validation',
    questionEn: 'Why is End Route blocked?',
    answerEn:
        'Because some shops in the plan are still pending. Handle each (Order Done / No-Visit with reason / Hold) and checkout from the last shop.',
    tagsEn: ['end route', 'blocked', 'pending shops'],
    categoryUr: 'گارڈ ریلز اور ویلیڈیشن',
    questionUr: 'اینڈ روٹ بلاک کیوں ہے؟',
    answerUr:
        'کیونکہ پلان میں کچھ دکانیں باقی ہیں۔ ہر دکان پر ایکشن مکمل کریں (آرڈر ڈن/نو وزٹ/ہولڈ) اور آخری دکان سے چیک آؤٹ کریں۔',
    tagsUr: ['اینڈ روٹ', 'بلاک', 'پینڈنگ دکانیں'],
  ),

  // ===== NEW: Shop States =====
  FaqItem(
    id: 'st_states_map',
    categoryEn: 'Shop States',
    questionEn: 'What are the shop states and transitions?',
    answerEn:
        'Planned → In-Progress (Check-In) → Order Done (auto-checkout) / No-Visit (reason) / Hold (optional revisit). After checkout, the shop is counted as handled.',
    tagsEn: ['states', 'planned', 'in-progress', 'handled'],
    categoryUr: 'شاپ اسٹیٹس',
    questionUr: 'شاپ کے اسٹیٹس اور ٹرانزیشن کیا ہیں؟',
    answerUr:
        'Planned → In-Progress (چیک اِن) → آرڈر ڈن (آٹو چیک آؤٹ) / نو وزٹ (وجہ) / ہولڈ (دوارہ وزٹ ممکن)۔ چیک آؤٹ کے بعد شاپ ہینڈلڈ شمار ہوتی ہے۔',
    tagsUr: ['اسٹیٹس', 'پلانڈ', 'اِن پروگریس', 'ہینڈلڈ'],
  ),

  // ===== NEW: KPIs & Counters =====
  FaqItem(
    id: 'kpi_counters',
    categoryEn: 'KPIs & Counters',
    questionEn: 'Which counters update during the day?',
    answerEn:
        'Covered shops increase after a handled visit (Order Done/No-Visit/Hold + checkout). Optional summaries: Visited today, Orders today, Payments today.',
    tagsEn: ['kpi', 'covered shops', 'visited', 'orders', 'payments'],
    categoryUr: 'کے پی آئیز اور کاؤنٹرز',
    questionUr: 'دن میں کون سے کاؤنٹرز اپڈیٹ ہوتے ہیں؟',
    answerUr:
        'ہینڈلڈ وزٹ (آرڈر ڈن/نو وزٹ/ہولڈ + چیک آؤٹ) پر Covered shops بڑھتا ہے۔ اختیاری سمریز: آج وزٹس، آج آرڈرز، آج پیمنٹس۔',
    tagsUr: ['کے پی آئی', 'کورڈ شاپس', 'وزٹڈ', 'آرڈرز', 'پیمنٹس'],
  ),

  // ===== NEW: Language =====
  FaqItem(
    id: 'lang_toggle',
    categoryEn: 'Language',
    questionEn: 'Can I switch the app guidance between English and Urdu?',
    answerEn:
        'Yes. You can toggle English/Urdu anytime. Your selection is remembered for future sessions.',
    tagsEn: ['language', 'english', 'urdu', 'toggle', 'persist'],
    categoryUr: 'زبان',
    questionUr: 'کیا میں انگلش اور اردو کے درمیان رہنمائی بدل سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ آپ کسی بھی وقت انگلش/اردو منتخب کر سکتے ہیں۔ آپ کی پسند بعد میں بھی محفوظ رہتی ہے۔',
    tagsUr: ['زبان', 'انگلش', 'اردو', 'سوئچ', 'محفوظ'],
  ),

  // ===== NEW: Errors & Messaging =====
  FaqItem(
    id: 'err_gps_off',
    categoryEn: 'Errors',
    questionEn: 'GPS is off — what should I do?',
    answerEn:
        'Turn on location from device settings. Attendance, Start Route, Check-In, and Checkout are blocked without GPS.',
    tagsEn: ['error', 'gps off', 'blocked'],
    categoryUr: 'غلطیاں',
    questionUr: 'جی پی ایس بند ہے — مجھے کیا کرنا چاہیے؟',
    answerUr:
        'ڈیوائس سیٹنگز سے لوکیشن آن کریں۔ جی پی ایس کے بغیر حاضری، اسٹارٹ روٹ، چیک اِن اور چیک آؤٹ بلاک رہتے ہیں۔',
    tagsUr: ['خرابی', 'جی پی ایس بند', 'بلاک'],
  ),

  // ===== NEW: Role — Order Booker / SMO =====
  FaqItem(
    id: 'role_overview',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'What does an Order Booker / SMO do?',
    answerEn:
        'Visit assigned outlets, take accurate orders, ensure displays/merchandising, build retailer relationships, and meet targets per journey plan.',
    tagsEn: ['role', 'order booker', 'smo', 'merchandising', 'targets'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'آرڈر بُکر / ایس ایم او کیا کرتا ہے؟',
    answerUr:
        'مختص دکانوں پر وزٹ، درست آرڈرز، ڈسپلے/مرچنڈائزنگ کی دیکھ بھال، ریٹیلرز سے تعلقات، اور جرنی پلان کے مطابق اہداف پورے کرنا۔',
    tagsUr: ['رول', 'آرڈر بُکر', 'ایس ایم او', 'مرچنڈائزنگ', 'ٹارگٹس'],
  ),
  FaqItem(
    id: 'role_daily_steps',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'What are the daily steps for an Order Booker?',
    answerEn:
        '1) Mark Attendance 2) Start Route 3) Visit shops by area 4) Check-In then Order/Payment/Reason 5) Checkout 6) Repeat 7) End Route.',
    tagsEn: ['daily steps', 'route', 'journey plan'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'آرڈر بُکر کے روزانہ مراحل کیا ہیں؟',
    answerUr:
        '1) حاضری 2) اسٹارٹ روٹ 3) ایریا کے مطابق دکانوں پر وزٹ 4) چیک اِن کے بعد آرڈر/پیمنٹ/وجہ 5) چیک آؤٹ 6) دہرائیں 7) اینڈ روٹ۔',
    tagsUr: ['روزانہ مراحل', 'روٹ', 'جرنی پلان'],
  ),
  FaqItem(
    id: 'role_merchandising',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'What is merchandising in this role?',
    answerEn:
        'Keeping products front-faced, clean shelves, correct pricing, and placing POS materials (banners, wobblers) for visibility.',
    tagsEn: ['merchandising', 'display', 'pos', 'visibility'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'اس رول میں مرچنڈائزنگ کیا ہے؟',
    answerUr:
        'پراڈکٹس کو فرنٹ فیس رکھنا، شیلف صاف، درست قیمتیں، اور پی او ایس میٹریلز (بینرز، وابلرز) لگانا تاکہ ویزیبلٹی بڑھے۔',
    tagsUr: ['مرچنڈائزنگ', 'ڈسپلے', 'پی او ایس', 'ویزبیلٹی'],
  ),
  FaqItem(
    id: 'role_competitor_monitor',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'Do I track competitor activity?',
    answerEn:
        'Yes. Note competitor prices, promotions, and presence. Share insights in your daily report.',
    tagsEn: ['competitor', 'pricing', 'promotion', 'report'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'کیا مجھے حریف برانڈز پر نظر رکھنی ہے؟',
    answerUr:
        'جی ہاں۔ حریف کی قیمتیں، پروموشنز اور دستیابی نوٹ کریں اور روزانہ رپورٹ میں شیئر کریں۔',
    tagsUr: ['حریف', 'قیمت', 'پروموشن', 'رپورٹ'],
  ),
  FaqItem(
    id: 'role_reporting_kpis',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'What should my daily report include?',
    answerEn:
        'Orders booked, outlet coverage, merchandising done, payments collected, and competitor notes mapped to targets/KPIs.',
    tagsEn: ['report', 'kpi', 'targets', 'coverage'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'روزانہ رپورٹ میں کیا شامل ہو؟',
    answerUr:
        'بک کیے گئے آرڈرز، آؤٹ لیٹ کوریج، مرچنڈائزنگ، کلیکشنز، اور حریف نوٹس — سب اہداف/کے پی آئیز کے ساتھ میپ ہوں۔',
    tagsUr: ['رپورٹ', 'کے پی آئی', 'ٹارگٹس', 'کوریج'],
  ),
  FaqItem(
    id: 'role_skills',
    categoryEn: 'Role: Order Booker/SMO',
    questionEn: 'Which skills matter for success?',
    answerEn:
        'Communication, negotiation, time management, display know-how, accurate reporting, and basic app usage.',
    tagsEn: ['skills', 'communication', 'negotiation', 'reporting'],
    categoryUr: 'رول: آرڈر بُکر / ایس ایم او',
    questionUr: 'کامیابی کیلئے کون سی مہارتیں اہم ہیں؟',
    answerUr:
        'کمیونیکیشن، نیگوشیئیشن، ٹائم مینجمنٹ، ڈسپلے کی سمجھ، درست رپورٹنگ اور ایپ کا بنیادی استعمال۔',
    tagsUr: ['مہارت', 'رابطہ', 'بات چیت', 'رپورٹنگ'],
  ),
];

// ---------- SYNONYMS ----------
const Map<String, List<String>> _synEn = {
  'buy': ['purchase', 'order', 'checkout', 'confirm', 'send'],
  'order': ['buy', 'purchase', 'cart', 'bag', 'list'],
  'cart': ['bag', 'basket', 'list'],
  'records': ['history', 'previous', 'past', 'submitted orders', 'logs'],
  'payment': ['pay', 'invoice', 'collect', 'collection'],
  'checkin': ['check in', 'check-in', 'visit'],
  'checkout': ['check out', 'check-out', 'leave'],
  'gps': ['location', 'map', 'blue dot'],
  'error': ['fail', 'failure', 'issue', 'problem'],
  'route': ['journey', 'trip', 'path'],
  'end route': ['finish route', 'close route', 'complete route'],
  'area': ['region', 'zone', 'locality', 'nearby'],
  'brand': ['line', 'label', 'company'],
  // NEW for role/merchandising/KPI
  'smo': ['sales merchandising officer', 'merchandiser', 'order booker'],
  'merchandising': ['display', 'pos', 'visibility', 'shelf', 'planogram'],
  'display': ['front face', 'face out', 'visibility', 'shelf'],
  'pos': ['banners', 'wobblers', 'shelf talker', 'standee'],
  'sku': ['unit', 'piece'],
  'ctn': ['carton', 'case'],
  'kpi': ['targets', 'metrics', 'coverage'],
};

const Map<String, List<String>> _synUr = {
  'آرڈر': ['خرید', 'سبمٹ', 'کنفرم', 'سینڈ', 'کارٹ', 'بیگ', 'فہرست'],
  'کارٹ': ['بیگ', 'فہرست'],
  'ریکارڈز': ['ہسٹری', 'پرانے آرڈر', 'جمع شدہ آرڈرز', 'لاگس'],
  'ادائیگی': ['پیمنٹ', 'بل', 'ان وائس', 'کلیکٹ', 'کلیکشن'],
  'چیک اِن': ['چیک ان', 'حاضری', 'وزٹ شروع'],
  'چیک آؤٹ': ['چیک اوٹ', 'نکلنا', 'وزٹ ختم'],
  'لوکیشن': ['جی پی ایس', 'نقشہ', 'بلیو ڈاٹ'],
  'خرابی': ['مسئلہ', 'ناکامی'],
  'ہولڈ': ['وقفہ', 'عارضی روک'],
  'نو وزٹ': ['کوئی وزٹ نہیں', 'وزٹ نہیں'],
  'روٹ': ['جرنی', 'سفر', 'راستہ'],
  'اختتام': ['ختم', 'بند', 'مکمل'],
  'ایریا': ['علاقہ', 'زون', 'قرب و جوار'],
  'برانڈ': ['لائن', 'کمپنی', 'لیبل'],
  // NEW for role/merchandising/KPI
  'ایس ایم او': ['سیلز مرچنڈائزنگ آفیسر', 'مرچنڈائزر', 'آرڈر بُکر'],
  'مرچنڈائزنگ': ['ڈسپلے', 'پی او ایس', 'ویزبیلٹی', 'شیلف', 'پلینوگرام'],
  'ڈسپلے': ['فرنٹ فیس', 'فیس آؤٹ', 'ویزبیلٹی', 'شیلف'],
  'پی او ایس': ['بینرز', 'وابلرز', 'شیلف ٹاکر', 'اسٹینڈی'],
  'SKU': ['یونٹ', 'پیِس'],
  'CTN': ['کارٹن', 'کیس'],
  'کے پی آئی': ['اہداف', 'میٹرکس', 'کوریج'],
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

  Map<String, dynamic> _fb() => _box.read(_fbKey) as Map<String, dynamic>? ?? {};

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
  final Map<String, int> _df = {};
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
    for (var i = 0; i <= a.length; i++) {
      m[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      m[0][j] = j;
    }
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

// ---------- LOCALIZATION ----------
class L10n {
  final FaqLang lang;
  const L10n(this.lang);

  String get appTitle => lang == FaqLang.en ? 'Smart FAQs' : 'سمارٹ سوالات';
  String get clearChat => lang == FaqLang.en ? 'Clear chat' : 'چیٹ صاف کریں';
  String get askHint => lang == FaqLang.en
      ? 'Ask a question (e.g., “How do I take an order?”)'
      : 'سوال پوچھیں (مثلاً: “آرڈر کیسے لوں؟”)';
  String get ask => lang == FaqLang.en ? 'Ask' : 'پوچھیں';
  String get welcome => lang == FaqLang.en
      ? 'Hi! Ask me anything about Orders, Route, or Payments. Tap a suggestion below to start.'
      : 'سلام! آرڈرز، روٹ یا ادائیگی سے متعلق کچھ بھی پوچھیں۔ شروع کرنے کیلئے نیچے سے کوئی سجیشن چنیں۔';
  String get thanks => lang == FaqLang.en ? 'Thanks for the feedback!' : 'فیڈبیک کا شکریہ!';
  String get noted =>
      lang == FaqLang.en ? 'Noted. We’ll improve these answers.' : 'موصول ہوا۔ ہم ان جوابات کو بہتر بنائیں گے۔';
  String get copied => lang == FaqLang.en ? 'Answer copied to clipboard' : 'جواب کاپی ہو گیا';
  String get couldntFind => lang == FaqLang.en
      ? "I couldn't find an exact answer, but try these or rephrase your question:"
      : 'ٹھیک جواب نہیں ملا، یہ آزمائیں یا سوال تھوڑا بدل دیں:';

  // Non-Motives question message
  String get notMotives => lang == FaqLang.en
      ? 'This question isn’t about Motives app features. This chat only answers questions related to Motives.'
      : 'یہ سوال موٹیوز ایپ کی فیچرز سے متعلق نہیں ہے۔ یہ چیٹ صرف موٹیوز سے متعلق سوالات کے جواب دیتی ہے۔';

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

    // small delay to feel chatty
    await Future.delayed(const Duration(milliseconds: 350));

    final hits = _engine.find(text, topK: 4);
    ChatMessage reply;

    if (hits.isEmpty) {
      final alts = _engine.starterSuggestions();
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text: _t.notMotives,
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
    await _prefs.setLang(lang);
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
        body: Stack(
          children: [
            const WatermarkTiledSmall(tileScale: 3.0),
            Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      _t.appTitle,
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
                    ),
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
                // category + suggestions
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
                          reverse: _lang == FaqLang.ur,
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
                                  _selectedCategory = (i == 0) ? null : label;
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

                // chat
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                              alignment: _lang == FaqLang.ur
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
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

                // composer
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 52),
                  decoration: const BoxDecoration(
                    color: _kCard,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      )
                    ],
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_t.copied)));
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
        border: isUser ? null : Border.all(color: const Color(0xFFEDEFF2)),
        boxShadow: isUser
            ? const []
            : const [
                BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))
              ],
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.28),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCopy != null)
                  _MiniIconButton(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy!),
                if (onShare != null) const SizedBox(width: 3),
                if (onShare != null)
                  _MiniIconButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare!),
                if (onThumbUp != null || onThumbDown != null) const SizedBox(width: 3),
                if (onThumbUp != null)
                  _MiniIconButton(
                    icon: Icons.thumb_up_outlined,
                    label: 'Helpful',
                    onTap: onThumbUp!,
                  ),
                if (onThumbDown != null) const SizedBox(width: 3),
                if (onThumbDown != null)
                  _MiniIconButton(
                    icon: Icons.thumb_down_outlined,
                    label: 'Not helpful',
                    onTap: onThumbDown!,
                  ),
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
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
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


/*

// ---------- THEME ----------
const _kBg = Color(0xFFF7F8FA);
const _kCard = Colors.white;
const _kText = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6C7580);
const _kAccent = Color(0xFFEA7A3B);

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

// ---------- DATA (domain Q&As) ----------
const _faqs = <FaqItem>[
  // 1) NEW — Offline / Online after attendance
  FaqItem(
    id: 'offline_after_attendance',
    categoryEn: 'App',
    questionEn: 'After marking attendance, can I work in offline mode?',
    answerEn:
        'Yes. Once your attendance is marked, you can continue your journey in either online or offline mode. Any orders, check-ins, reasons, or holds done while offline are kept in a local queue and are synced automatically when the internet comes back — no manual Sync In/Out is required.',
    tagsEn: ['offline', 'online', 'attendance', 'auto sync', 'queue', 'sync in', 'sync out'],
    categoryUr: 'ایپ',
    questionUr: 'حاضری لگانے کے بعد کیا میں آف لائن موڈ میں کام کر سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ جب آپ حاضری لگا لیتے ہیں تو آپ آن لائن یا آف لائن دونوں موڈ میں جرنی جاری رکھ سکتے ہیں۔ آف لائن رہتے ہوئے کیے گئے آرڈر، چیک اِن، وجوہات یا ہولڈ لوکل قطار (queue) میں محفوظ ہو جاتے ہیں اور انٹرنیٹ آتے ہی خودکار طریقے سے سنک ہو جاتے ہیں — کسی دستی Sync In/Out کی ضرورت نہیں ہوتی۔',
    tagsUr: ['آف لائن', 'آن لائن', 'حاضری', 'آٹو سنک', 'قطار', 'سنک اِن', 'سنک آؤٹ'],
  ),

  // 2) NEW — Auto sync behaviour
  FaqItem(
    id: 'offline_auto_sync',
    categoryEn: 'App',
    questionEn: 'Do I need to press any button to sync offline actions?',
    answerEn:
        'No. Motives automatically syncs the queued actions (orders, reasons, payments) when the device is online again. Just keep the app open for a few seconds after the internet is restored.',
    tagsEn: ['auto sync', 'no manual sync', 'offline queue', 'online'],
    categoryUr: 'ایپ',
    questionUr: 'آف لائن میں کیے گئے ایکشن سنک کرنے کیلئے مجھے کوئی بٹن دبانا پڑے گا؟',
    answerUr:
        'نہیں۔ موٹیوز خودکار طور پر قطار میں لگے ہوئے ایکشن (آرڈر، وجوہات، پیمنٹ) کو اس وقت سنک کر دیتا ہے جب موبائل دوبارہ آن لائن ہو جائے۔ بس انٹرنیٹ آنے کے بعد چند سیکنڈ کیلئے ایپ کو کھلا رکھیں۔',
    tagsUr: ['آٹو سنک', 'بغیر بٹن', 'آف لائن قطار', 'آن لائن'],
  ),

  // 3) NEW — Status / indicator
  FaqItem(
    id: 'offline_indicator',
    categoryEn: 'App',
    questionEn: 'How will I know the app is in offline mode or syncing?',
    answerEn:
        'You can show a small banner or status chip like “Offline – will auto-sync” or “Syncing…” at the top of the screen. This helps field staff stay confident that their work is saved even without internet.',
    tagsEn: ['offline indicator', 'banner', 'syncing status', 'ui'],
    categoryUr: 'ایپ',
    questionUr: 'میں کیسے جانوں گا/گی کہ ایپ آف لائن ہے یا سنک ہو رہی ہے؟',
    answerUr:
        'آپ اسکرین کے اوپر ایک چھوٹا سا بینر یا اسٹیٹس چِپ دکھا سکتے ہیں جیسے “آف لائن – خودکار سنک ہوگا” یا “سنک ہو رہا ہے…”. اس سے فیلڈ اسٹاف کو یقین رہتا ہے کہ ان کا کام محفوظ ہے چاہے انٹرنیٹ نہ ہو۔',
    tagsUr: ['آف لائن اسٹیٹس', 'بینر', 'سنکنگ اسٹیٹس', 'یو آئی'],
  ),

  // 4) NEW — What is NOT synced offline
  FaqItem(
    id: 'offline_limitations',
    categoryEn: 'App',
    questionEn: 'Is everything available in offline mode?',
    answerEn:
        'Core visit actions (check-in, order, no-visit, hold) are supported offline. But fetching NEW data from the server (new journey plan, fresh price list, new SKUs) requires the internet. So, go online at least once a day to stay updated.',
    tagsEn: ['offline limits', 'new data', 'journey plan', 'price list'],
    categoryUr: 'ایپ',
    questionUr: 'کیا آف لائن میں ہر چیز دستیاب ہوتی ہے؟',
    answerUr:
        'بنیادی وزٹ ایکشن (چیک اِن، آرڈر، نو وِزٹ، ہولڈ) آف لائن میں کئے جا سکتے ہیں۔ لیکن سرور سے نیا ڈیٹا (نیا جرنی پلان، نئی قیمتیں، نئے آئٹمز) لانے کیلئے انٹرنیٹ ضروری ہے۔ اس لئے دن میں کم از کم ایک بار آن لائن ضرور جائیں۔',
    tagsUr: ['آف لائن حدود', 'نیا ڈیٹا', 'جرنی پلان', 'قیمت'],
  ),

  // 5) NEW — Troubleshooting sync
  FaqItem(
    id: 'offline_sync_troubleshoot',
    categoryEn: 'Troubleshooting',
    questionEn: 'My offline orders are not syncing, what should I check?',
    answerEn:
        'First, confirm the internet is actually working. Then open the app and stay on the screen for a few seconds so the sync worker can run. If it still does not sync, sign out/sign in or contact support — the queued data is still stored locally.',
    tagsEn: ['offline', 'sync not working', 'queue not syncing', 'troubleshoot'],
    categoryUr: 'ٹرَبل شوٹنگ',
    questionUr: 'میری آف لائن انٹریاں سنک نہیں ہو رہیں، کیا چیک کروں؟',
    answerUr:
        'پہلے دیکھیں انٹرنیٹ واقعی آن ہے۔ پھر ایپ کھول کر چند سیکنڈ اسی اسکرین پر رہیں تاکہ سنک خود چلے۔ اگر پھر بھی سنک نہ ہو تو سائن آؤٹ/سائن اِن کریں یا سپورٹ سے رابطہ کریں — قطار میں موجود ڈیٹا لوکل میں محفوظ رہتا ہے۔',
    tagsUr: ['آف لائن', 'سنک نہیں ہو رہا', 'قطار سنک نہیں', 'مسئلہ'],
  ),

  // EXISTING FAQS -------------
  FaqItem(
    id: 'ov_what_is_motives',
    categoryEn: 'Overview',
    questionEn: 'What is Motives?',
    answerEn:
        'Motives is a field-sales app for distributors to capture shop orders according to a journey plan. Riders mark attendance, start the route, then visit shops to check-in, take orders, collect payments, mark No-Visit with a reason, or put shops on Hold. You cannot end the route until the journey plan is completed.',
    tagsEn: ['motives', 'overview', 'what is', 'distributor app', 'field sales', 'route'],
    categoryUr: 'جائزہ',
    questionUr: 'موٹیوز کیا ہے؟',
    answerUr:
        'موٹیوز ڈسٹری بیوٹرز کے لئے فیلڈ سیلز ایپ ہے جس سے جرنی پلان کے مطابق دکانوں کے آرڈر لیے جاتے ہیں۔ رائیڈر حاضری لگاتا ہے، روٹ شروع کرتا ہے، پھر دکان پر چیک اِن، آرڈر، پیمنٹ، نو وِزٹ (وجہ کے ساتھ) یا ہولڈ کرتا ہے۔ جرنی پلان مکمل ہونے سے پہلے روٹ ختم نہیں کیا جا سکتا۔',
    tagsUr: ['موٹیوز', 'جائزہ', 'کیا ہے', 'ڈسٹری بیوٹر', 'فیلڈ سیلز', 'روٹ'],
  ),
  FaqItem(
    id: 'route_flow',
    categoryEn: 'Attendance & Route',
    questionEn: 'What is the correct daily flow: attendance, route, and visits?',
    answerEn:
        '1) Mark Attendance → 2) Start Route → 3) Visit shops in order → 4) At each shop: Check-In first, then take an action (Order / Collect Payment / No-Visit with reason / Hold). Repeat until all shops in the journey plan are handled.',
    tagsEn: ['attendance', 'start route', 'flow', 'daily', 'visit order'],
    categoryUr: 'حاضری اور روٹ',
    questionUr: 'روزانہ کا درست طریقہ کیا ہے: حاضری، روٹ اور وزٹس؟',
    answerUr:
        '1) حاضری لگائیں → 2) روٹ شروع کریں → 3) ترتیب کے مطابق دکانوں پر جائیں → 4) ہر دکان پر پہلے چیک اِن کریں، پھر ایکشن کریں (آرڈر / پیمنٹ / نو وِزٹ وجہ کے ساتھ / ہولڈ)۔ یہ عمل تب تک دہرائیں جب تک جرنی پلان مکمل نہ ہو۔',
    tagsUr: ['حاضری', 'روٹ شروع', 'طریقہ', 'روزانہ', 'وزٹ ترتیب'],
  ),
  FaqItem(
    id: 'cant_end_route',
    categoryEn: 'Attendance & Route',
    questionEn: "Why can't I end the route yet?",
    answerEn:
        'You can’t end the route until the full journey plan is covered. Make sure every shop in the current plan is handled (Order Done, No-Visit with reason, or Hold as needed) and you are checked-out from the last visited shop.',
    tagsEn: ['end route', 'cannot end', 'journey plan complete', 'block'],
    categoryUr: 'حاضری اور روٹ',
    questionUr: 'میں روٹ ابھی ختم کیوں نہیں کر پا رہا/رہی؟',
    answerUr:
        'جب تک مکمل جرنی پلان کور نہ ہو، روٹ ختم نہیں کیا جا سکتا۔ موجودہ پلان کی ہر دکان پر ایکشن مکمل کریں (آرڈر ڈن، نو وِزٹ وجہ کے ساتھ، یا ہولڈ) اور آخری وزٹ کی دکان سے چیک آؤٹ یقینی بنائیں۔',
    tagsUr: ['روٹ ختم', 'اختتام نہیں', 'جرنی پلان مکمل', 'بلاک'],
  ),
  FaqItem(
    id: 'checkin_first',
    categoryEn: 'Visits & Reasons',
    questionEn: 'Do I need to Check-In before taking any action at a shop?',
    answerEn:
        'Yes. Check-In is required before taking orders, collecting payments, or selecting reasons (No-Visit/Hold).',
    tagsEn: ['check in', 'required', 'visit', 'reason', 'hold', 'no visit'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'کیا دکان پر کسی بھی ایکشن سے پہلے چیک اِن ضروری ہے؟',
    answerUr:
        'جی ہاں۔ آرڈر لینے، پیمنٹ جمع کرنے یا وجوہات (نو وِزٹ/ہولڈ) منتخب کرنے سے پہلے چیک اِن لازمی ہے۔',
    tagsUr: ['چیک اِن', 'ضروری', 'وزٹ', 'وجہ', 'ہولڈ', 'نو وزٹ'],
  ),
  FaqItem(
    id: 'hold_shop',
    categoryEn: 'Visits & Reasons',
    questionEn: 'When should I mark a shop as Hold?',
    answerEn:
        'Use Hold when the owner is unavailable or the shop is temporarily closed. You can move to the next shop and return later.',
    tagsEn: ['hold', 'unavailable', 'closed', 'reason', 'pause'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'دکان کو ہولڈ کب مارک کروں؟',
    answerUr:
        'جب مالک موجود نہ ہو یا دکان عارضی طور پر بند ہو تو ہولڈ کریں۔ آپ اگلی دکان پر جا سکتے ہیں اور بعد میں واپس آ سکتے ہیں۔',
    tagsUr: ['ہولڈ', 'غیر موجود', 'بند', 'وجہ', 'وقفہ'],
  ),
  FaqItem(
    id: 'no_visit_reason',
    categoryEn: 'Visits & Reasons',
    questionEn: 'How do I mark No-Visit with a reason?',
    answerEn:
        'After Check-In, choose No-Visit and select the appropriate reason from the list, then proceed to the next shop.',
    tagsEn: ['no visit', 'reason', 'visit', 'skip'],
    categoryUr: 'وزٹس اور وجوہات',
    questionUr: 'نو وِزٹ وجہ کے ساتھ کیسے مارک کروں؟',
    answerUr:
        'چیک اِن کے بعد نو وِزٹ منتخب کریں اور فہرست میں سے موزوں وجہ چنیں، پھر اگلی دکان پر جائیں۔',
    tagsUr: ['نو وزٹ', 'وجہ', 'وزٹ', 'اسکپ'],
  ),
  FaqItem(
    id: 'place_order',
    categoryEn: 'Orders',
    questionEn: 'How do I take/place an order after Check-In?',
    answerEn:
        'From Order Menu, open Products, add items, and in “My List” press “Confirm & Send”. On success, the shop becomes “Order Done”, you’re checked-out locally, and covered routes increment.',
    tagsEn: ['order', 'take order', 'products', 'confirm & send', 'order done'],
    categoryUr: 'آرڈرز',
    questionUr: 'چیک اِن کے بعد آرڈر کیسے لوں/کروں؟',
    answerUr:
        'آرڈر مینو سے “Products” کھولیں، آئٹمز شامل کریں، پھر “My List” میں “Confirm & Send” دبائیں۔ کامیابی پر دکان “Order Done” ہو جاتی ہے، مقامی طور پر چیک آؤٹ ہو جاتا ہے اور کورڈ روٹس کی گنتی بڑھتی ہے۔',
    tagsUr: ['آرڈر', 'پروڈکٹس', 'کنفرم سینڈ', 'آرڈر ڈن'],
  ),
  FaqItem(
    id: 'brand_filter',
    categoryEn: 'Orders',
    questionEn: 'Can I filter by brand to speed up ordering?',
    answerEn:
        'Yes. Use the brand chips at the top of the catalog and Search to quickly narrow down items.',
    tagsEn: ['brand', 'filter', 'catalog', 'chips', 'search'],
    categoryUr: 'آرڈرز',
    questionUr: 'کیا میں برانڈ فلٹر سے آرڈر تیز بنا سکتا/سکتی ہوں؟',
    answerUr:
        'جی ہاں۔ کیٹلاگ کے اوپر برانڈ چپس اور سرچ استعمال کریں تاکہ آئٹمز تیزی سے شارٹ لسٹ ہوں۔',
    tagsUr: ['برانڈ', 'فلٹر', 'کیٹلاگ', 'چپس', 'سرچ'],
  ),
  FaqItem(
    id: 'collect_payment',
    categoryEn: 'Payments',
    questionEn: 'Can I collect payment after Check-In?',
    answerEn:
        'If your account has invoice/collection rights, open “Collect Payment” from the Order Menu and follow on-screen steps.',
    tagsEn: ['payment', 'collect', 'invoice', 'rights', 'check in'],
    categoryUr: 'ادائیگیاں',
    questionUr: 'کیا چیک اِن کے بعد پیمنٹ جمع کر سکتا/سکتی ہوں؟',
    answerUr:
        'اگر آپ کے اکاؤنٹ میں ان وائس/کلیکشن کی اجازت ہے تو “Order Menu” سے “Collect Payment” کھولیں اور ہدایات پر عمل کریں۔',
    tagsUr: ['پیمنٹ', 'کلیکٹ', 'ان وائس', 'رائٹس', 'چیک اِن'],
  ),
  FaqItem(
    id: 'area_based_plan',
    categoryEn: 'Journey Plan',
    questionEn: 'How does the area-based journey plan help?',
    answerEn:
        'Shops are grouped by area so you can cover nearby stops in one visit. Use the area filter in Journey Plan to focus and finish faster.',
    tagsEn: ['journey plan', 'area', 'filter', 'efficiency', 'nearby'],
    categoryUr: 'جرنی پلان',
    questionUr: 'ایریا بیسڈ جرنی پلان کیسے مدد دیتا ہے؟',
    answerUr:
        'دکانیں ایریا کے لحاظ سے گروپ ہوتی ہیں تاکہ ایک ہی وزٹ میں قریبی جگہیں کور ہو جائیں۔ جرنی پلان میں ایریا فلٹر استعمال کریں اور کام جلد مکمل کریں۔',
    tagsUr: ['جرنی پلان', 'ایریا', 'فلٹر', 'موثر', 'قریب'],
  ),
  FaqItem(
    id: 'after_success_order',
    categoryEn: 'Journey Plan',
    questionEn: 'What happens after a successful order?',
    answerEn:
        'The shop is marked “Order Done”, local checkout is performed, and your covered-routes/visited count increases so you can continue to the next shop.',
    tagsEn: ['order done', 'visited', 'covered routes', 'checkout'],
    categoryUr: 'جرنی پلان',
    questionUr: 'کامیاب آرڈر کے بعد کیا ہوتا ہے؟',
    answerUr:
        'دکان “آرڈر ڈن” ہو جاتی ہے، مقامی چیک آؤٹ ہو جاتا ہے، اور کورڈ روٹس/وزٹڈ کاؤنٹ بڑھ جاتا ہے تاکہ آپ اگلی دکان پر چل سکیں۔',
    tagsUr: ['آرڈر ڈن', 'وزٹڈ', 'کورڈ روٹس', 'چیک آؤٹ'],
  ),
  FaqItem(
    id: 'order_fail',
    categoryEn: 'Troubleshooting',
    questionEn: 'Why did my order fail to submit?',
    answerEn:
        'Common causes: no network, missing user/distributor, or server maintenance. Check internet and retry. If it persists, contact support.',
    tagsEn: ['error', 'fail', 'submit', 'network', 'server'],
    categoryUr: 'ٹرَبل شوٹنگ',
    questionUr: 'میرا آرڈر سبمٹ کیوں نہیں ہوا؟',
    answerUr:
        'عام وجوہات: انٹرنیٹ نہیں، یوزر/ڈسٹری بیوٹر کی معلومات نہیں، یا سرور مینٹیننس۔ نیٹ چیک کریں اور دوبارہ کوشش کریں۔ مسئلہ برقرار رہے تو سپورٹ سے رابطہ کریں۔',
    tagsUr: ['خرابی', 'ناکام', 'نیٹ ورک', 'سرور', 'سبمٹ'],
  ),
  FaqItem(
    id: 'not_syncing',
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
  'route': ['journey', 'trip', 'path'],
  'end route': ['finish route', 'close route', 'complete route'],
  'area': ['region', 'zone', 'locality', 'nearby'],
  'brand': ['line', 'label', 'company'],
};

const Map<String, List<String>> _synUr = {
  'آرڈر': ['خرید', 'سبمٹ', 'کنفرم', 'سینڈ', 'کارٹ', 'بیگ', 'فہرست'],
  'کارٹ': ['بیگ', 'فہرست'],
  'ریکارڈز': ['ہسٹری', 'پرانے آرڈر'],
  'ادائیگی': ['پیمنٹ', 'بل', 'ان وائس', 'کلیکٹ'],
  'چیک اِن': ['چیک ان', 'حاضری', 'وزٹ شروع'],
  'چیک آؤٹ': ['چیک اوٹ', 'نکلنا', 'وزٹ ختم'],
  'لوکیشن': ['جی پی ایس', 'نقشہ', 'بلیو ڈاٹ'],
  'خرابی': ['مسئلہ', 'ناکامی'],
  'ہولڈ': ['وقفہ', 'عارضی روک'],
  'نو وزٹ': ['کوئی وزٹ نہیں', 'وزٹ نہیں'],
  'روٹ': ['جرنی', 'سفر', 'راستہ'],
  'اختتام': ['ختم', 'بند', 'مکمل'],
  'ایریا': ['علاقہ', 'زون', 'قرب و جوار'],
  'برانڈ': ['لائن', 'کمپنی', 'لیبل'],
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

  Map<String, dynamic> _fb() => _box.read(_fbKey) as Map<String, dynamic>? ?? {};

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
  final Map<String, int> _df = {};
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
    for (var i = 0; i <= a.length; i++) {
      m[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      m[0][j] = j;
    }
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

// ---------- LOCALIZATION ----------
class L10n {
  final FaqLang lang;
  const L10n(this.lang);

  String get appTitle => lang == FaqLang.en ? 'Smart FAQs' : 'سمارٹ سوالات';
  String get clearChat => lang == FaqLang.en ? 'Clear chat' : 'چیٹ صاف کریں';
  String get askHint => lang == FaqLang.en
      ? 'Ask a question (e.g., “How do I take an order?”)'
      : 'سوال پوچھیں (مثلاً: “آرڈر کیسے لوں؟”)';
  String get ask => lang == FaqLang.en ? 'Ask' : 'پوچھیں';
  String get welcome => lang == FaqLang.en
      ? 'Hi! Ask me anything about Orders, Route, or Payments. Tap a suggestion below to start.'
      : 'سلام! آرڈرز، روٹ یا ادائیگی سے متعلق کچھ بھی پوچھیں۔ شروع کرنے کیلئے نیچے سے کوئی سجیشن چنیں۔';
  String get thanks => lang == FaqLang.en ? 'Thanks for the feedback!' : 'فیڈبیک کا شکریہ!';
  String get noted =>
      lang == FaqLang.en ? 'Noted. We’ll improve these answers.' : 'موصول ہوا۔ ہم ان جوابات کو بہتر بنائیں گے۔';
  String get copied => lang == FaqLang.en ? 'Answer copied to clipboard' : 'جواب کاپی ہو گیا';
  String get couldntFind => lang == FaqLang.en
      ? "I couldn't find an exact answer, but try these or rephrase your question:"
      : 'ٹھیک جواب نہیں ملا، یہ آزمائیں یا سوال تھوڑا بدل دیں:';

  // 👇 NEW: non-Motives question message
  String get notMotives => lang == FaqLang.en
      ? 'This question isn’t about Motives app features. This chat only answers questions related to Motives.'
      : 'یہ سوال موٹیوز ایپ کی فیچرز سے متعلق نہیں ہے۔ یہ چیٹ صرف موٹیوز سے متعلق سوالات کے جواب دیتی ہے۔';

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

    // small delay to feel chatty
    await Future.delayed(const Duration(milliseconds: 350));

    final hits = _engine.find(text, topK: 4);
    ChatMessage reply;

    if (hits.isEmpty) {
      // 👇 your new behavior: if it's not in Motives FAQ
      final alts = _engine.starterSuggestions();
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text: _t.notMotives,
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
    await _prefs.setLang(lang);
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
        body: Stack(
          children: [
            const WatermarkTiledSmall(tileScale: 3.0),
            Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      _t.appTitle,
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
                    ),
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
                // category + suggestions
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
                          reverse: _lang == FaqLang.ur,
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
                                  _selectedCategory = (i == 0) ? null : label;
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

                // chat
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                              alignment: _lang == FaqLang.ur
                                  ? WrapAlignment.end
                                  : WrapAlignment.start,
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

                // composer
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 52),
                  decoration: const BoxDecoration(
                    color: _kCard,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      )
                    ],
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
          ],
        ),
      ),
    );
  }

  void _share(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_t.copied)));
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
            : const [
                BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))
              ],
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.28),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCopy != null)
                  _MiniIconButton(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy!),
                if (onShare != null) const SizedBox(width: 3),
                if (onShare != null)
                  _MiniIconButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare!),
                if (onThumbUp != null || onThumbDown != null) const SizedBox(width: 3),
                if (onThumbUp != null)
                  _MiniIconButton(
                    icon: Icons.thumb_up_outlined,
                    label: 'Helpful',
                    onTap: onThumbUp!,
                  ),
                if (onThumbDown != null) const SizedBox(width: 3),
                if (onThumbDown != null)
                  _MiniIconButton(
                    icon: Icons.thumb_down_outlined,
                    label: 'Not helpful',
                    onTap: onThumbDown!,
                  ),
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
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
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
*/




// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:motives_new_ui_conversion/widgets/watermark_widget.dart';

// // ---------- THEME ----------
// const _kBg = Color(0xFFF7F8FA);
// const _kCard = Colors.white;
// const _kText = Color(0xFF1E1E1E);
// const _kMuted = Color(0xFF6C7580);
// const _kAccent = Color(0xFFEA7A3B);

// // ---------- LANG ----------
// enum FaqLang { en, ur }

// extension FaqLangX on FaqLang {
//   String get code => this == FaqLang.en ? 'en' : 'ur';
//   TextDirection get dir => this == FaqLang.ur ? TextDirection.rtl : TextDirection.ltr;
// }

// // ---------- MODELS ----------
// enum ChatRole { user, bot }

// class ChatMessage {
//   final String id;
//   final ChatRole role;
//   final String text;
//   final DateTime ts;
//   final List<String> suggestions;
//   ChatMessage({
//     required this.id,
//     required this.role,
//     required this.text,
//     required this.ts,
//     this.suggestions = const [],
//   });

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'role': role.name,
//         'text': text,
//         'ts': ts.toIso8601String(),
//         'sug': suggestions,
//       };

//   static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
//         id: j['id'] as String,
//         role: j['role'] == 'user' ? ChatRole.user : ChatRole.bot,
//         text: (j['text'] ?? '').toString(),
//         ts: DateTime.tryParse((j['ts'] ?? '').toString()) ?? DateTime.now(),
//         suggestions: (j['sug'] as List?)?.map((e) => e.toString()).toList() ?? const [],
//       );
// }

// class FaqItem {
//   final String id;

//   // EN
//   final String categoryEn;
//   final String questionEn;
//   final String answerEn;
//   final List<String> tagsEn;

//   // UR
//   final String categoryUr;
//   final String questionUr;
//   final String answerUr;
//   final List<String> tagsUr;

//   const FaqItem({
//     required this.id,
//     required this.categoryEn,
//     required this.questionEn,
//     required this.answerEn,
//     required this.tagsEn,
//     required this.categoryUr,
//     required this.questionUr,
//     required this.answerUr,
//     required this.tagsUr,
//   });

//   String category(FaqLang l) => l == FaqLang.en ? categoryEn : categoryUr;
//   String question(FaqLang l) => l == FaqLang.en ? questionEn : questionUr;
//   String answer(FaqLang l) => l == FaqLang.en ? answerEn : answerUr;
//   List<String> tags(FaqLang l) => l == FaqLang.en ? tagsEn : tagsUr;
// }

// // ---------- DATA (domain Q&As) ----------
// const _faqs = <FaqItem>[
//     // 1) NEW — Offline / Online after attendance
//   FaqItem(
//     id: 'offline_after_attendance',
//     categoryEn: 'App',
//     questionEn: 'After marking attendance, can I work in offline mode?',
//     answerEn:
//         'Yes. Once your attendance is marked, you can continue your journey in either online or offline mode. Any orders, check-ins, reasons, or holds done while offline are kept in a local queue and are synced automatically when the internet comes back — no manual Sync In/Out is required.',
//     tagsEn: ['offline', 'online', 'attendance', 'auto sync', 'queue', 'sync in', 'sync out'],
//     categoryUr: 'ایپ',
//     questionUr: 'حاضری لگانے کے بعد کیا میں آف لائن موڈ میں کام کر سکتا/سکتی ہوں؟',
//     answerUr:
//         'جی ہاں۔ جب آپ حاضری لگا لیتے ہیں تو آپ آن لائن یا آف لائن دونوں موڈ میں جرنی جاری رکھ سکتے ہیں۔ آف لائن رہتے ہوئے کیے گئے آرڈر، چیک اِن، وجوہات یا ہولڈ لوکل قطار (queue) میں محفوظ ہو جاتے ہیں اور انٹرنیٹ آتے ہی خودکار طریقے سے سنک ہو جاتے ہیں — کسی دستی Sync In/Out کی ضرورت نہیں ہوتی۔',
//     tagsUr: ['آف لائن', 'آن لائن', 'حاضری', 'آٹو سنک', 'قطار', 'سنک اِن', 'سنک آؤٹ'],
//   ),

//   // 2) NEW — Auto sync behaviour
//   FaqItem(
//     id: 'offline_auto_sync',
//     categoryEn: 'App',
//     questionEn: 'Do I need to press any button to sync offline actions?',
//     answerEn:
//         'No. Motives automatically syncs the queued actions (orders, reasons, payments) when the device is online again. Just keep the app open for a few seconds after the internet is restored.',
//     tagsEn: ['auto sync', 'no manual sync', 'offline queue', 'online'],
//     categoryUr: 'ایپ',
//     questionUr: 'آف لائن میں کیے گئے ایکشن سنک کرنے کیلئے مجھے کوئی بٹن دبانا پڑے گا؟',
//     answerUr:
//         'نہیں۔ موٹیوز خودکار طور پر قطار میں لگے ہوئے ایکشن (آرڈر، وجوہات، پیمنٹ) کو اس وقت سنک کر دیتا ہے جب موبائل دوبارہ آن لائن ہو جائے۔ بس انٹرنیٹ آنے کے بعد چند سیکنڈ کیلئے ایپ کو کھلا رکھیں۔',
//     tagsUr: ['آٹو سنک', 'بغیر بٹن', 'آف لائن قطار', 'آن لائن'],
//   ),

//   // 3) NEW — Status / indicator
//   FaqItem(
//     id: 'offline_indicator',
//     categoryEn: 'App',
//     questionEn: 'How will I know the app is in offline mode or syncing?',
//     answerEn:
//         'You can show a small banner or status chip like “Offline – will auto-sync” or “Syncing…” at the top of the screen. This helps field staff stay confident that their work is saved even without internet.',
//     tagsEn: ['offline indicator', 'banner', 'syncing status', 'ui'],
//     categoryUr: 'ایپ',
//     questionUr: 'میں کیسے جانوں گا/گی کہ ایپ آف لائن ہے یا سنک ہو رہی ہے؟',
//     answerUr:
//         'آپ اسکرین کے اوپر ایک چھوٹا سا بینر یا اسٹیٹس چِپ دکھا سکتے ہیں جیسے “آف لائن – خودکار سنک ہوگا” یا “سنک ہو رہا ہے…”. اس سے فیلڈ اسٹاف کو یقین رہتا ہے کہ ان کا کام محفوظ ہے چاہے انٹرنیٹ نہ ہو۔',
//     tagsUr: ['آف لائن اسٹیٹس', 'بینر', 'سنکنگ اسٹیٹس', 'یو آئی'],
//   ),

//   // 4) NEW — What is NOT synced offline
//   FaqItem(
//     id: 'offline_limitations',
//     categoryEn: 'App',
//     questionEn: 'Is everything available in offline mode?',
//     answerEn:
//         'Core visit actions (check-in, order, no-visit, hold) are supported offline. But fetching NEW data from the server (new journey plan, fresh price list, new SKUs) requires the internet. So, go online at least once a day to stay updated.',
//     tagsEn: ['offline limits', 'new data', 'journey plan', 'price list'],
//     categoryUr: 'ایپ',
//     questionUr: 'کیا آف لائن میں ہر چیز دستیاب ہوتی ہے؟',
//     answerUr:
//         'بنیادی وزٹ ایکشن (چیک اِن، آرڈر، نو وِزٹ، ہولڈ) آف لائن میں کئے جا سکتے ہیں۔ لیکن سرور سے نیا ڈیٹا (نیا جرنی پلان، نئی قیمتیں، نئے آئٹمز) لانے کیلئے انٹرنیٹ ضروری ہے۔ اس لئے دن میں کم از کم ایک بار آن لائن ضرور جائیں۔',
//     tagsUr: ['آف لائن حدود', 'نیا ڈیٹا', 'جرنی پلان', 'قیمت'],
//   ),

//   // 5) NEW — Troubleshooting sync
//   FaqItem(
//     id: 'offline_sync_troubleshoot',
//     categoryEn: 'Troubleshooting',
//     questionEn: 'My offline orders are not syncing, what should I check?',
//     answerEn:
//         'First, confirm the internet is actually working. Then open the app and stay on the screen for a few seconds so the sync worker can run. If it still does not sync, sign out/sign in or contact support — the queued data is still stored locally.',
//     tagsEn: ['offline', 'sync not working', 'queue not syncing', 'troubleshoot'],
//     categoryUr: 'ٹرَبل شوٹنگ',
//     questionUr: 'میری آف لائن انٹریاں سنک نہیں ہو رہیں، کیا چیک کروں؟',
//     answerUr:
//         'پہلے دیکھیں انٹرنیٹ واقعی آن ہے۔ پھر ایپ کھول کر چند سیکنڈ اسی اسکرین پر رہیں تاکہ سنک خود چلے۔ اگر پھر بھی سنک نہ ہو تو سائن آؤٹ/سائن اِن کریں یا سپورٹ سے رابطہ کریں — قطار میں موجود ڈیٹا لوکل میں محفوظ رہتا ہے۔',
//     tagsUr: ['آف لائن', 'سنک نہیں ہو رہا', 'قطار سنک نہیں', 'مسئلہ'],
//   ),

//   // 🔽 your existing FAQs continue here…
//   FaqItem(
//     id: 'ov_what_is_motives',
//     categoryEn: 'Overview',
//     questionEn: 'What is Motives?',
//     answerEn:
//         'Motives is a field-sales app for distributors to capture shop orders according to a journey plan. Riders mark attendance, start the route, then visit shops to check-in, take orders, collect payments, mark No-Visit with a reason, or put shops on Hold. You cannot end the route until the journey plan is completed.',
//     tagsEn: ['motives', 'overview', 'what is', 'distributor app', 'field sales', 'route'],
//     categoryUr: 'جائزہ',
//     questionUr: 'موٹیوز کیا ہے؟',
//     answerUr:
//         'موٹیوز ڈسٹری بیوٹرز کے لئے فیلڈ سیلز ایپ ہے جس سے جرنی پلان کے مطابق دکانوں کے آرڈر لیے جاتے ہیں۔ رائیڈر حاضری لگاتا ہے، روٹ شروع کرتا ہے، پھر دکان پر چیک اِن، آرڈر، پیمنٹ، نو وِزٹ (وجہ کے ساتھ) یا ہولڈ کرتا ہے۔ جرنی پلان مکمل ہونے سے پہلے روٹ ختم نہیں کیا جا سکتا۔',
//     tagsUr: ['موٹیوز', 'جائزہ', 'کیا ہے', 'ڈسٹری بیوٹر', 'فیلڈ سیلز', 'روٹ'],
//   ),
//   FaqItem(
//     id: 'ov_what_is_motives',
//     categoryEn: 'Overview',
//     questionEn: 'What is Motives?',
//     answerEn:
//         'Motives is a field-sales app for distributors to capture shop orders according to a journey plan. Riders mark attendance, start the route, then visit shops to check-in, take orders, collect payments, mark No-Visit with a reason, or put shops on Hold. You cannot end the route until the journey plan is completed.',
//     tagsEn: ['motives', 'overview', 'what is', 'distributor app', 'field sales', 'route'],
//     categoryUr: 'جائزہ',
//     questionUr: 'موٹیوز کیا ہے؟',
//     answerUr:
//         'موٹیوز ڈسٹری بیوٹرز کے لئے فیلڈ سیلز ایپ ہے جس سے جرنی پلان کے مطابق دکانوں کے آرڈر لیے جاتے ہیں۔ رائیڈر حاضری لگاتا ہے، روٹ شروع کرتا ہے، پھر دکان پر چیک اِن، آرڈر، پیمنٹ، نو وِزٹ (وجہ کے ساتھ) یا ہولڈ کرتا ہے۔ جرنی پلان مکمل ہونے سے پہلے روٹ ختم نہیں کیا جا سکتا۔',
//     tagsUr: ['موٹیوز', 'جائزہ', 'کیا ہے', 'ڈسٹری بیوٹر', 'فیلڈ سیلز', 'روٹ'],
//   ),
//   FaqItem(
//     id: 'route_flow',
//     categoryEn: 'Attendance & Route',
//     questionEn: 'What is the correct daily flow: attendance, route, and visits?',
//     answerEn:
//         '1) Mark Attendance → 2) Start Route → 3) Visit shops in order → 4) At each shop: Check-In first, then take an action (Order / Collect Payment / No-Visit with reason / Hold). Repeat until all shops in the journey plan are handled.',
//     tagsEn: ['attendance', 'start route', 'flow', 'daily', 'visit order'],
//     categoryUr: 'حاضری اور روٹ',
//     questionUr: 'روزانہ کا درست طریقہ کیا ہے: حاضری، روٹ اور وزٹس؟',
//     answerUr:
//         '1) حاضری لگائیں → 2) روٹ شروع کریں → 3) ترتیب کے مطابق دکانوں پر جائیں → 4) ہر دکان پر پہلے چیک اِن کریں، پھر ایکشن کریں (آرڈر / پیمنٹ / نو وِزٹ وجہ کے ساتھ / ہولڈ)۔ یہ عمل تب تک دہرائیں جب تک جرنی پلان مکمل نہ ہو۔',
//     tagsUr: ['حاضری', 'روٹ شروع', 'طریقہ', 'روزانہ', 'وزٹ ترتیب'],
//   ),
//   FaqItem(
//     id: 'cant_end_route',
//     categoryEn: 'Attendance & Route',
//     questionEn: "Why can't I end the route yet?",
//     answerEn:
//         'You can’t end the route until the full journey plan is covered. Make sure every shop in the current plan is handled (Order Done, No-Visit with reason, or Hold as needed) and you are checked-out from the last visited shop.',
//     tagsEn: ['end route', 'cannot end', 'journey plan complete', 'block'],
//     categoryUr: 'حاضری اور روٹ',
//     questionUr: 'میں روٹ ابھی ختم کیوں نہیں کر پا رہا/رہی؟',
//     answerUr:
//         'جب تک مکمل جرنی پلان کور نہ ہو، روٹ ختم نہیں کیا جا سکتا۔ موجودہ پلان کی ہر دکان پر ایکشن مکمل کریں (آرڈر ڈن، نو وِزٹ وجہ کے ساتھ، یا ہولڈ) اور آخری وزٹ کی دکان سے چیک آؤٹ یقینی بنائیں۔',
//     tagsUr: ['روٹ ختم', 'اختتام نہیں', 'جرنی پلان مکمل', 'بلاک'],
//   ),
//   FaqItem(
//     id: 'checkin_first',
//     categoryEn: 'Visits & Reasons',
//     questionEn: 'Do I need to Check-In before taking any action at a shop?',
//     answerEn:
//         'Yes. Check-In is required before taking orders, collecting payments, or selecting reasons (No-Visit/Hold).',
//     tagsEn: ['check in', 'required', 'visit', 'reason', 'hold', 'no visit'],
//     categoryUr: 'وزٹس اور وجوہات',
//     questionUr: 'کیا دکان پر کسی بھی ایکشن سے پہلے چیک اِن ضروری ہے؟',
//     answerUr:
//         'جی ہاں۔ آرڈر لینے، پیمنٹ جمع کرنے یا وجوہات (نو وِزٹ/ہولڈ) منتخب کرنے سے پہلے چیک اِن لازمی ہے۔',
//     tagsUr: ['چیک اِن', 'ضروری', 'وزٹ', 'وجہ', 'ہولڈ', 'نو وزٹ'],
//   ),
//   FaqItem(
//     id: 'hold_shop',
//     categoryEn: 'Visits & Reasons',
//     questionEn: 'When should I mark a shop as Hold?',
//     answerEn:
//         'Use Hold when the owner is unavailable or the shop is temporarily closed. You can move to the next shop and return later.',
//     tagsEn: ['hold', 'unavailable', 'closed', 'reason', 'pause'],
//     categoryUr: 'وزٹس اور وجوہات',
//     questionUr: 'دکان کو ہولڈ کب مارک کروں؟',
//     answerUr:
//         'جب مالک موجود نہ ہو یا دکان عارضی طور پر بند ہو تو ہولڈ کریں۔ آپ اگلی دکان پر جا سکتے ہیں اور بعد میں واپس آ سکتے ہیں۔',
//     tagsUr: ['ہولڈ', 'غیر موجود', 'بند', 'وجہ', 'وقفہ'],
//   ),
//   FaqItem(
//     id: 'no_visit_reason',
//     categoryEn: 'Visits & Reasons',
//     questionEn: 'How do I mark No-Visit with a reason?',
//     answerEn:
//         'After Check-In, choose No-Visit and select the appropriate reason from the list, then proceed to the next shop.',
//     tagsEn: ['no visit', 'reason', 'visit', 'skip'],
//     categoryUr: 'وزٹس اور وجوہات',
//     questionUr: 'نو وِزٹ وجہ کے ساتھ کیسے مارک کروں؟',
//     answerUr:
//         'چیک اِن کے بعد نو وِزٹ منتخب کریں اور فہرست میں سے موزوں وجہ چنیں، پھر اگلی دکان پر جائیں۔',
//     tagsUr: ['نو وزٹ', 'وجہ', 'وزٹ', 'اسکپ'],
//   ),
//   FaqItem(
//     id: 'place_order',
//     categoryEn: 'Orders',
//     questionEn: 'How do I take/place an order after Check-In?',
//     answerEn:
//         'From Order Menu, open Products, add items, and in “My List” press “Confirm & Send”. On success, the shop becomes “Order Done”, you’re checked-out locally, and covered routes increment.',
//     tagsEn: ['order', 'take order', 'products', 'confirm & send', 'order done'],
//     categoryUr: 'آرڈرز',
//     questionUr: 'چیک اِن کے بعد آرڈر کیسے لوں/کروں؟',
//     answerUr:
//         'آرڈر مینو سے “Products” کھولیں، آئٹمز شامل کریں، پھر “My List” میں “Confirm & Send” دبائیں۔ کامیابی پر دکان “Order Done” ہو جاتی ہے، مقامی طور پر چیک آؤٹ ہو جاتا ہے اور کورڈ روٹس کی گنتی بڑھتی ہے۔',
//     tagsUr: ['آرڈر', 'پروڈکٹس', 'کنفرم سینڈ', 'آرڈر ڈن'],
//   ),
//   FaqItem(
//     id: 'brand_filter',
//     categoryEn: 'Orders',
//     questionEn: 'Can I filter by brand to speed up ordering?',
//     answerEn:
//         'Yes. Use the brand chips at the top of the catalog and Search to quickly narrow down items.',
//     tagsEn: ['brand', 'filter', 'catalog', 'chips', 'search'],
//     categoryUr: 'آرڈرز',
//     questionUr: 'کیا میں برانڈ فلٹر سے آرڈر تیز بنا سکتا/سکتی ہوں؟',
//     answerUr:
//         'جی ہاں۔ کیٹلاگ کے اوپر برانڈ چپس اور سرچ استعمال کریں تاکہ آئٹمز تیزی سے شارٹ لسٹ ہوں۔',
//     tagsUr: ['برانڈ', 'فلٹر', 'کیٹلاگ', 'چپس', 'سرچ'],
//   ),
//   FaqItem(
//     id: 'collect_payment',
//     categoryEn: 'Payments',
//     questionEn: 'Can I collect payment after Check-In?',
//     answerEn:
//         'If your account has invoice/collection rights, open “Collect Payment” from the Order Menu and follow on-screen steps.',
//     tagsEn: ['payment', 'collect', 'invoice', 'rights', 'check in'],
//     categoryUr: 'ادائیگیاں',
//     questionUr: 'کیا چیک اِن کے بعد پیمنٹ جمع کر سکتا/سکتی ہوں؟',
//     answerUr:
//         'اگر آپ کے اکاؤنٹ میں ان وائس/کلیکشن کی اجازت ہے تو “Order Menu” سے “Collect Payment” کھولیں اور ہدایات پر عمل کریں۔',
//     tagsUr: ['پیمنٹ', 'کلیکٹ', 'ان وائس', 'رائٹس', 'چیک اِن'],
//   ),
//   FaqItem(
//     id: 'area_based_plan',
//     categoryEn: 'Journey Plan',
//     questionEn: 'How does the area-based journey plan help?',
//     answerEn:
//         'Shops are grouped by area so you can cover nearby stops in one visit. Use the area filter in Journey Plan to focus and finish faster.',
//     tagsEn: ['journey plan', 'area', 'filter', 'efficiency', 'nearby'],
//     categoryUr: 'جرنی پلان',
//     questionUr: 'ایریا بیسڈ جرنی پلان کیسے مدد دیتا ہے؟',
//     answerUr:
//         'دکانیں ایریا کے لحاظ سے گروپ ہوتی ہیں تاکہ ایک ہی وزٹ میں قریبی جگہیں کور ہو جائیں۔ جرنی پلان میں ایریا فلٹر استعمال کریں اور کام جلد مکمل کریں۔',
//     tagsUr: ['جرنی پلان', 'ایریا', 'فلٹر', 'موثر', 'قریب'],
//   ),
//   FaqItem(
//     id: 'after_success_order',
//     categoryEn: 'Journey Plan',
//     questionEn: 'What happens after a successful order?',
//     answerEn:
//         'The shop is marked “Order Done”, local checkout is performed, and your covered-routes/visited count increases so you can continue to the next shop.',
//     tagsEn: ['order done', 'visited', 'covered routes', 'checkout'],
//     categoryUr: 'جرنی پلان',
//     questionUr: 'کامیاب آرڈر کے بعد کیا ہوتا ہے؟',
//     answerUr:
//         'دکان “Order Done” ہو جاتی ہے، مقامی چیک آؤٹ ہو جاتا ہے، اور کورڈ روٹس/وزٹڈ کاؤنٹ بڑھ جاتا ہے تاکہ آپ اگلی دکان پر چل سکیں۔',
//     tagsUr: ['آرڈر ڈن', 'وزٹڈ', 'کورڈ روٹس', 'چیک آؤٹ'],
//   ),
//   FaqItem(
//     id: 'order_fail',
//     categoryEn: 'Troubleshooting',
//     questionEn: 'Why did my order fail to submit?',
//     answerEn:
//         'Common causes: no network, missing user/distributor, or server maintenance. Check internet and retry. If it persists, contact support.',
//     tagsEn: ['error', 'fail', 'submit', 'network', 'server'],
//     categoryUr: 'ٹرَبل شوٹنگ',
//     questionUr: 'میرا آرڈر سبمٹ کیوں نہیں ہوا؟',
//     answerUr:
//         'عام وجوہات: انٹرنیٹ نہیں، یوزر/ڈسٹری بیوٹر کی معلومات نہیں، یا سرور مینٹیننس۔ نیٹ چیک کریں اور دوبارہ کوشش کریں۔ مسئلہ برقرار رہے تو سپورٹ سے رابطہ کریں۔',
//     tagsUr: ['خرابی', 'ناکام', 'نیٹ ورک', 'سرور', 'سبمٹ'],
//   ),
//   FaqItem(
//     id: 'not_syncing',
//     categoryEn: 'App',
//     questionEn: 'The app isn’t syncing my actions.',
//     answerEn:
//         'If you’re offline, actions queue and sync when online. Keep the app open for a few seconds after internet returns.',
//     tagsEn: ['offline', 'sync', 'queue', 'online'],
//     categoryUr: 'ایپ',
//     questionUr: 'ایپ میری کارروائیاں سنک نہیں کر رہی۔',
//     answerUr:
//         'آف لائن ہونے پر ایکشن قطار میں لگتے ہیں اور آن لائن ہوتے ہی سنک ہو جاتے ہیں۔ انٹرنیٹ آنے کے بعد کچھ سیکنڈ ایپ کھلی رکھیں۔',
//     tagsUr: ['آف لائن', 'سنک', 'قطار', 'آن لائن'],
//   ),
// ];

// // ---------- SYNONYMS ----------
// const Map<String, List<String>> _synEn = {
//   'buy': ['purchase', 'order', 'checkout', 'confirm', 'send'],
//   'order': ['buy', 'purchase', 'cart', 'bag', 'list'],
//   'cart': ['bag', 'basket', 'list'],
//   'records': ['history', 'previous', 'past'],
//   'payment': ['pay', 'invoice', 'collect'],
//   'checkin': ['check in', 'check-in', 'visit'],
//   'checkout': ['check out', 'check-out', 'leave'],
//   'gps': ['location', 'map', 'blue dot'],
//   'error': ['fail', 'failure', 'issue', 'problem'],
//   'route': ['journey', 'trip', 'path'],
//   'end route': ['finish route', 'close route', 'complete route'],
//   'area': ['region', 'zone', 'locality', 'nearby'],
//   'brand': ['line', 'label', 'company'],
// };

// const Map<String, List<String>> _synUr = {
//   'آرڈر': ['خرید', 'سبمٹ', 'کنفرم', 'سینڈ', 'کارٹ', 'بیگ', 'فہرست'],
//   'کارٹ': ['بیگ', 'فہرست'],
//   'ریکارڈز': ['ہسٹری', 'پرانے آرڈر'],
//   'ادائیگی': ['پیمنٹ', 'بل', 'ان وائس', 'کلیکٹ'],
//   'چیک اِن': ['چیک ان', 'حاضری', 'وزٹ شروع'],
//   'چیک آؤٹ': ['چیک اوٹ', 'نکلنا', 'وزٹ ختم'],
//   'لوکیشن': ['جی پی ایس', 'نقشہ', 'بلیو ڈاٹ'],
//   'خرابی': ['مسئلہ', 'ناکامی'],
//   'ہولڈ': ['وقفہ', 'عارضی روک'],
//   'نو وزٹ': ['کوئی وزٹ نہیں', 'وزٹ نہیں'],
//   'روٹ': ['جرنی', 'سفر', 'راستہ'],
//   'اختتام': ['ختم', 'بند', 'مکمل'],
//   'ایریا': ['علاقہ', 'زون', 'قرب و جوار'],
//   'برانڈ': ['لائن', 'کمپنی', 'لیبل'],
// };

// // ---------- PREFS / STORE ----------
// class FaqPrefs {
//   final _box = GetStorage();
//   FaqLang getLang() {
//     final s = (_box.read('smartfaq_lang') as String?) ?? 'en';
//     return s == 'ur' ? FaqLang.ur : FaqLang.en;
//   }
//   Future<void> setLang(FaqLang l) => _box.write('smartfaq_lang', l.code);
// }

// class FaqStore {
//   static final FaqStore _i = FaqStore._();
//   FaqStore._();
//   factory FaqStore() => _i;

//   final _box = GetStorage();

//   String _histKey(FaqLang l) => 'smartfaq_history_${l.code}';
//   String get _fbKey => 'smartfaq_feedback';

//   Map<String, dynamic> _fb() => _box.read(_fbKey) as Map<String, dynamic>? ?? {};

//   void thumbUp(String id) {
//     final fb = Map<String, dynamic>.from(_fb());
//     final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
//     rec['up'] = (rec['up'] ?? 0) + 1;
//     fb[id] = rec;
//     _box.write(_fbKey, fb);
//   }

//   void thumbDown(String id) {
//     final fb = Map<String, dynamic>.from(_fb());
//     final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
//     rec['down'] = (rec['down'] ?? 0) + 1;
//     fb[id] = rec;
//     _box.write(_fbKey, fb);
//   }

//   List<ChatMessage> loadHistory(FaqLang lang) {
//     final raw = _box.read(_histKey(lang)) as String?;
//     if (raw == null || raw.isEmpty) return const [];
//     try {
//       final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
//       return list.map(ChatMessage.fromJson).toList();
//     } catch (_) {
//       return const [];
//     }
//   }

//   Future<void> saveHistory(FaqLang lang, List<ChatMessage> msgs) async {
//     final payload = jsonEncode(msgs.map((e) => e.toJson()).toList());
//     await _box.write(_histKey(lang), payload);
//   }

//   Future<void> clearHistory(FaqLang lang) => _box.remove(_histKey(lang));
// }

// // ---------- ENGINE ----------
// class FaqEngine {
//   final List<FaqItem> data;
//   FaqLang _lang;
//   final Map<String, int> _df = {};
//   late int _n;

//   FaqEngine(this.data, this._lang) {
//     _rebuild();
//   }

//   void setLang(FaqLang l) {
//     if (_lang == l) return;
//     _lang = l;
//     _rebuild();
//   }

//   void _rebuild() {
//     _df.clear();
//     _n = data.length;
//     for (final f in data) {
//       final terms = _terms(f.question(_lang)).toSet();
//       for (final t in terms) {
//         _df[t] = (_df[t] ?? 0) + 1;
//       }
//       for (final tag in f.tags(_lang)) {
//         final t = _norm(tag);
//         _df[t] = (_df[t] ?? 0) + 1;
//       }
//     }
//   }

//   String _norm(String s) {
//     final cleaned = s
//         .toLowerCase()
//         .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//     return cleaned;
//   }

//   List<String> _terms(String s) =>
//       _norm(s).split(' ').where((e) => e.isNotEmpty).toList();

//   List<String> _expandSynonyms(List<String> tokens) {
//     final out = <String>[];
//     final map = _lang == FaqLang.en ? _synEn : _synUr;
//     for (final t in tokens) {
//       out.add(t);
//       map.forEach((k, vals) {
//         if (t == k || vals.contains(t)) {
//           out.add(k);
//           out.addAll(vals);
//         }
//       });
//     }
//     return out.toSet().toList();
//   }

//   double _idf(String term) {
//     final df = _df[term] ?? 1;
//     return log((_n + 1) / df);
//   }

//   int _lev(String a, String b) {
//     if (a.isEmpty) return b.length;
//     if (b.isEmpty) return a.length;
//     final m = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
//     for (var i = 0; i <= a.length; i++) m[i][0] = i;
//     for (var j = 0; j <= b.length; j++) m[0][j] = j;
//     for (var i = 1; i <= a.length; i++) {
//       for (var j = 1; j <= b.length; j++) {
//         final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
//         m[i][j] = [
//           m[i - 1][j] + 1,
//           m[i][j - 1] + 1,
//           m[i - 1][j - 1] + cost,
//         ].reduce(min);
//       }
//     }
//     return m[a.length][b.length];
//   }

//   double _fuzzySim(String q, String s) {
//     final a = _norm(q);
//     final b = _norm(s);
//     if (a.isEmpty || b.isEmpty) return 0;
//     final d = _lev(a, b).toDouble();
//     final mx = max(a.length, b.length).toDouble();
//     return 1.0 - (d / mx);
//   }

//   double _score(String query, FaqItem f) {
//     final qTokens = _expandSynonyms(_terms(query));
//     final qSet = qTokens.toSet();

//     final titleTokens = _terms(f.question(_lang));
//     final titleSet = titleTokens.toSet();

//     final tagsSet = f.tags(_lang).map(_norm).toSet();

//     double overlap = 0;
//     for (final t in qSet) {
//       if (titleSet.contains(t) || tagsSet.contains(t)) {
//         overlap += _idf(t);
//       }
//     }

//     final fuzzy = _fuzzySim(query, f.question(_lang));
//     final tagBoost = qSet.intersection(tagsSet).isNotEmpty ? 1.0 : 0.0;

//     return 0.6 * overlap + 0.25 * fuzzy + 0.15 * tagBoost;
//   }

//   List<FaqItem> find(String query, {int topK = 4}) {
//     if (query.trim().isEmpty) return const <FaqItem>[];
//     final scored = <(FaqItem, double)>[];
//     for (final f in data) {
//       final s = _score(query, f);
//       if (s > 0) scored.add((f, s));
//     }
//     scored.sort((a, b) => b.$2.compareTo(a.$2));
//     return scored.take(topK).map((e) => e.$1).toList();
//   }

//   List<String> suggestionsFor(FaqItem picked, {int max = 5}) {
//     final sameCat = data
//         .where((e) => e.category(_lang) == picked.category(_lang) && e.id != picked.id)
//         .toList();
//     return sameCat.take(max).map((e) => e.question(_lang)).toList();
//   }

//   List<String> starterSuggestions({int max = 8}) {
//     final qs = data.map((e) => e.question(_lang)).toSet().toList();
//     qs.shuffle(Random());
//     return qs.take(max).toList();
//   }

//   List<String> categories() {
//     final s = data.map((e) => e.category(_lang)).toSet().toList();
//     s.sort();
//     return s;
//   }

//   List<String> questionsInCategory(String cat, {int max = 10}) =>
//       data.where((e) => e.category(_lang) == cat).map((e) => e.question(_lang)).take(max).toList();

//   FaqLang get lang => _lang;
// }

// // ---------- LOCALIZATION ----------
// class L10n {
//   final FaqLang lang;
//   const L10n(this.lang);

//   String get appTitle => lang == FaqLang.en ? 'Smart FAQs' : 'سمارٹ سوالات';
//   String get clearChat => lang == FaqLang.en ? 'Clear chat' : 'چیٹ صاف کریں';
//   String get askHint => lang == FaqLang.en
//       ? 'Ask a question (e.g., “How do I take an order?”)'
//       : 'سوال پوچھیں (مثلاً: “آرڈر کیسے لوں؟”)';
//   String get ask => lang == FaqLang.en ? 'Ask' : 'پوچھیں';
//   String get welcome =>
//       lang == FaqLang.en
//           ? 'Hi! Ask me anything about Orders, Route, or Payments. Tap a suggestion below to start.'
//           : 'سلام! آرڈرز، روٹ یا ادائیگی سے متعلق کچھ بھی پوچھیں۔ شروع کرنے کیلئے نیچے سے کوئی سجیشن چنیں۔';
//   String get thanks => lang == FaqLang.en ? 'Thanks for the feedback!' : 'فیڈبیک کا شکریہ!';
//   String get noted => lang == FaqLang.en ? 'Noted. We’ll improve these answers.' : 'موصول ہوا۔ ہم ان جوابات کو بہتر بنائیں گے۔';
//   String get copied => lang == FaqLang.en ? 'Answer copied to clipboard' : 'جواب کاپی ہو گیا';
//   String get couldntFind =>
//       lang == FaqLang.en
//           ? "I couldn't find an exact answer, but try these or rephrase your question:"
//           : 'ٹھیک جواب نہیں ملا، یہ آزمائیں یا سوال تھوڑا بدل دیں:';
//   String get en => 'EN';
//   String get ur => 'اردو';
// }

// // ---------- SCREEN ----------
// class SmartFaqChatBilingual extends StatefulWidget {
//   const SmartFaqChatBilingual({super.key, this.onOpen});
//   final VoidCallback? onOpen;

//   @override
//   State<SmartFaqChatBilingual> createState() => _SmartFaqChatBilingualState();
// }

// class _SmartFaqChatBilingualState extends State<SmartFaqChatBilingual> {
//   final _store = FaqStore();
//   final _prefs = FaqPrefs();
//   final _ctl = TextEditingController();
//   final _scroll = ScrollController();

//   late FaqEngine _engine;
//   late FaqLang _lang;
//   late L10n _t;

//   List<ChatMessage> _messages = [];
//   bool _typing = false;
//   String? _selectedCategory;

//   @override
//   void initState() {
//     super.initState();
//     widget.onOpen?.call();
//     _lang = _prefs.getLang();
//     _t = L10n(_lang);
//     _engine = FaqEngine(_faqs, _lang);
//     _messages = _store.loadHistory(_lang);
//     if (_messages.isEmpty) _seedWelcome();
//   }

//   void _seedWelcome() {
//     final starters = _engine.starterSuggestions();
//     _messages = [
//       ChatMessage(
//         id: 'm0',
//         role: ChatRole.bot,
//         text: _t.welcome,
//         ts: DateTime.now(),
//         suggestions: starters,
//       )
//     ];
//   }

//   @override
//   void dispose() {
//     _ctl.dispose();
//     _scroll.dispose();
//     super.dispose();
//   }

//   Future<void> _save() => _store.saveHistory(_lang, _messages);

//   void _jumpToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scroll.hasClients) {
//         _scroll.animateTo(
//           _scroll.position.maxScrollExtent + 120,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Future<void> _onSend(String raw) async {
//     final text = raw.trim();
//     if (text.isEmpty) return;

//     setState(() {
//       _messages.add(ChatMessage(
//         id: 'u${DateTime.now().microsecondsSinceEpoch}',
//         role: ChatRole.user,
//         text: text,
//         ts: DateTime.now(),
//       ));
//       _typing = true;
//     });
//     _ctl.clear();
//     _jumpToBottom();

//     await Future.delayed(const Duration(milliseconds: 350));

//     final hits = _engine.find(text, topK: 4);
//     ChatMessage reply;

//     if (hits.isEmpty) {
//       final alts = _engine.starterSuggestions();
//       reply = ChatMessage(
//         id: 'b${DateTime.now().microsecondsSinceEpoch}',
//         role: ChatRole.bot,
//         text: _t.couldntFind,
//         ts: DateTime.now(),
//         suggestions: alts.take(6).toList(),
//       );
//     } else {
//       final top = hits.first;
//       final related = _engine.suggestionsFor(top, max: 5);
//       reply = ChatMessage(
//         id: 'b${DateTime.now().microsecondsSinceEpoch}',
//         role: ChatRole.bot,
//         text: top.answer(_lang),
//         ts: DateTime.now(),
//         suggestions: related,
//       );
//     }

//     setState(() {
//       _messages.add(reply);
//       _typing = false;
//     });
//     _jumpToBottom();
//     await _save();
//   }

//   Future<void> _onTapSuggestion(String q) async {
//     _ctl.text = q;
//     await _onSend(q);
//   }

//   void _onThumbUp(ChatMessage botMsg) {
//     final item = _faqs.firstWhere(
//       (f) => f.answer(_lang) == botMsg.text,
//       orElse: () => const FaqItem(
//         id: 'unknown',
//         categoryEn: '',
//         questionEn: '',
//         answerEn: '',
//         tagsEn: [],
//         categoryUr: '',
//         questionUr: '',
//         answerUr: '',
//         tagsUr: [],
//       ),
//     );
//     if (item.id != 'unknown') _store.thumbUp(item.id);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.thanks)));
//   }

//   void _onThumbDown(ChatMessage botMsg) {
//     final item = _faqs.firstWhere(
//       (f) => f.answer(_lang) == botMsg.text,
//       orElse: () => const FaqItem(
//         id: 'unknown',
//         categoryEn: '',
//         questionEn: '',
//         answerEn: '',
//         tagsEn: [],
//         categoryUr: '',
//         questionUr: '',
//         answerUr: '',
//         tagsUr: [],
//       ),
//     );
//     if (item.id != 'unknown') _store.thumbDown(item.id);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.noted)));
//   }

//   Future<void> _clearHistory() async {
//     await _store.clearHistory(_lang);
//     setState(() => _seedWelcome());
//   }

//   Future<void> _switchLang(FaqLang lang) async {
//     if (_lang == lang) return;
//     await _prefs.setLang(lang);
//     setState(() {
//       _lang = lang;
//       _t = L10n(_lang);
//       _engine.setLang(_lang);
//       _selectedCategory = null;
//       _messages = _store.loadHistory(_lang);
//       if (_messages.isEmpty) _seedWelcome();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;
//     final cats = _engine.categories();
//     final catSuggestions = _selectedCategory == null
//         ? _engine.starterSuggestions()
//         : _engine.questionsInCategory(_selectedCategory!);

//     return Directionality(
//       textDirection: _lang.dir,
//       child: Scaffold(
//         // keep scaffold background so app still looks consistent outside body
//         backgroundColor: _kBg,
//       /*  appBar: AppBar(
//           backgroundColor: _kCard,
//           elevation: 0,
//           title: Text(
//             _t.appTitle,
//             style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
//           ),
//           actions: [
//             _LangToggle(
//               lang: _lang,
//               onChanged: _switchLang,
//               t: _t,
//             ),
//             IconButton(
//               tooltip: _t.clearChat,
//               onPressed: _clearHistory,
//               icon: const Icon(Icons.delete_outline, color: _kMuted),
//             ),
//           ],
//         ),*/
//         // ✅ UI-only update: watermark behind the chat content
//         body: Stack(
//           children: [
//              WatermarkTiledSmall(tileScale: 3.0),

//           //    Positioned(
//           //     top: 250,
//           //     child: Row(
//           //     children: [
//           //       Text(
//           //   _t.appTitle,
//           //   style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
//           // ),
          
//           //   _LangToggle(
//           //     lang: _lang,
//           //     onChanged: _switchLang,
//           //     t: _t,
//           //   ),
//           //   IconButton(
//           //     tooltip: _t.clearChat,
//           //     onPressed: _clearHistory,
//           //     icon: const Icon(Icons.delete_outline, color: _kMuted),
//           //   ),
//           //     ],
//           //    )),

//             // Foreground content (unchanged logic)
//             Column(
//               children: [
//                 SizedBox(height: 40,),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [

//                 Text(
//             _t.appTitle,
//             style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText),
//           ),
          
//             _LangToggle(
//               lang: _lang,
//               onChanged: _switchLang,
//               t: _t,
//             ),
//             IconButton(
//               tooltip: _t.clearChat,
//               onPressed: _clearHistory,
//               icon: const Icon(Icons.delete_outline, color: _kMuted),
//             ),
//               ],
//              ),
//                 // Category filter + suggestion chips (opaque so watermark peeks around)
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
//                   color: _kCard,
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         height: 40,
//                         child: ListView.separated(
//                           scrollDirection: Axis.horizontal,
//                           reverse: _lang == FaqLang.ur,
//                           itemCount: cats.length + 1,
//                           separatorBuilder: (_, __) => const SizedBox(width: 8),
//                           itemBuilder: (_, i) {
//                             final label = (i == 0)
//                                 ? (_lang == FaqLang.en ? 'All' : 'تمام')
//                                 : cats[i - 1];
//                             final sel = (i == 0 && _selectedCategory == null) ||
//                                 (i > 0 && _selectedCategory == label);
//                             return ChoiceChip(
//                               label: Text(label, overflow: TextOverflow.ellipsis),
//                               selected: sel,
//                               onSelected: (_) {
//                                 setState(() {
//                                   _selectedCategory = (i == 0) ? null : label;
//                                 });
//                               },
//                               selectedColor: _kAccent,
//                               labelStyle: TextStyle(
//                                 color: sel ? Colors.white : _kText,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                               backgroundColor: Colors.white,
//                               shape: StadiumBorder(
//                                 side: BorderSide(
//                                   color: sel ? Colors.transparent : const Color(0xFFEDEFF2),
//                                 ),
//                               ),
//                               elevation: sel ? 1 : 0,
//                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       SizedBox(
//                         height: 34,
//                         child: ListView.separated(
//                           scrollDirection: Axis.horizontal,
//                           reverse: _lang == FaqLang.ur,
//                           itemCount: catSuggestions.length.clamp(0, 12),
//                           separatorBuilder: (_, __) => const SizedBox(width: 8),
//                           itemBuilder: (_, i) {
//                             final q = catSuggestions[i];
//                             return ActionChip(
//                               label: Text(q, maxLines: 1, overflow: TextOverflow.ellipsis),
//                               onPressed: () => _onTapSuggestion(q),
//                               backgroundColor: Colors.white,
//                               side: const BorderSide(color: Color(0xFFEDEFF2)),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Chat list (transparent to show watermark in the canvas area)
//                 Expanded(
//                   child: ListView.builder(
//                     controller: _scroll,
//                     padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
//                     itemCount: _messages.length + (_typing ? 1 : 0),
//                     itemBuilder: (_, i) {
//                       if (_typing && i == _messages.length) {
//                         return const _TypingBubble();
//                       }
//                       final m = _messages[i];
//                       final isUser = m.role == ChatRole.user;
//                       return Column(
//                         crossAxisAlignment:
//                             isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                         children: [
//                           Align(
//                             alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                             child: _ChatBubble(
//                               isUser: isUser,
//                               text: m.text,
//                               onCopy: () => Clipboard.setData(ClipboardData(text: m.text)),
//                               onShare: () => _share(context, m.text),
//                               onThumbUp: isUser ? null : () => _onThumbUp(m),
//                               onThumbDown: isUser ? null : () => _onThumbDown(m),
//                               textDirection: _lang.dir,
//                             ),
//                           ),
//                           if (!isUser && m.suggestions.isNotEmpty) ...[
//                             const SizedBox(height: 6),
//                             Wrap(
//                               spacing: 8,
//                               runSpacing: 6,
//                               alignment: _lang == FaqLang.ur ? WrapAlignment.end : WrapAlignment.start,
//                               children: m.suggestions.take(6).map((s) {
//                                 return ActionChip(
//                                   label: Text(
//                                     s,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   onPressed: () => _onTapSuggestion(s),
//                                   backgroundColor: Colors.white,
//                                   side: const BorderSide(color: Color(0xFFEDEFF2)),
//                                 );
//                               }).toList(),
//                             ),
//                           ],
//                           const SizedBox(height: 10),
//                         ],
//                       );
//                     },
//                   ),
//                 ),

//                 // Composer (opaque white strip; watermark stays behind)
//                 Container(
//                   padding: const EdgeInsets.fromLTRB(12, 8, 12, 52),
//                   decoration: const BoxDecoration(
//                     color: _kCard,
//                     boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, -2))],
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             border: Border.all(color: const Color(0xFFEDEFF2)),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: TextField(
//                             controller: _ctl,
//                             textInputAction: TextInputAction.send,
//                             onSubmitted: _onSend,
//                             textDirection: _lang.dir,
//                             decoration: InputDecoration(
//                               border: InputBorder.none,
//                               hintText: _t.askHint,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton.icon(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _kAccent,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//                         ),
//                         onPressed: () => _onSend(_ctl.text),
//                         icon: const Icon(Icons.send_rounded, size: 18),
//                         label: Text(_t.ask),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _share(BuildContext context, String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t.copied)));
//   }
// }

// // ---------- LANG TOGGLE WIDGET ----------
// class _LangToggle extends StatelessWidget {
//   const _LangToggle({required this.lang, required this.onChanged, required this.t});
//   final FaqLang lang;
//   final ValueChanged<FaqLang> onChanged;
//   final L10n t;

//   @override
//   Widget build(BuildContext context) {
//     final selEn = lang == FaqLang.en;
//     final selUr = lang == FaqLang.ur;
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//       padding: const EdgeInsets.all(2),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color(0xFFEDEFF2)),
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         _segBtn(label: t.en, selected: selEn, onTap: () => onChanged(FaqLang.en)),
//         _segBtn(label: t.ur, selected: selUr, onTap: () => onChanged(FaqLang.ur)),
//       ]),
//     );
//   }

//   Widget _segBtn({required String label, required bool selected, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(999),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: selected ? _kAccent : Colors.transparent,
//           borderRadius: BorderRadius.circular(999),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? Colors.white : _kText,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------- BUBBLES ----------
// class _ChatBubble extends StatelessWidget {
//   const _ChatBubble({
//     required this.isUser,
//     required this.text,
//     this.onCopy,
//     this.onShare,
//     this.onThumbUp,
//     this.onThumbDown,
//     required this.textDirection,
//   });

//   final bool isUser;
//   final String text;
//   final VoidCallback? onCopy;
//   final VoidCallback? onShare;
//   final VoidCallback? onThumbUp;
//   final VoidCallback? onThumbDown;
//   final TextDirection textDirection;

//   @override
//   Widget build(BuildContext context) {
//     final bubbleColor = isUser ? _kAccent : _kCard;
//     final textColor = isUser ? Colors.white : _kText;

//     return Container(
//       constraints: const BoxConstraints(maxWidth: 640),
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
//       decoration: BoxDecoration(
//         color: bubbleColor,
//         borderRadius: BorderRadius.only(
//           topLeft: const Radius.circular(14),
//           topRight: const Radius.circular(14),
//           bottomLeft: Radius.circular(isUser ? 14 : 4),
//           bottomRight: Radius.circular(isUser ? 4 : 14),
//         ),
//         border: isUser ? null : Border.all(color: const Color(0xFFEDEFF2)),
//         boxShadow: isUser
//             ? const []
//             : const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
//       ),
//       child: Directionality(
//         textDirection: textDirection,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SelectableText(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.28)),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (onCopy != null)
//                   _MiniIconButton(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy!),
//                 if (onShare != null) const SizedBox(width: 3),
//                 if (onShare != null)
//                   _MiniIconButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare!),
//                 if (onThumbUp != null || onThumbDown != null) const SizedBox(width: 3),
//                 if (onThumbUp != null)
//                   _MiniIconButton(icon: Icons.thumb_up_outlined, label: 'Helpful', onTap: onThumbUp!),
//                 if (onThumbDown != null) const SizedBox(width: 3),
//                 if (onThumbDown != null)
//                   _MiniIconButton(icon: Icons.thumb_down_outlined, label: 'Not helpful', onTap: onThumbDown!),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _MiniIconButton extends StatelessWidget {
//   const _MiniIconButton({required this.icon, required this.label, required this.onTap});
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final c = Theme.of(context).textTheme.bodySmall?.copyWith(color: _kMuted);
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           Icon(icon, size: 16, color: _kMuted),
//           const SizedBox(width: 4),
//           Text(label, style: c),
//         ]),
//       ),
//     );
//   }
// }

// class _TypingBubble extends StatelessWidget {
//   const _TypingBubble();

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0xFFEDEFF2)),
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(14),
//             topRight: Radius.circular(14),
//             bottomRight: Radius.circular(14),
//             bottomLeft: Radius.circular(4),
//           ),
//         ),
//         child: const _Dots(),
//       ),
//     );
//   }
// }

// class _Dots extends StatefulWidget {
//   const _Dots();

//   @override
//   State<_Dots> createState() => _DotsState();
// }

// class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
//   late final AnimationController _ctl;
//   @override
//   void initState() {
//     super.initState();
//     _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
//   }

//   @override
//   void dispose() {
//     _ctl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ctl,
//       builder: (_, __) {
//         final v = (sin(_ctl.value * 2 * pi) + 1) / 2;
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(3, (i) {
//             final s = 6.0 + (i == 0 ? v : i == 1 ? (1 - v) : v) * 3;
//             return Container(
//               width: s,
//               height: s,
//               margin: const EdgeInsets.symmetric(horizontal: 3),
//               decoration: const BoxDecoration(color: _kMuted, shape: BoxShape.circle),
//             );
//           }),
//         );
//       },
//     );
//   }
// }
