import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../network/api_service.dart';

class AddMandirPage extends StatefulWidget {
  const AddMandirPage({super.key});

  @override
  State<AddMandirPage> createState() => _AddMandirPageState();
}

class _AddMandirPageState extends State<AddMandirPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _liveUrlController = TextEditingController();
  bool _isLive = false;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  Future<void> _submitMandir() async {
    if (_nameController.text.trim().isEmpty) {
      _showMsg("Mandir name is required");
      return;
    }
    if (_imageBytes == null) {
      _showMsg("Please select an image");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse("${ApiConstants.baseUrl}/mandir");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = ApiConstants.token;
      request.fields["name"] = _nameController.text.trim();
      request.fields["location"] = _locationController.text.trim();
      request.fields["city"] = _cityController.text.trim();
      request.fields["liveUrl"] = _liveUrlController.text.trim();
      request.fields["isLive"] = _isLive.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          _imageBytes!,
          filename: _imageName ?? "mandir.jpg",
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        _showMsg("Mandir added successfully");
        if (mounted) Navigator.pop(context, true);
      } else {
        _showMsg(data["message"] ?? "Something went wrong");
      }
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Mandir")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                        : const Center(child: Icon(Icons.add_photo_alternate, size: 48)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Mandir Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Location (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: "City (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _liveUrlController,
                  decoration: const InputDecoration(
                    labelText: "Live Darshan URL (YouTube link)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Is currently live?"),
                  value: _isLive,
                  onChanged: (val) => setState(() => _isLive = val),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitMandir,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text("Add Mandir"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}