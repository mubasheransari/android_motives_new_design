// lib/features/smart_faq/smart_faq_chat.dart
// Drop-in Smart FAQ "AI-style" chat (offline). No external AI calls required.
//
// Dependencies:
//   flutter_bloc (only if you want to dispatch your GlobalBloc Activity; it's optional)
//   get_storage: ^2.1.1
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartFaqChatScreen()));
//
// Optional: If you use GlobalBloc to log Activity, pass `onOpen` callback.

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
const _kAccent = Color(0xFFEA7A3B); // matches your Meezan orange
const _kAccentLite = Color(0xFFFFB07A);

// ---------- MODELS ----------
enum ChatRole { user, bot }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime ts;
  final List<String> suggestions; // optional "follow-ups" under the bot message
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
        suggestions: (j['sug'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> tags;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'question': question,
        'answer': answer,
        'tags': tags,
      };

  static FaqItem fromJson(Map<String, dynamic> j) => FaqItem(
        id: j['id'].toString(),
        category: (j['category'] ?? '').toString(),
        question: (j['question'] ?? '').toString(),
        answer: (j['answer'] ?? '').toString(),
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

// ---------- DATA SOURCE (you can replace with assets/faqs.json) ----------
const _hardcodedFaqs = <FaqItem>[
  // Category: Orders
  FaqItem(
    id: 'orders_01',
    category: 'Orders',
    question: 'How do I place an order?',
    answer:
        'Open “Products”, tap items to add, then open your bag and press “Confirm & Send”. You’ll get a success toast and the order appears in Records.',
    tags: ['order', 'place', 'buy', 'cart', 'bag', 'confirm', 'send'],
  ),
  FaqItem(
    id: 'orders_02',
    category: 'Orders',
    question: 'Can I edit quantities before submitting?',
    answer:
        'Yes. In the “My List” screen use +/– on each line to adjust quantities before you press “Confirm & Send”.',
    tags: ['qty', 'quantity', 'change', 'update', 'edit', 'cart'],
  ),
  FaqItem(
    id: 'orders_03',
    category: 'Orders',
    question: 'Where can I see my previous orders?',
    answer:
        'Open the “Records” screen from the menu. The latest orders appear at the top with status and timestamp.',
    tags: ['history', 'records', 'previous', 'past', 'orders', 'status'],
  ),
  FaqItem(
    id: 'orders_04',
    category: 'Orders',
    question: 'Why did my order fail to submit?',
    answer:
        'Common causes: no network, missing user/distributor, or server maintenance. Re-check your internet and try again. If it persists, contact support.',
    tags: ['error', 'fail', 'submit', 'network', 'server'],
  ),

  // Category: Check-in / Route
  FaqItem(
    id: 'route_01',
    category: 'Route',
    question: 'How do I check in at a shop?',
    answer:
        'From “Order Menu” tap “Check In”. If location is required, allow location services. You must check in to take orders or mark reasons.',
    tags: ['check-in', 'shop', 'visit', 'location', 'gps', 'route'],
  ),
  FaqItem(
    id: 'route_02',
    category: 'Route',
    question: 'I need to check out — what should I do?',
    answer:
        'From “Order Menu” tap “Check Out”. If a reason is required, select HOLD or NO VISIT before checking out.',
    tags: ['check-out', 'reason', 'hold', 'no visit', 'route'],
  ),
  FaqItem(
    id: 'route_03',
    category: 'Route',
    question: 'What is “Order Done” on Journey Plan?',
    answer:
        'After a successful order, the app marks that shop with “Order Done”, checks you out locally, and increments covered routes.',
    tags: ['order done', 'journey plan', 'covered routes', 'label'],
  ),

  // Category: Payments
  FaqItem(
    id: 'pay_01',
    category: 'Payments',
    question: 'How do I pay for an order?',
    answer:
        'For this app flow, orders are submitted to your distributor — payments are collected per your business rules. If “Collect Payment” is enabled, open it from Order Menu.',
    tags: ['payment', 'pay', 'collect', 'invoice'],
  ),
  FaqItem(
    id: 'pay_02',
    category: 'Payments',
    question: 'Payment screen says not allowed.',
    answer:
        'You may not have rights to view invoices. Contact your admin to enable “markInvoices”.',
    tags: ['not allowed', 'rights', 'invoices', 'permission'],
  ),

  // Category: App / Account
  FaqItem(
    id: 'app_01',
    category: 'App',
    question: 'How do I reset my password?',
    answer:
        'Go to “Profile → Change Password”. Enter new and confirm passwords to update.',
    tags: ['password', 'reset', 'change', 'forgot'],
  ),
  FaqItem(
    id: 'app_02',
    category: 'App',
    question: 'The app isn’t syncing my actions.',
    answer:
        'If you’re offline, actions are queued. They’re synced once online automatically. Keep the app open for a few seconds after getting internet.',
    tags: ['offline', 'sync', 'queue', 'online'],
  ),
];

// ---------- SIMPLE SYNONYMS / LEMMAS ----------
const Map<String, List<String>> _synonyms = {
  'buy': ['purchase', 'order', 'checkout', 'confirm', 'send'],
  'order': ['buy', 'purchase', 'cart', 'bag'],
  'cart': ['bag', 'basket', 'list'],
  'records': ['history', 'previous', 'past'],
  'payment': ['pay', 'invoice', 'collect'],
  'checkin': ['check in', 'check-in', 'visit'],
  'checkout': ['check out', 'check-out', 'leave'],
  'gps': ['location', 'map', 'blue dot'],
  'error': ['fail', 'failure', 'issue', 'problem'],
};

// ---------- FAQ ENGINE (offline retrieval with fuzzy & synonyms) ----------
class FaqEngine {
  final List<FaqItem> data;
  final Map<String, int> _df = {}; // document frequency
  late final int _n;

  FaqEngine(this.data) {
    _n = data.length;
    _buildDf();
  }

  void _buildDf() {
    for (final f in data) {
      final terms = _terms(f.question).toSet();
      for (final t in terms) {
        _df[t] = (_df[t] ?? 0) + 1;
      }
      for (final tag in f.tags) {
        final t = _norm(tag);
        _df[t] = (_df[t] ?? 0) + 1;
      }
    }
  }

  // Normalize: lowercase, remove punctuation
  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  List<String> _terms(String s) => _norm(s).split(' ').where((e) => e.isNotEmpty).toList();

  List<String> _expandSynonyms(List<String> tokens) {
    final out = <String>[];
    for (final t in tokens) {
      out.add(t);
      _synonyms.forEach((k, vals) {
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

  // Simple edit distance for fuzzy score
  int _lev(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) m[i][0] = i;
    for (var j = 0; j <= b.length; j++) m[0][j] = j;
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
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
    return 1.0 - (d / mx); // 1.0 exact, 0.0 very different
  }

  // Score query vs item
  double _score(String query, FaqItem f) {
    final qTokens = _expandSynonyms(_terms(query));
    final qSet = qTokens.toSet();

    final titleTokens = _terms(f.question);
    final titleSet = titleTokens.toSet();

    final tagsSet = f.tags.map(_norm).toSet();

    // Overlap (weighted by idf)
    double overlap = 0;
    for (final t in qSet) {
      if (titleSet.contains(t) || tagsSet.contains(t)) {
        overlap += _idf(t);
      }
    }

    // Fuzzy similarity with title
    final fuzzy = _fuzzySim(query, f.question);

    // Tag boost if category or tags hit strongly
    final tagBoost = qSet.intersection(tagsSet).isNotEmpty ? 1.0 : 0.0;

    // Final weighted score (tweakable)
    return 0.6 * overlap + 0.25 * fuzzy + 0.15 * tagBoost;
  }

  // Find topK answers
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

  // Suggestions: top questions containing a token or same category
  List<String> suggestionsFor(FaqItem picked, {int max = 5}) {
    final sameCat = data.where((e) => e.category == picked.category && e.id != picked.id).toList();
    // pick first 5 different questions
    return sameCat.take(max).map((e) => e.question).toList();
  }

  // Quick suggestions for empty screen
  List<String> starterSuggestions({int max = 8}) {
    final qs = data.map((e) => e.question).toSet().toList();
    qs.shuffle(Random());
    return qs.take(max).toList();
  }

  List<String> categories() => data.map((e) => e.category).toSet().toList()..sort();
  List<String> questionsInCategory(String cat, {int max = 10}) =>
      data.where((e) => e.category == cat).map((e) => e.question).take(max).toList();
}

// ---------- PERSISTENCE (feedback + history) ----------
class FaqStore {
  static final FaqStore _i = FaqStore._();
  FaqStore._();
  factory FaqStore() => _i;

  final _box = GetStorage();

  // Feedback: map<faqId, {up:int, down:int}>
  Map<String, dynamic> _fb() => _box.read('smartfaq_feedback') as Map<String, dynamic>? ?? {};
  void thumbUp(String id) {
    final fb = Map<String, dynamic>.from(_fb());
    final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
    rec['up'] = (rec['up'] ?? 0) + 1;
    fb[id] = rec;
    _box.write('smartfaq_feedback', fb);
  }

  void thumbDown(String id) {
    final fb = Map<String, dynamic>.from(_fb());
    final rec = Map<String, dynamic>.from(fb[id] as Map? ?? {});
    rec['down'] = (rec['down'] ?? 0) + 1;
    fb[id] = rec;
    _box.write('smartfaq_feedback', fb);
  }

  // Chat history
  List<ChatMessage> loadHistory() {
    final raw = _box.read('smartfaq_history') as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ChatMessage.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHistory(List<ChatMessage> msgs) async {
    final payload = jsonEncode(msgs.map((e) => e.toJson()).toList());
    await _box.write('smartfaq_history', payload);
  }

  Future<void> clearHistory() => _box.remove('smartfaq_history');
}

// ---------- UI: Smart FAQ Chat ----------
class SmartFaqChatScreen extends StatefulWidget {
  const SmartFaqChatScreen({super.key, this.onOpen});
  final VoidCallback? onOpen; // if you want to log Activity via Bloc on open

  @override
  State<SmartFaqChatScreen> createState() => _SmartFaqChatScreenState();
}

class _SmartFaqChatScreenState extends State<SmartFaqChatScreen> {
  final _engine = FaqEngine(_hardcodedFaqs);
  final _store = FaqStore();
  final _ctl = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessage> _messages = [];
  bool _typing = false;
  String? _selectedCategory; // for suggestion chips

  @override
  void initState() {
    super.initState();
    widget.onOpen?.call(); // e.g., context.read<GlobalBloc>().add(Activity(activity:'Smart FAQ'));
    _messages = _store.loadHistory();
    if (_messages.isEmpty) {
      _seedWelcome();
    }
  }

  void _seedWelcome() {
    final starters = _engine.starterSuggestions();
    _messages = [
      ChatMessage(
        id: 'm0',
        role: ChatRole.bot,
        text:
            'Hi! Ask me anything about Orders, Route, or Payments. You can tap a suggestion below to get started.',
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

  Future<void> _save() => _store.saveHistory(_messages);

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

    // "AI-like" delay
    await Future.delayed(const Duration(milliseconds: 350));

    final hits = _engine.find(text, topK: 4);

    ChatMessage reply;
    if (hits.isEmpty) {
      final alts = _engine.starterSuggestions();
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text:
            "I couldn't find an exact answer, but try these or rephrase your question:",
        ts: DateTime.now(),
        suggestions: alts.take(6).toList(),
      );
    } else {
      final top = hits.first;
      final related = _engine.suggestionsFor(top, max: 5);
      reply = ChatMessage(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        text: top.answer,
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
    // map answer text back to item (best effort)
    final item = _hardcodedFaqs.firstWhere(
      (f) => f.answer == botMsg.text,
      orElse: () => const FaqItem(id: 'unknown', category: '', question: '', answer: ''),
    );
    if (item.id != 'unknown') _store.thumbUp(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for the feedback!')),
    );
  }

  void _onThumbDown(ChatMessage botMsg) {
    final item = _hardcodedFaqs.firstWhere(
      (f) => f.answer == botMsg.text,
      orElse: () => const FaqItem(id: 'unknown', category: '', question: '', answer: ''),
    );
    if (item.id != 'unknown') _store.thumbDown(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Noted. We’ll improve these answers.')),
    );
  }

  Future<void> _clearHistory() async {
    await _store.clearHistory();
    setState(() {
      _seedWelcome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final cats = _engine.categories();
    final catSuggestions = _selectedCategory == null
        ? _engine.starterSuggestions()
        : _engine.questionsInCategory(_selectedCategory!);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Text('Smart FAQs', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: _kText)),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_outline, color: _kMuted),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter & suggestion chips row
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
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final label = (i == 0) ? 'All' : cats[i - 1];
                      final sel = (i == 0 && _selectedCategory == null) ||
                          (i > 0 && _selectedCategory == label);
                      return ChoiceChip(
                        label: Text(label),
                        selected: sel,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = (label == 'All') ? null : label;
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
                              color: sel ? Colors.transparent : const Color(0xFFEDEFF2)),
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
                    itemCount: catSuggestions.length.clamp(0, 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final q = catSuggestions[i];
                      return ActionChip(
                        label: Text(
                          q,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      ),
                    ),
                    if (!isUser && m.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
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
            decoration: const BoxDecoration(color: _kCard, boxShadow: [
              BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, -2))
            ]),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ask a question (e.g. “How do I place an order?”)',
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
                  label: const Text('Ask'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context, String text) {
    // Put your share logic / package here if you use share_plus.
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answer copied to clipboard')),
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
  });

  final bool isUser;
  final String text;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onThumbUp;
  final VoidCallback? onThumbDown;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? _kAccent : _kCard;
    final textColor = isUser ? Colors.white : _kText;

    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: isUser ? _kAccent : Colors.white,
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
