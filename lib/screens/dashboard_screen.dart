import 'dart:convert';
import 'package:dhyanmanjari_sitepanel/screens/notification_page.dart';
import 'package:dhyanmanjari_sitepanel/screens/user_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';
import 'add_category_page.dart';
import 'add_chalisa_page.dart';
import 'add_aarti_page.dart';
import 'add_mantra_page.dart';
import 'add_vishesh_sangrh.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String selectedSection = "Dashboard";
  bool isDark = false;

  final sections = [
    "Dashboard",
    "Users",
    "Chalisas",
    "Aartis",
    "Mantras",
    "Vishesh Sangrh",
    "Categories",  // ← ADD
    "Notifications", // ← ADD

  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xfff4f6f9),
      body: Row(
        children: [

          /// ================= SIDEBAR =================
          Container(
            width: 230,
            color: isDark ? Colors.grey[900] : Colors.deepPurple,
            child: Column(
              children: [

                const SizedBox(height: 40),

                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 50),

                const SizedBox(height: 10),

                const Text(
                  "Admin Panel",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                ...sections.map(
                      (e) => ListTile(
                    title: Text(
                      e,
                      style: const TextStyle(color: Colors.white),
                    ),
                    selected: selectedSection == e,
                    selectedTileColor: Colors.white24,
                    onTap: () {
                      setState(() {
                        selectedSection = e;
                      });
                    },
                  ),
                ),

                const Spacer(),

                SwitchListTile(
                  value: isDark,
                  onChanged: (val) {
                    setState(() {
                      isDark = val;
                    });
                  },
                  title: const Text(
                    "Dark Mode",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          /// ================= MAIN CONTENT =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: selectedSection == "Dashboard"
                  ? _buildDashboard()
                  : _buildContentPage(selectedSection),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DASHBOARD OVERVIEW =================
  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Overview",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 30),

        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _statCard("Users", "users", Icons.people, Colors.deepPurple),
            _statCard("Chalisas", "chalisha", Icons.menu_book, Colors.orange),
            _statCard("Aartis", "aartis", Icons.auto_awesome, Colors.green),
            _statCard("Mantras", "mantras", Icons.self_improvement, Colors.blue),
            _statCard("Vishesh", "granth", Icons.collections_bookmark, Colors.red),
            _statCard("Categories", "category", Icons.category, Colors.teal),
            _statCard("Notifications", "notifications", Icons.notifications, Colors.purple),
          ],
        ),
      ],
    );
  }

  /// ================= DASHBOARD COUNT CARD =================
  Widget _statCard(String title, String endpoint, IconData icon, Color color) {

    Future<int> fetchCount() async {

      final response = await http.get(
        Uri.parse(ApiConstants.dashStats),
        headers: {
          "Content-Type": "application/json",
          "Authorization":ApiConstants.token

        },
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        final counts = data["data"] ?? {};

        return counts[endpoint] ?? 0;
      }

      return 0;
    }

    return FutureBuilder<int>(
      future: fetchCount(),
      builder: (context, snapshot) {

        int count = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            setState(() {
              selectedSection = title;
            });
          },
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Icon(icon, color: Colors.white),

                const SizedBox(height: 15),

                Text(
                  title,
                  style: const TextStyle(color: Colors.white70),
                ),

                snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  count.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= CONTENT PAGE =================
  Widget _buildContentPage(String section) {

    String endpoint = "";

    if (section == "Users") endpoint = "users";
    if (section == "Chalisas") endpoint = "chalisha";
    if (section == "Aartis") endpoint = "aartis";
    if (section == "Mantras") endpoint = "mantras";
    if (section == "Vishesh Sangrh") endpoint = "granths";
    if (section == "Categories") endpoint = "categories";
    if (section == "Notifications") endpoint = "notifications";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              section,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add"),
              onPressed: () {

                if (section == "Chalisas") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddChalisaPage(),
                    ),
                  );
                }

                if (section == "Aartis") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddAartiPage(),
                    ),
                  );
                }

                if (section == "Mantras") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddMantraPage(),
                    ),
                  );
                }

                if (section == "Vishesh Sangrh") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddVisheshSangrahPage(),
                    ),
                  );
                }
                if (section == "Categories") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddCategoryPage(),
                    ),
                  );
                }
                if (section == "Notifications") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  SendNotificationPage()),
                  );
                }
              },
            )
          ],
        ),

        const SizedBox(height: 20),

        /// LIST
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(

            future: fetchApiList(endpoint),

            builder: (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (!snapshot.hasData ||
                  snapshot.data!["data"] == null ||
                  snapshot.data!["data"].length == 0) {
                return const Center(child: Text("No data found"));
              }

              final items = snapshot.data!["data"] as List<dynamic>;

// _buildContentPage ke andar ListView.builder mein ye replace karo:
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final data = items[index] as Map<String, dynamic>;

                  // ── User initials helper ──
                  String getInitials(String name) {
                    final parts = name.trim().split(' ');
                    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
                  }

                  final isUsers = section == "Users";
                  final hasToken = isUsers &&
                      data["fcmToken"] != null &&
                      data["fcmToken"].toString().isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      // ── User row pe click karo → UserDetailPage ──
                      onTap: isUsers
                          ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(
                            user: data,
                            isDark: isDark,
                          ),
                        ),
                      )
                          : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),

                        // ── Avatar for Users ──
                        leading: isUsers
                            ? CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Text(
                            getInitials(
                                data["fullname"] ?? data["username"] ?? "U"),
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                            : section == "Categories" && data["categoryImage"] != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data["categoryImage"],
                            width: 45, height: 45, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.category, size: 45),
                          ),
                        )
                            : null,

                        title: Text(
                          isUsers
                              ? (data["fullname"] ?? data["username"] ?? "No Name")
                              : section == "Categories"
                              ? (data["categoryName"] ?? "No Name")
                              : (data["title"] ?? data["titleEnglish"] ?? "No Title"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: Text(
                          isUsers
                              ? (data["email"] ?? "")
                              : section == "Categories"
                              ? "ID: ${data["categoryId"] ?? ""}"
                              : "ID: ${data["id"] ?? data["_id"] ?? ""}",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── FCM badge + Notify button for Users ──
                            if (isUsers) ...[
                              if (hasToken)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    "FCM ✓",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.green.shade700),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    "No FCM",
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.red.shade700),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              // ── Direct Notify Button ──
                              if (hasToken)
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserDetailPage(
                                        user: data,
                                        isDark: isDark,
                                        openNotification: true, // seedha notification form kholo
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    "Notify",
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                            ] else ...[
                              // ── Normal edit/delete ──
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final id = section == "Categories"
                                      ? data["_id"]
                                      : (data["id"] ?? data["_id"]);
                                  if (id != null) {
                                    await deleteItem(endpoint, id);
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );            },
          ),
        ),
      ],
    );
  }

  /// ================= FETCH LIST =================
  Future<Map<String, dynamic>> fetchApiList(String endpoint) async {

    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/$endpoint"),
      headers: {
        "Content-Type": "application/json",
        "Authorization":ApiConstants.token

      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {
      "success": false,
      "data": []
    };
  }

  /// ================= DELETE =================
  Future<void> deleteItem(String endpoint, dynamic id) async {

    await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/$endpoint/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization":ApiConstants.token

      },
    );
  }
}