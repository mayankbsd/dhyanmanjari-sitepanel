import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mandir_live_player_screen.dart';

class Mandir {
  final String id;
  final String name;
  final String image;
  final String location;
  final String city;
  final String liveUrl;
  final bool isLive;

  Mandir({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
    required this.city,
    required this.liveUrl,
    required this.isLive,
  });

  factory Mandir.fromJson(Map<String, dynamic> json) {
    return Mandir(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      image: json["image"] ?? "",
      location: json["location"] ?? "",
      city: json["city"] ?? "",
      liveUrl: json["liveUrl"] ?? "",
      isLive: json["isLive"] ?? false,
    );
  }
}

class MandirListScreen extends StatefulWidget {
  const MandirListScreen({super.key});

  @override
  State<MandirListScreen> createState() => _MandirListScreenState();
}

class _MandirListScreenState extends State<MandirListScreen> {
  // TODO: apna actual base URL yahan set karo
  final String baseUrl = "https://your-api-domain.com/api";

  List<Mandir> _mandirs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMandirs();
  }

  Future<void> _fetchMandirs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse("$baseUrl/mandir"));
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final list = (data["data"] as List).map((e) => Mandir.fromJson(e)).toList();
        setState(() => _mandirs = list);
      } else {
        setState(() => _error = data["message"] ?? "Something went wrong");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLive(Mandir mandir) {
    if (mandir.liveUrl.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Live darshan link uplabdh nahi hai")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MandirLivePlayerScreen(
          mandirName: mandir.name,
          liveUrl: mandir.liveUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Darshan")),
      body: RefreshIndicator(
        onRefresh: _fetchMandirs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _mandirs.length,
                    itemBuilder: (context, index) {
                      final m = _mandirs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openLive(m),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: m.image.isNotEmpty
                                    ? Image.network(m.image, fit: BoxFit.cover)
                                    : Container(color: Colors.grey.shade300),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.name,
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (m.isLive)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4)),
                                          child: const Text(
                                            "LIVE",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
