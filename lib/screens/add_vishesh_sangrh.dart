import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../network/api_service.dart';

class AddVisheshSangrahPage extends StatefulWidget {
  final bool isDark;
  const AddVisheshSangrahPage({super.key, this.isDark = false});

  @override
  State<AddVisheshSangrahPage> createState() => _AddVisheshSangrahPageState();
}

class _AddVisheshSangrahPageState extends State<AddVisheshSangrahPage> {
  final _formKey        = GlobalKey<FormState>();
  final _titleCtrl      = TextEditingController();
  final _englishCtrl    = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _contentCtrl    = TextEditingController();

  bool   _isLoading     = false;
  bool   _catLoading    = true;

  List<Map<String, dynamic>> _categories = [];
  int?   _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _englishCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/categories"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": ApiConstants.token,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data["data"] as List<dynamic>;
        setState(() {
          _categories = list.map((e) => {
            "categoryId":   e["categoryId"],
            "categoryName": e["categoryName"],
          }).toList();
          _catLoading = false;
        });
      }
    } catch (_) {
      setState(() => _catLoading = false);
    }
  }

  List<String> _splitIntoPages(String content) {
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final pages = <String>[];
    for (int i = 0; i < lines.length; i += 4) {
      pages.add(lines.sublist(i, (i + 4).clamp(0, lines.length)).join('\n'));
    }
    return pages;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pages = _splitIntoPages(_contentCtrl.text.trim());

      final res = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/granths"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": ApiConstants.token,
        },
        body: jsonEncode({
          "title":        _titleCtrl.text.trim(),
          "titleEnglish": _englishCtrl.text.trim(),
          "description":  _descCtrl.text.trim(),
          "duration":     "5 min",
          "language":     "Hindi",
          "categoryId":   _selectedCategoryId,
          "pages":        pages,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Granth added successfully"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "❌ Failed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = widget.isDark ? Colors.grey[900]! : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850]! : Colors.white;
    final textColor = widget.isDark ? Colors.white      : Colors.black87;
    const accent    = Colors.red;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Add Vishesh Sangrah"),
        backgroundColor: accent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Title Hindi ──
              _label("Title (Hindi)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: textColor),
                decoration: _deco("जैसे: शिव पुराण", cardColor),
                validator: (v) => v!.isEmpty ? "Title required" : null,
              ),

              const SizedBox(height: 20),

              // ── Title English ──
              _label("Title (English)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _englishCtrl,
                style: TextStyle(color: textColor),
                decoration: _deco("e.g. Shiv Puran", cardColor),
                validator: (v) => v!.isEmpty ? "English title required" : null,
              ),

              const SizedBox(height: 20),

              // ── Description ──
              _label("Description"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _deco("Short description...", cardColor),
                validator: (v) => v!.isEmpty ? "Description required" : null,
              ),

              const SizedBox(height: 20),

              // ── Category Dropdown ──
              _label("Category *"),
              const SizedBox(height: 8),
              _catLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text("No categories found. Please add a category first.",
                    style: TextStyle(color: Colors.red)),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded:  true,
                    value:       _selectedCategoryId,
                    hint:        const Text("Select Category"),
                    dropdownColor: cardColor,
                    style:       TextStyle(color: textColor, fontSize: 15),
                    items: _categories.map((c) => DropdownMenuItem<int>(
                      value: c["categoryId"] as int,
                      child: Text(c["categoryName"] as String),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Content ──
              _label("Content (4 lines = 1 page)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                maxLines:   20,
                style:      TextStyle(color: textColor),
                decoration: _deco("Paste full content here...\n4 lines = 1 page", cardColor),
                validator:  (v) => v!.isEmpty ? "Content required" : null,
              ),

              const SizedBox(height: 30),

              // ── Save Button ──
              SizedBox(
                width:  double.infinity,
                height: 50,
                child:  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Granth", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  InputDecoration _deco(String hint, Color fill) => InputDecoration(
    hintText:    hint,
    filled:      true,
    fillColor:   fill,
    border:      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}