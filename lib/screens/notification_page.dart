import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';

class SendNotificationPage extends StatefulWidget {
  final bool isDark;
  const SendNotificationPage({super.key, this.isDark = false});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  final _imageCtrl = TextEditingController();

  bool _isLoading      = false;
  bool _isFetching     = false;
  bool _uploadingImage = false;

  // ── Target selection ──
  String _target = "registered";

  List<Map<String, dynamic>> _registeredUsers = [];
  List<Map<String, dynamic>> _guestUsers      = [];
  Map<String, dynamic>?      _selectedUser;

  // ── Blocked users ──
  Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ── Load blocked users from SharedPreferences ──
  Future<void> _loadBlockedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList('blocked_users') ?? [];
    setState(() => _blockedUserIds = list.toSet());
  }

  // ── Toggle block/unblock ──
  Future<void> _toggleBlock(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_blockedUserIds.contains(userId)) {
        _blockedUserIds.remove(userId);
      } else {
        _blockedUserIds.add(userId);
        // Deselect if currently selected
        if (_selectedUser?["id"] == userId) {
          _selectedUser = null;
        }
      }
    });
    await prefs.setStringList('blocked_users', _blockedUserIds.toList());

    final isNowBlocked = _blockedUserIds.contains(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowBlocked ? "🚫 User blocked" : "✅ User unblocked",
          ),
          backgroundColor: isNowBlocked ? Colors.red.shade700 : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Confirm block dialog ──
  Future<void> _showBlockConfirmDialog(Map<String, dynamic> user) async {
    final isBlocked  = _blockedUserIds.contains(user["id"]);
    final actionText = isBlocked ? "Unblock" : "Block";
    final actionIcon = isBlocked ? Icons.lock_open_rounded : Icons.block_rounded;
    final actionColor = isBlocked ? Colors.green : Colors.red;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(actionIcon, color: actionColor, size: 22),
            const SizedBox(width: 8),
            Text(
              "$actionText User?",
              style: TextStyle(color: actionColor, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBlocked
                  ? "Kya aap is user ko unblock karna chahte hain? Inhe phir se notifications milne lagengi."
                  : "Kya aap is user ko block karna chahte hain? Inhe koi bhi notification nahi jayegi.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: user["type"] == "guest"
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      user["type"] == "guest"
                          ? Icons.person_outline
                          : Icons.person,
                      size: 16,
                      color: user["type"] == "guest"
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user["name"],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        Text(user["email"],
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleBlock(user["id"]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // ── Registered users load ──
  Future<void> _loadUsers() async {
    setState(() => _isFetching = true);
    try {
      final token = await _getToken();
      final res   = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/users"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data["data"] as List<dynamic>;
        setState(() {
          _registeredUsers = list
              .where((u) =>
          u["fcmToken"] != null &&
              u["fcmToken"].toString().isNotEmpty)
              .map((u) => {
            "id":       u["_id"]      ?? "",
            "name":     u["fullname"] ?? u["username"] ?? "User",
            "email":    u["email"]    ?? "",
            "fcmToken": u["fcmToken"] ?? "",
            "type":     "registered",
          })
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Load registered users error: $e");
    }
    setState(() => _isFetching = false);
  }

  // ── Guest users load ──
  Future<void> _loadGuestUsers() async {
    try {
      final token = await _getToken();
      final res   = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/guest-users"),
        headers: {
          "Content-Type":  "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          final list = data["data"] as List<dynamic>;

          _guestUsers = list.map((u) {
            final fcm = u["fcmToken"]?.toString() ?? "";
            final shortFcm = fcm.length > 20
                ? "${fcm.substring(0, 20)}..."
                : fcm.isEmpty
                ? "Unknown"
                : fcm;

            return {
              "id":       u["_id"]   ?? "",
              "name":     "Guest User",
              "email":    (u["deviceId"] != null &&
                  u["deviceId"].toString().isNotEmpty &&
                  u["deviceId"] != "null")
                  ? "Device: ${u['deviceId']}"
                  : shortFcm,
              "fcmToken": fcm,
              "type":     "guest",
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Guest users error: $e");
    }
  }

  // ── Image upload ──
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:       ImageSource.gallery,
      maxWidth:     1024,
      maxHeight:    1024,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString('token') ?? '';
      final bytes   = await picked.readAsBytes();
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConstants.baseUrl}/upload"),
      );
      request.headers["Authorization"] = "Bearer $token";
      request.files.add(http.MultipartFile.fromBytes(
          "image", bytes, filename: picked.name));

      final res  = await http.Response.fromStream(await request.send());
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() => _imageCtrl.text = data["imageUrl"]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  // ── Send ──
  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final title    = _titleCtrl.text.trim();
    final body     = _bodyCtrl.text.trim();
    final imageUrl = _imageCtrl.text.trim();

    try {
      switch (_target) {

        case "all":
          await _sendToTopic("all_users", title, body, imageUrl);
          break;

        case "registered":
          await _sendToTopic("registered_users", title, body, imageUrl);
          break;

        case "guest":
          await _sendToTopic("guest_users", title, body, imageUrl);
          break;

        case "single":
          if (_selectedUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User select karo")),
            );
            setState(() => _isLoading = false);
            return;
          }
          // ── Block check ──
          if (_blockedUserIds.contains(_selectedUser!["id"])) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:         Text("🚫 Yeh user blocked hai. Pehle unblock karo."),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
          await _sendOne(
            title:    title,
            body:     body,
            userId:   _selectedUser!["id"],
            fcmToken: _selectedUser!["fcmToken"],
            imageUrl: imageUrl,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text("✅ Notification sent!"),
            backgroundColor: Colors.green,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _imageCtrl.clear();
        setState(() => _selectedUser = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Topic notification ──
  Future<void> _sendToTopic(
      String topic, String title, String body, String imageUrl) async {
    final token = await _getToken();
    final res   = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/notify-topic"),
      headers: {
        "Content-Type":  "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "topic":          topic,
        "title":          title,
        "body":           body,
        "imageUrl":       imageUrl,
        "blockedUserIds": _blockedUserIds.toList(), // Backend ko bhi bhejo
      }),
    );
    final data = jsonDecode(res.body);
    if (data["success"] != true) {
      throw Exception(data["message"] ?? "Failed");
    }
  }

  // ── Single notification ──
  Future<void> _sendOne({
    required String title,
    required String body,
    required String userId,
    required String fcmToken,
    String imageUrl = '',
  }) async {
    final token = await _getToken();
    final res   = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/notifications"),
      headers: {
        "Content-Type":  "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title":    title,
        "body":     body,
        "userId":   userId,
        "fcmToken": fcmToken,
        if (imageUrl.isNotEmpty) "imageUrl": imageUrl,
      }),
    );
    final data = jsonDecode(res.body);
    if (data["success"] != true) {
      throw Exception(data["message"] ?? "Failed");
    }
  }

  // ── Dono ek saath load karo ──
  Future<void> _loadAllData() async {
    setState(() => _isFetching = true);
    await Future.wait([
      _loadUsers(),
      _loadGuestUsers(),
      _loadBlockedUsers(),
    ]);
    setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = widget.isDark ? Colors.grey[900]! : const Color(0xfff4f6f9);
    final cardColor = widget.isDark ? Colors.grey[850]! : Colors.white;
    final textColor = widget.isDark ? Colors.white      : Colors.black87;
    const accent    = Colors.purple;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Send Notification"),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        actions: [
          // ── Blocked count badge ──
          if (_blockedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.block_rounded),
                    onPressed: _showBlockedUsersSheet,
                    tooltip: "Blocked Users",
                  ),
                  Positioned(
                    top: 6, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${_blockedUserIds.length}",
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ─────────────────────────────────────
              // TARGET SELECTION
              // ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Notification Kisko Bhejna Hai?",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children: [
                        _targetChip(
                          label: "Registered Users",
                          value: "registered",
                          icon:  Icons.people_rounded,
                          color: Colors.blue,
                          count: _registeredUsers.length,
                        ),
                        _targetChip(
                          label: "Guest Users",
                          value: "guest",
                          icon:  Icons.person_outline_rounded,
                          color: Colors.orange,
                          count: _guestUsers.length,
                        ),
                        _targetChip(
                          label: "All Users",
                          value: "all",
                          icon:  Icons.public_rounded,
                          color: Colors.green,
                          count: _registeredUsers.length + _guestUsers.length,
                        ),
                        _targetChip(
                          label: "Single User",
                          value: "single",
                          icon:  Icons.person_pin_rounded,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────
              // STATS CARDS
              // ─────────────────────────────────────
              Row(
                children: [
                  _statCard("Registered", _registeredUsers.length,
                      Colors.blue, Icons.people_rounded),
                  const SizedBox(width: 8),
                  _statCard("Guest", _guestUsers.length,
                      Colors.orange, Icons.person_outline_rounded),
                  const SizedBox(width: 8),
                  _statCard("Total",
                      _registeredUsers.length + _guestUsers.length,
                      Colors.green, Icons.public_rounded),
                  const SizedBox(width: 8),
                  // ── Blocked stat card ──
                  _statCard("Blocked", _blockedUserIds.length,
                      Colors.red, Icons.block_rounded),
                ],
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────
              // SINGLE USER SELECT
              // ─────────────────────────────────────
              if (_target == "single") ...[
                const Text("Select User",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:        cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TabBar(
                          labelColor:           Colors.purple,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor:       Colors.purple,
                          indicatorSize:        TabBarIndicatorSize.tab,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people, size: 16),
                                  const SizedBox(width: 4),
                                  Text("Registered (${_registeredUsers.length})"),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 4),
                                  Text("Guest (${_guestUsers.length})"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: TabBarView(
                          children: [
                            _userListView(_registeredUsers, cardColor, textColor),
                            _userListView(_guestUsers, cardColor, textColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─────────────────────────────────────
              // TITLE
              // ─────────────────────────────────────
              const Text("Notification Title",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style:      TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText:  "e.g. नई सूचना",
                  filled:    true,
                  fillColor: cardColor,
                  border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Title required" : null,
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────
              // BODY
              // ─────────────────────────────────────
              const Text("Notification Message",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines:   4,
                style:      TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText:  "Notification ka message likho...",
                  filled:    true,
                  fillColor: cardColor,
                  border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? "Message required" : null,
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────
              // IMAGE
              // ─────────────────────────────────────
              const Text("Image (Optional)",
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageCtrl,
                      onChanged:  (_) => setState(() {}),
                      style:      TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText:   "Image URL paste karo",
                        prefixIcon: const Icon(
                            Icons.image_outlined, size: 20),
                        filled:    true,
                        fillColor: cardColor,
                        border:    OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _uploadingImage ? null : _pickAndUploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade50,
                        foregroundColor: Colors.purple,
                        elevation:       0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.purple.shade200)),
                      ),
                      child: _uploadingImage
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                          : const Icon(
                          Icons.photo_library_outlined, size: 22),
                    ),
                  ),
                ],
              ),

              if (_imageCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _imageCtrl.text,
                        height:      130,
                        width:       double.infinity,
                        fit:         BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 46,
                          color:  Colors.red.shade50,
                          child: const Center(
                              child: Text("Invalid URL",
                                  style: TextStyle(color: Colors.red))),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageCtrl.clear()),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ─────────────────────────────────────
              // SEND BUTTON
              // ─────────────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon:  const Icon(Icons.send_rounded),
                  label: Text(
                    _getSendButtonText(),
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _send,
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Center(child: Text("Bhej rahe hain...")),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // BLOCKED USERS BOTTOM SHEET
  // ─────────────────────────────────────
  void _showBlockedUsersSheet() {
    final allUsers = [..._registeredUsers, ..._guestUsers];
    final blocked  = allUsers
        .where((u) => _blockedUserIds.contains(u["id"]))
        .toList();

    showModalBottomSheet(
      context:       context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              "🚫 Blocked Users",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: blocked.isEmpty
                  ? const Center(
                  child: Text("Koi blocked user nahi hai",
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: blocked.length,
                itemBuilder: (_, i) {
                  final u = blocked[i];
                  return Container(
                    margin:  const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color:        Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(
                          color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius:          18,
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.block,
                              color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(u["name"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(u["email"],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await _toggleBlock(u["id"]);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.lock_open,
                              size: 14, color: Colors.green),
                          label: const Text("Unblock",
                              style: TextStyle(
                                  color: Colors.green, fontSize: 12)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────

  Widget _targetChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    int? count,
  }) {
    final selected = _target == value;
    return GestureDetector(
      onTap: () => setState(() {
        _target       = value;
        _selectedUser = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              count != null ? "$label ($count)" : label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              "$count",
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.bold,
                  color:      color),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userListView(List<Map<String, dynamic>> users,
      Color cardColor, Color textColor) {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text("Koi user nahi hai",
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u         = users[i];
        final selected  = _selectedUser?["id"] == u["id"];
        final isGuest   = u["type"] == "guest";
        final isBlocked = _blockedUserIds.contains(u["id"]);

        return GestureDetector(
          onTap: () {
            if (isBlocked) return; // Blocked user select nahi hoga
            setState(() => _selectedUser = u);
          },
          child: Container(
            margin:  const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // ── Blocked = greyed out ──
              color: isBlocked
                  ? Colors.grey.shade100
                  : selected
                  ? Colors.purple.withOpacity(0.1)
                  : cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBlocked
                    ? Colors.grey.shade300
                    : selected
                    ? Colors.purple
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isBlocked
                          ? Colors.grey.shade200
                          : isGuest
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        isBlocked
                            ? Icons.block
                            : isGuest
                            ? Icons.person_outline
                            : Icons.person,
                        size:  18,
                        color: isBlocked
                            ? Colors.grey
                            : isGuest
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u["name"],
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      isBlocked
                              ? Colors.grey
                              : textColor,
                          decoration: isBlocked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        u["email"],
                        style: TextStyle(
                            fontSize: 11,
                            color:    Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Block / Unblock button ──
                GestureDetector(
                  onTap: () => _showBlockConfirmDialog(u),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isBlocked
                            ? Colors.red.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBlocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                          size:  12,
                          color: isBlocked ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isBlocked ? "Unblock" : "Block",
                          style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w600,
                            color:      isBlocked
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected check
                if (selected && !isBlocked) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle,
                      color: Colors.purple, size: 18),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSendButtonText() {
    switch (_target) {
      case "registered":
        return "Send to Registered (${_registeredUsers.length})";
      case "guest":
        return "Send to Guest (${_guestUsers.length})";
      case "all":
        return "Send to All (${_registeredUsers.length + _guestUsers.length})";
      case "single":
        return _selectedUser != null
            ? "Send to ${_selectedUser!["name"]}"
            : "Single User Select Karo";
      default:
        return "Send Notification";
    }
  }
}