import 'package:flutter/material.dart';

import '../../models/content_category.dart';
import '../../models/status_model.dart';
import '../../services/content_category_api.dart';
import '../../services/status_api.dart';
import 'status_form_page.dart';

const saffron = Color(0xFFFF6B00);
const amber = Color(0xFFD4A017);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class StatusListPage extends StatefulWidget {
  const StatusListPage({super.key});

  @override
  State<StatusListPage> createState() =>
      _StatusListPageState();
}

class _StatusListPageState
    extends State<StatusListPage> {
  final StatusApi _api = StatusApi();
  final ContentCategoryApi _categoryApi =
  ContentCategoryApi();

  List<StatusModel> statuses = [];
  List<ContentCategory> categories = [];

  bool loading = true;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        _api.getStatuses(
          categoryId: selectedCategory,
        ),
        _categoryApi.getCategories('status'),
      ]);

      if (!mounted) return;

      setState(() {
        statuses =
        results[0] as List<StatusModel>;
        categories =
        results[1] as List<ContentCategory>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  Future<void> deleteStatus(
      StatusModel item) async {
    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Status?',
        ),
        content: Text(
          'क्या आप "${item.title}" को delete करना चाहते हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteStatus(item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Status deleted successfully'),
        ),
      );

      loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: const Text(
          'Status Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const StatusFormPage(),
            ),
          );

          loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Status',
        ),
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: loading
                ? const Center(
              child:
              CircularProgressIndicator(
                color: saffron,
              ),
            )
                : statuses.isEmpty
                ? _empty()
                : RefreshIndicator(
              onRefresh: loadData,
              child: ListView.builder(
                padding:
                const EdgeInsets.all(
                  20,
                ),
                itemCount:
                statuses.length,
                itemBuilder:
                    (_, index) {
                  return _statusCard(
                    statuses[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Category:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<
                String>(
              value: selectedCategory,
              decoration:
              const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All Categories',
                  ),
                ),
                ...categories.map(
                      (category) =>
                      DropdownMenuItem(
                        value:
                        category.id.toString(),
                        child: Text(
                          category.nameHi,
                        ),
                      ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedCategory = value;
                });

                loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(StatusModel item) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
            saffron.withOpacity(.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          _mediaPreview(item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                    saffron.withOpacity(.1),
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.categoryName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w700,
                      color: deepOr,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StatusFormPage(
                        status: item,
                      ),
                ),
              );

              loadData();
            },
            icon: const Icon(
              Icons.edit_rounded,
              color: deepOr,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () =>
                deleteStatus(item),
            icon: const Icon(
              Icons.delete_rounded,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPreview(
      StatusModel item) {
    return ClipRRect(
      borderRadius:
      BorderRadius.circular(14),
      child: SizedBox(
        width: 80,
        height: 100,
        child: item.mediaType == 'video'
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.thumbnailUrl
                  .isNotEmpty
                  ? item.thumbnailUrl
                  : item.mediaUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                  _placeholder(),
            ),
            const Center(
              child: CircleAvatar(
                backgroundColor:
                Colors.black54,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        )
            : Image.network(
          item.mediaUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
              _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: saffron.withOpacity(.1),
      child: const Icon(
        Icons.image,
        color: deepOr,
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text(
        'कोई Status उपलब्ध नहीं है',
        style: TextStyle(
          color: brown,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}