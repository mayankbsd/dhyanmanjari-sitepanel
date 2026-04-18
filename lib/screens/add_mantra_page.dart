import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddMantraPage extends StatefulWidget {
  final bool isDark;
  const AddMantraPage({super.key, this.isDark = false});

  @override
  State<AddMantraPage> createState() => _AddMantraPageState();
}

class _AddMantraPageState extends State<AddMantraPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController englishTitleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  bool isLoading = false;

  Future<void> _saveMantra() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final body = {
      "title": titleController.text.trim(),
      "titleEnglish": englishTitleController.text.trim(),
      "duration": "5 min", // default ya input se set kar sakte ho
      "language": "Hindi",
      "description": contentController.text.trim(),
    };

    final response = await http.post(
      Uri.parse(ApiConstants.mantra), // backend endpoint
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
        const SnackBar(content: Text("Failed to add Mantra")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? Colors.grey[900] : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final accentColor = Colors.blue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Add New Mantra"),
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
                  hintText: "Enter Mantra Title in Hindi",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                  hintText: "Enter Mantra Title in English",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? "English Title required" : null,
              ),

              const SizedBox(height: 25),
              const Text(
                "Content / Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: contentController,
                maxLines: 20,
                decoration: InputDecoration(
                  hintText: "Enter Mantra content / description here...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  fillColor: cardColor,
                  filled: true,
                ),
                style: TextStyle(color: textColor),
                validator: (value) => value!.isEmpty ? "Content required" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _saveMantra,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Mantra",
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