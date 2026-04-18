import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';
// user_detail_page.dart aur send_notification_page.dart
// dono mein ye method add karo

import 'package:image_picker/image_picker.dart';

// Controller ke saath ye add karo

// Image pick + upload method

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final bool openNotification;

  const UserDetailPage({
    super.key,
    required this.user,
    this.isDark = false,
    this.openNotification = false,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  final _imageCtrl = TextEditingController(); // ← add
  bool _sending    = false;
  String _status   = '';
  bool _isSuccess  = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose(); // ← add
    super.dispose();
  }
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth:   1024,
      maxHeight:  1024,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => _uploadingImage = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final bytes    = await picked.readAsBytes();
      final filename = picked.name;

      // Multipart request
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConstants.baseUrl}/upload"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          bytes,
          filename: filename,
        ),
      );

      final streamedRes = await request.send();
      final res         = await http.Response.fromStream(streamedRes);
      final data        = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          _imageCtrl.text = data["imageUrl"]; // ← URL set ho jayega
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Upload failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _uploadingImage = false);
    }
  }
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Future<void> _sendNotification() async {
    final title    = _titleCtrl.text.trim();
    final body     = _bodyCtrl.text.trim();
    final imageUrl = _imageCtrl.text.trim(); // ← add

    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _status    = 'Title aur message dono required hain';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _sending = true;
      _status  = '';
    });

    try {
      final prefs    = await SharedPreferences.getInstance();
      final token    = prefs.getString('token') ?? '';
      final fcmToken = widget.user["fcmToken"] ?? '';
      final userId   = widget.user["_id"] ?? widget.user["id"] ?? '';

      final res = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/notifications"), // ← /api/ fix
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title":    title,
          "body":     body,
          "userId":   userId,
          "fcmToken": fcmToken,
          if (imageUrl.isNotEmpty) "imageUrl": imageUrl, // ← add
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          _status    = 'Notification bhej di gai!';
          _isSuccess = true;
        });
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _imageCtrl.clear(); // ← add
      } else {
        setState(() {
          _status    = data["message"] ?? 'Kuch galat hua';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _status    = 'Error: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user     = widget.user;
    final name     = user["fullname"] ?? user["username"] ?? "User";
    final email    = user["email"]    ?? "";
    final fcmToken = user["fcmToken"] ?? "";
    final hasToken = fcmToken.isNotEmpty;
    final initials = _getInitials(name);

    final bgColor   = widget.isDark ? Colors.grey[900]! : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850]! : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("User Details"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── User Info Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasToken
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasToken
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      hasToken
                          ? "FCM Token Available"
                          : "FCM Token Nahi Hai",
                      style: TextStyle(
                        fontSize: 12,
                        color: hasToken
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Detail Fields ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow("User ID",
                      user["userId"]?.toString() ?? user["_id"] ?? ""),
                  _detailRow("Username", user["username"] ?? ""),
                  _detailRow("Email", email),
                  _detailRow(
                    "FCM Token",
                    hasToken
                        ? '${fcmToken.substring(0, fcmToken.length.clamp(0, 20))}...'
                        : 'Not available',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notification Section ──
            if (hasToken) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: Colors.deepPurple, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Notification Bhejo",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Title ──
                    const Text("Title",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        hintText: "e.g. नई सूचना",
                        filled:   true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Message ──
                    const Text("Message",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines:   3,
                      decoration: InputDecoration(
                        hintText: "Notification ka message...",
                        filled:   true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Image URL ── ← naya
                    // Image URL field ki jagah ye use karo
                    const Text("Notification Image (Optional)",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),

// ── URL field + Upload button ──
    Row(
    children: [
    Expanded(
    child: TextFormField(
    controller: _imageCtrl,
    onChanged:  (_) => setState(() {}),
    decoration: InputDecoration(
    hintText:   "URL ya gallery se choose karo",
    prefixIcon: const Icon(Icons.image_outlined, size: 20),
    filled:     true,
    fillColor:  bgColor,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 10),
    ),
    ),
    ),
    const SizedBox(width: 8),

    // ── Gallery Button ──
    SizedBox(
    height: 46,
    child: ElevatedButton(
    onPressed: _uploadingImage ? null : _pickAndUploadImage,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple.shade50,
    foregroundColor: Colors.deepPurple,
    elevation: 0,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    side: BorderSide(color: Colors.deepPurple.shade200)),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: _uploadingImage
    ? const SizedBox(
    width: 18, height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
    )
        : const Icon(Icons.photo_library_outlined, size: 22),
    ),
    ),
    ],
    ),

// ── Image Preview ──
    if (_imageCtrl.text.isNotEmpty) ...[
    const SizedBox(height: 10),
    Stack(
    children: [
    ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
    _imageCtrl.text,
    height: 130,
    width:  double.infinity,
    fit:    BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
    height: 46,
    decoration: BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(
    child: Text("Invalid image URL",
    style: TextStyle(color: Colors.red)),
    ),
    ),
    ),
    ),
    // Remove button
    Positioned(
    top: 6, right: 6,
    child: GestureDetector(
    onTap: () => setState(() => _imageCtrl.clear()),
    child: Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
    color:  Colors.black54,
    shape:  BoxShape.circle,
    ),
    child: const Icon(Icons.close,
    color: Colors.white, size: 16),
    ),
    ),
    ),
    ],
    ),
    ],


                    const SizedBox(height: 16),

                    // ── Send Button ──
                    SizedBox(
                      width:  double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: _sending
                            ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2),
                        )
                            : const Text("Send Notification"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _sending ? null : _sendNotification,
                      ),
                    ),

                    // ── Status ──
                    if (_status.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 16,
                              color: _isSuccess
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _status,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isSuccess
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Is user ke paas FCM token nahi hai,\nisiliye notification nahi bhej sakte.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const Text("  :  ",
              style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}