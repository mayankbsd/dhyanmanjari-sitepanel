import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddShlokaPage extends StatefulWidget {
  final bool isDark;
  const AddShlokaPage({super.key, this.isDark = false});

  @override
  State<AddShlokaPage> createState() => _AddShlokaPageState();
}

class _AddShlokaPageState extends State<AddShlokaPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _hindiTitleController     = TextEditingController(); // e.g. "नैनं छिन्दन्ति शस्त्राणि"
  final _englishTitleController   = TextEditingController(); // e.g. "Soul is Indestructible"
  final _chapterController        = TextEditingController(); // e.g. "2"
  final _verseController          = TextEditingController(); // e.g. "23"
  final _chapterNameController    = TextEditingController(); // e.g. "सांख्ययोग"
  final _devanagariController     = TextEditingController(); // full shloka in Sanskrit
  final _meaningHindiController   = TextEditingController(); // Hindi arth
  final _wisdomController         = TextEditingController(); // Krishna ka sandesh
  final _hookMsgController        = TextEditingController(); // reel hook line
  final _tagsController           = TextEditingController(); // comma separated tags

  bool _isLoading = false;
  String? _savedShlokaId; // set after save, used for post-reel

  @override
  void dispose() {
    _hindiTitleController.dispose();
    _englishTitleController.dispose();
    _chapterController.dispose();
    _verseController.dispose();
    _chapterNameController.dispose();
    _devanagariController.dispose();
    _meaningHindiController.dispose();
    _wisdomController.dispose();
    _hookMsgController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ── Post existing shloka as reel to FB + IG ──────────────
  Future<void> _postReel(String shlokaId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("\${ApiConstants.shloka}/$shlokaId/post-reel"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": ApiConstants.token,
        },
        body: jsonEncode({"platforms": ["fb", "ig"]}),
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎬 Reel generation started! FB + IG pe post ho jaayega"),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Post failed: \${response.statusCode}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: \$e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveShloka() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      "hindiTitle":   _hindiTitleController.text.trim(),
      "englishTitle": _englishTitleController.text.trim(),
      "chapter":      int.tryParse(_chapterController.text.trim()) ?? 1,
      "verse":        int.tryParse(_verseController.text.trim()) ?? 1,
      "chapterName":  _chapterNameController.text.trim(),
      "devanagari":   _devanagariController.text.trim(),
      "meaningHindi": _meaningHindiController.text.trim(),
      "wisdom":       _wisdomController.text.trim(),
      "hookMsg":      _hookMsgController.text.trim(),
      "tags": _tagsController.text
          .trim()
          .split(",")
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.shloka), // e.g. /api/shloka
        headers: {
          "Content-Type":  "application/json",
          "Authorization": ApiConstants.token,
        },
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = jsonDecode(response.body);
        final id = saved["data"]?["_id"] as String?;
        if (mounted) {
          setState(() => _savedShlokaId = id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Shloka saved! Ab FB + IG pe post kar sakte ho"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Failed: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor    = widget.isDark ? Colors.grey[900]! : const Color(0xfff4f6f9);
    final cardColor  = widget.isDark ? Colors.grey[850]! : Colors.white;
    final textColor  = widget.isDark ? Colors.white : Colors.black87;
    final labelColor = widget.isDark ? Colors.white70 : Colors.black54;
    const accent     = Color(0xFFFF8C00); // saffron — spiritual theme

    InputDecoration field(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: accent) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.orange.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      fillColor: cardColor,
      filled: true,
    );

    Widget label(String text, {bool required = true}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (required)
            const Text(" *", style: TextStyle(color: Colors.red, fontSize: 16)),
        ],
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 22, color: accent,
              margin: const EdgeInsets.only(right: 10)),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "🕉️ Add New Shloka",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header card ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFFDD57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "भगवद्गीता श्लोक",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Fill in the shloka details — यह reel mein use hoga",
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ── Section 1: Titles ────────────────────────
              section("Title / शीर्षक"),

              label("Hindi Title (श्लोक का नाम)"),
              TextFormField(
                controller: _hindiTitleController,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: field(
                  "e.g. नैनं छिन्दन्ति शस्त्राणि...",
                  icon: Icons.title,
                ),
                validator: (v) => v!.trim().isEmpty ? "Hindi title required" : null,
              ),

              const SizedBox(height: 16),
              label("English Title"),
              TextFormField(
                controller: _englishTitleController,
                style: TextStyle(color: textColor),
                decoration: field(
                  "e.g. Soul is Indestructible",
                  icon: Icons.translate,
                ),
                validator: (v) => v!.trim().isEmpty ? "English title required" : null,
              ),

              // ── Section 2: Chapter & Verse ───────────────
              section("Chapter & Verse / अध्याय"),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label("अध्याय (Chapter)"),
                        TextFormField(
                          controller: _chapterController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration: field("e.g. 2", icon: Icons.menu_book),
                          validator: (v) =>
                          v!.trim().isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label("श्लोक (Verse)"),
                        TextFormField(
                          controller: _verseController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration: field("e.g. 23", icon: Icons.tag),
                          validator: (v) =>
                          v!.trim().isEmpty ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              label("Chapter Name (अध्याय का नाम)", required: false),
              TextFormField(
                controller: _chapterNameController,
                style: TextStyle(color: textColor),
                decoration: field(
                  "e.g. सांख्ययोग, कर्मयोग, ज्ञानयोग...",
                  icon: Icons.auto_stories,
                ),
              ),

              // ── Section 3: Shloka Text ───────────────────
              section("Shloka Text / श्लोक"),

              label("Devanagari (Sanskrit श्लोक)"),
              TextFormField(
                controller: _devanagariController,
                maxLines: 5,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  height: 1.8,
                  fontFamily: 'Serif',
                ),
                decoration: field(
                  "नैनं छिन्दन्ति शस्त्राणि\nनैनं दहति पावकः।\nन चैनं क्लेदयन्त्यापो\nन शोषयति मारुतः॥",
                ).copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.format_quote, color: Color(0xFFFF8C00)),
                  ),
                ),
                validator: (v) => v!.trim().isEmpty ? "Shloka text required" : null,
              ),

              // ── Section 4: Meaning & Wisdom ──────────────
              section("Meaning & Wisdom / अर्थ"),

              label("Hindi Arth (हिंदी अर्थ)"),
              TextFormField(
                controller: _meaningHindiController,
                maxLines: 5,
                style: TextStyle(color: textColor, height: 1.7),
                decoration: field(
                  "इस आत्मा को न शस्त्र काट सकते हैं,\nन अग्नि जला सकती है...",
                  icon: Icons.translate,
                ),
                validator: (v) => v!.trim().isEmpty ? "Hindi meaning required" : null,
              ),

              const SizedBox(height: 16),
              label("Wisdom / संदेश (Krishna ka updesh)", required: false),
              TextFormField(
                controller: _wisdomController,
                maxLines: 3,
                style: TextStyle(color: textColor, height: 1.7),
                decoration: field(
                  "आत्मा अजर, अमर और अविनाशी है। भय का कारण अज्ञान है...",
                  icon: Icons.lightbulb_outline,
                ),
              ),

              // ── Section 5: Reel Hook ─────────────────────
              section("Reel Hook / सोशल मीडिया"),

              label("Hook Message (Reel ke liye)", required: false),
              TextFormField(
                controller: _hookMsgController,
                maxLines: 2,
                style: TextStyle(color: textColor),
                decoration: field(
                  "अर्जुन को मिला जीवन का सबसे बड़ा उपदेश — क्या तुम इसे जानते हो?",
                  icon: Icons.campaign_outlined,
                ),
              ),

              const SizedBox(height: 16),
              label("Tags (comma separated)", required: false),
              TextFormField(
                controller: _tagsController,
                style: TextStyle(color: textColor),
                decoration: field(
                  "karma, atma, geeta, adhyay2",
                  icon: Icons.label_outline,
                ),
              ),

              // ── Submit button ────────────────────────────
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isLoading ? null : _saveShloka,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isLoading ? "Saving..." : "Save Shloka  🕉️",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ── Post to FB + IG button (shown after save) ──
              if (_savedShlokaId != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : () => _postReel(_savedShlokaId!),
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.send_rounded),
                    label: const Text(
                      "Post Reel to FB + Instagram  🎬",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Reel banake automatically post ho jaayega",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}