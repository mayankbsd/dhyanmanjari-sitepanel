import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../network/api_service.dart';

class AddCategoryPage extends StatefulWidget {
  final bool isDark;
  const AddCategoryPage({super.key, this.isDark = false});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _englishCtrl   = TextEditingController();
  final _imageCtrl     = TextEditingController();
  bool  _isLoading     = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/categories"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": ApiConstants.token,
        },
        body: jsonEncode({
          "categoryName":    _nameCtrl.text.trim(),
          "categoryEnglish": _englishCtrl.text.trim(),
          "categoryImage":   _imageCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Category added successfully ✅"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Failed")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _englishCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = widget.isDark ? Colors.grey[900] : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white     : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Add Category"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Category Name Hindi
              const Text("Category Name (Hindi)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText:  "जैसे: शिव स्तोत्र",
                  border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled:    true,
                ),
                style:     TextStyle(color: textColor),
                validator: (v) => v!.isEmpty ? "Category name required" : null,
              ),

              const SizedBox(height: 20),

              // Category Name English
              const Text("Category Name (English)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _englishCtrl,
                decoration: InputDecoration(
                  hintText:  "e.g. Shiv Stotra",
                  border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled:    true,
                ),
                style:     TextStyle(color: textColor),
                validator: (v) => v!.isEmpty ? "English name required" : null,
              ),

              const SizedBox(height: 20),

              // Image URL
              const Text("Category Image URL",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageCtrl,
                decoration: InputDecoration(
                  hintText:  "https://example.com/image.png",
                  border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled:    true,
                ),
                style: TextStyle(color: textColor),
              ),

              // Image Preview
              if (_imageCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageCtrl.text,
                    height: 120,
                    width:  double.infinity,
                    fit:    BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 120, color: Colors.grey.shade200,
                            child: const Center(child: Text("Invalid URL"))),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width:  double.infinity,
                height: 50,
                child:  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Category",
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}