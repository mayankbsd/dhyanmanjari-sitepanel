import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddChalisaPage extends StatefulWidget {
  final bool isDark;

  const AddChalisaPage({super.key, this.isDark = false});

  @override
  State<AddChalisaPage> createState() => _AddChalisaPageState();
}

class _AddChalisaPageState extends State<AddChalisaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController englishTitleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  bool isLoading = false;

  /// 4 lines = 1 page
  List<String> _splitIntoPages(String content) {
    List<String> lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    List<String> pages = [];

    for (int i = 0; i < lines.length; i += 4) {
      int end = (i + 4 < lines.length) ? i + 4 : lines.length;
      pages.add(lines.sublist(i, end).join('\n'));
    }

    return pages;
  }

  Future<void> _saveChalisa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {

      List<String> pages = _splitIntoPages(contentController.text.trim());

      final body = {
        "title": titleController.text.trim(),
        "titleEnglish": englishTitleController.text.trim(),
        "duration": "5 min",
        "language": "Hindi",
        "description": contentController.text.trim(),
        "pages": pages
      };

      final response = await http.post(
        Uri.parse(ApiConstants.chalisha),
        headers: {
          "Content-Type": "application/json",
          "Authorization":ApiConstants.token

        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 && data["success"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Chalisa added successfully"),
          ),
        );

        Navigator.pop(context);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "❌ Failed to add Chalisa"),
          ),
        );

      }

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final bgColor = widget.isDark ? Colors.grey[900] : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    const accentColor = Colors.deepPurple;

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: const Text("Add New Chalisa"),
        backgroundColor: accentColor,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TITLE HINDI
              const Text(
                "Title (Hindi)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter Chalisa Title in Hindi",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Title required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// TITLE ENGLISH
              const Text(
                "Title (English)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: englishTitleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter Chalisa Title in English",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "English Title required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              /// CONTENT
              const Text(
                "Content",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: contentController,
                maxLines: 20,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Paste full chalisa text here...\n4 lines = 1 page",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Content required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: isLoading ? null : _saveChalisa,

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Chalisa",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}