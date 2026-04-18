import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddAartiPage extends StatefulWidget {
  final bool isDark;
  const AddAartiPage({super.key, this.isDark = false});

  @override
  State<AddAartiPage> createState() => _AddAartiPageState();
}

class _AddAartiPageState extends State<AddAartiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController englishTitleController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController languageController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  Future<void> _saveAarti() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final body = {
      "title": titleController.text.trim(),
      "titleEnglish": englishTitleController.text.trim(),
      "duration": durationController.text.trim().isEmpty ? "5 min" : durationController.text.trim(),
      "language": languageController.text.trim().isEmpty ? "Hindi" : languageController.text.trim(),
      "description": descriptionController.text.trim(),
    };

    final response = await http.post(
      Uri.parse(ApiConstants.aarti), // backend endpoint
      headers: {
        "Content-Type": "application/json",
        "Authorization":ApiConstants.token

      },
      body: jsonEncode(body),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context); // success, wapas dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add Aarti")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? Colors.grey[900] : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final accentColor = Colors.green;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Add New Aarti"),
        backgroundColor: accentColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Title (Hindi)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Enter Aarti Title in Hindi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? "Title required" : null,
              ),

              const SizedBox(height: 20),
              const Text(
                "Title (English)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: englishTitleController,
                decoration: InputDecoration(
                  hintText: "Enter Aarti Title in English",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? "English Title required" : null,
              ),

              const SizedBox(height: 20),
              const Text(
                "Duration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: durationController,
                decoration: InputDecoration(
                  hintText: "Enter duration (e.g., 5 min)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
              ),

              const SizedBox(height: 20),
              const Text(
                "Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: languageController,
                decoration: InputDecoration(
                  hintText: "Enter language (e.g., Hindi)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
              ),

              const SizedBox(height: 20),
              const Text(
                "Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 15,
                decoration: InputDecoration(
                  hintText: "Enter Aarti description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? "Description required" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _saveAarti,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Aarti",
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