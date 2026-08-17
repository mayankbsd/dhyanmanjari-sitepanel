import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/status_model.dart';
import '../network/api_service.dart';
import '../pages/status/status_form_page.dart';
import '../pages/template/template_form_page.dart';

class StatusTemplateManagementPage extends StatefulWidget {
  const StatusTemplateManagementPage({
    super.key,
    this.isDark = false,
  });

  final bool isDark;

  @override
  State<StatusTemplateManagementPage> createState() =>
      _StatusTemplateManagementPageState();
}

class _StatusTemplateManagementPageState
    extends State<StatusTemplateManagementPage> {

  // =========================================================
  // MAIN TAB
  // =========================================================

  int selectedTab = 0;

  // 0 = Status
  // 1 = Template

  // =========================================================
  // DATA
  // =========================================================

  List<Map<String, dynamic>> categories = [];

  List<Map<String, dynamic>> items = [];

  bool loadingCategories = true;
  bool loadingItems = false;

  String? selectedCategoryId;

  String searchText = '';

  // =========================================================
  // COLORS
  // =========================================================

  Color get primaryColor => const Color(0xffd97706);

  Color get backgroundColor =>
      widget.isDark ? const Color(0xff121212) : const Color(0xfff6f7fb);

  Color get cardColor =>
      widget.isDark ? const Color(0xff1e1e1e) : Colors.white;

  Color get textColor =>
      widget.isDark ? Colors.white : const Color(0xff222222);

  Color get subTextColor =>
      widget.isDark ? Colors.white60 : Colors.grey.shade600;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  // =========================================================
  // CURRENT TYPE
  // =========================================================

  String get currentType {
    return selectedTab == 0 ? 'status' : 'template';
  }

  String get currentTitle {
    return selectedTab == 0 ? 'Status Management' : 'Template Management';
  }

  // =========================================================
  // CATEGORY API
  // =========================================================

  Future<void> loadCategories() async {
    setState(() {
      loadingCategories = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/content-categories?type=$currentType',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': ApiConstants.token,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final List<dynamic> list = body['data'] ?? [];

        categories = list
            .map(
              (e) => Map<String, dynamic>.from(e),
        )
            .toList();

        if (categories.isNotEmpty) {
          selectedCategoryId =
              categories.first['_id']?.toString() ??
                  categories.first['id']?.toString();
        } else {
          selectedCategoryId = null;
        }
      }
    } catch (e) {
      debugPrint('Category error: $e');
    }

    setState(() {
      loadingCategories = false;
    });

    await loadItems();
  }

  // =========================================================
  // STATUS API
  // =========================================================

  Future<void> loadItems() async {
    setState(() {
      loadingItems = true;
    });

    try {
      String url =
          '${ApiConstants.baseUrl}/status?language=hi&limit=100';

      if (selectedCategoryId != null) {
        url += '&categoryId=$selectedCategoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': ApiConstants.token,
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final List<dynamic> list = body['data'] ?? [];

        items = list
            .map(
              (e) => Map<String, dynamic>.from(e),
        )
            .toList();
      } else {
        items = [];
      }
    } catch (e) {
      debugPrint('Status API error: $e');

      items = [];
    }

    setState(() {
      loadingItems = false;
    });
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final id = item['_id'];

    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Status'),
          content: const Text(
            'Are you sure you want to delete this status?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}/status/$id',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': ApiConstants.token,
        },
      );

      if (response.statusCode == 200) {
        _showMessage('Deleted successfully');

        await loadItems();
      } else {
        _showMessage('Delete failed');
      }
    } catch (e) {
      _showMessage('Delete error');
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  List<Map<String, dynamic>> get filteredItems {
    if (searchText.trim().isEmpty) {
      return items;
    }

    final query = searchText.toLowerCase();

    return items.where((item) {
      final title =
      (item['title'] ?? '').toString().toLowerCase();

      final category =
      (item['category']?['name'] ?? '')
          .toString()
          .toLowerCase();

      return title.contains(query) ||
          category.contains(query);
    }).toList();
  }

  // =========================================================
  // ADD
  // =========================================================

  void addItem() {
    if (selectedTab == 0) {
      // =========================
      // ADD STATUS
      // =========================
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StatusFormPage(),
        ),
      ).then((_) {
        loadItems();
      });
    } else {
      // =========================
      // ADD TEMPLATE
      // =========================
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TemplateFormPage(),
        ),
      ).then((_) {
        loadItems();
      });
    }
  }

  // =========================================================
  // EDIT
  // =========================================================

  void editItem(Map<String, dynamic> item) {
    if (selectedTab == 0) {
      // =========================
      // EDIT STATUS
      // =========================

      final status = StatusModel.fromJson(item);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusFormPage(
            status: status,
          ),
        ),
      ).then((_) {
        loadItems();
      });
    } else {
      // =========================
      // EDIT TEMPLATE
      // =========================

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateFormPage(
            template: item,
          ),
        ),
      ).then((_) {
        loadItems();
      });
    }
  }

  // =========================================================
  // TAB CHANGE
  // =========================================================

  Future<void> changeTab(int index) async {
    if (selectedTab == index) return;

    setState(() {
      selectedTab = index;
      categories = [];
      items = [];
      selectedCategoryId = null;
    });

    await loadCategories();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,

        title: Text(
          currentTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await loadCategories();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            // =================================================
            // STATUS / TEMPLATE TABS
            // =================================================

            Row(
              children: [

                Expanded(
                  child: _tabButton(
                    title: 'Status',
                    icon: Icons.image,
                    index: 0,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _tabButton(
                    title: 'Templates',
                    icon: Icons.dashboard_customize,
                    index: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =================================================
            // CATEGORY + SEARCH + ADD
            // =================================================

            Row(
              children: [

                // CATEGORY
                Expanded(
                  flex: 2,
                  child: _buildCategoryDropdown(),
                ),

                const SizedBox(width: 16),

                // SEARCH
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },

                    style: TextStyle(
                      color: textColor,
                    ),

                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon:
                      const Icon(Icons.search),

                      filled: true,
                      fillColor: cardColor,

                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ADD BUTTON
                ElevatedButton.icon(
                  onPressed: addItem,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),

                  icon: const Icon(Icons.add),

                  label: Text(
                    selectedTab == 0
                        ? 'Add Status'
                        : 'Add Template',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =================================================
            // LIST
            // =================================================

            Expanded(
              child: loadingItems
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : filteredItems.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                itemCount:
                filteredItems.length,

                itemBuilder:
                    (context, index) {

                  final item =
                  filteredItems[index];

                  return _buildItemCard(
                    item,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TAB BUTTON
  // =========================================================

  Widget _tabButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final selected =
        selectedTab == index;

    return InkWell(
      borderRadius:
      BorderRadius.circular(14),

      onTap: () {
        changeTab(index);
      },

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 16,
        ),

        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : cardColor,

          borderRadius:
          BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,
          ),
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              color: selected
                  ? Colors.white
                  : primaryColor,
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : textColor,

                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CATEGORY DROPDOWN
  // =========================================================

  Widget _buildCategoryDropdown() {
    if (loadingCategories) {
      return Container(
        height: 56,

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
          BorderRadius.circular(12),
        ),

        child: const Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedCategoryId,

      dropdownColor: cardColor,

      style: TextStyle(
        color: textColor,
      ),

      decoration: InputDecoration(
        labelText: selectedTab == 0
            ? 'Status Category'
            : 'Template Category',

        prefixIcon:
        const Icon(Icons.category),

        filled: true,
        fillColor: cardColor,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),

          borderSide: BorderSide.none,
        ),
      ),

      items: categories.map((category) {

        final id =
        (category['_id'] ??
            category['id'])
            .toString();

        final name =
        category['name'] is Map
            ? (
            category['name']['hi'] ??
                category['name']['en'] ??
                ''
        ).toString()
            : (category['name'] ??
            category['categoryName'] ??
            '')
            .toString();

        return DropdownMenuItem<String>(
          value: id,

          child: Text(
            name,
            overflow:
            TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: (value) async {
        setState(() {
          selectedCategoryId = value;
        });

        await loadItems();
      },
    );
  }

  // =========================================================
  // ITEM CARD
  // =========================================================

  Widget _buildItemCard(
      Map<String, dynamic> item,
      ) {
    final title =
    (item['title'] ?? 'No Title').toString();

    final categoryName =
    (item['category']?['name'] ?? '')
        .toString();

    final mediaType =
    (item['mediaType'] ?? 'image')
        .toString();

    final thumbnail =
    (item['thumbnailUrl'] ?? '')
        .toString();

    final mediaUrl =
    (item['mediaUrl'] ?? '')
        .toString();

    return Card(
      color: cardColor,

      elevation: 1,

      margin:
      const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(12),

        child: Row(
          children: [

            // =============================================
            // THUMBNAIL
            // =============================================

            _buildThumbnail(
              mediaType,
              thumbnail,
              mediaUrl,
            ),

            const SizedBox(width: 16),

            // =============================================
            // CONTENT
            // =============================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    maxLines: 2,

                    overflow:
                    TextOverflow.ellipsis,

                    style: TextStyle(
                      color: textColor,

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [

                      if (categoryName
                          .isNotEmpty)
                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),

                          decoration:
                          BoxDecoration(
                            color: primaryColor
                                .withOpacity(.1),

                            borderRadius:
                            BorderRadius
                                .circular(
                                6),
                          ),

                          child: Text(
                            categoryName,

                            style: TextStyle(
                              color:
                              primaryColor,

                              fontSize: 12,

                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),

                      Text(
                        'ID: ${item['_id'] ?? ''}',

                        style: TextStyle(
                          color:
                          subTextColor,

                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    mediaType.toUpperCase(),

                    style: TextStyle(
                      color: subTextColor,

                      fontSize: 11,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // =============================================
            // ACTIONS
            // =============================================

            IconButton(
              tooltip: 'Edit',

              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.blue,
              ),

              onPressed: () {
                editItem(item);
              },
            ),

            IconButton(
              tooltip: 'Delete',

              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),

              onPressed: () {
                deleteItem(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // THUMBNAIL
  // =========================================================

  Widget _buildThumbnail(
      String mediaType,
      String thumbnail,
      String mediaUrl,
      ) {
    String imageUrl = thumbnail;

    if (imageUrl.isEmpty &&
        mediaType == 'image') {
      imageUrl = mediaUrl;
    }

    if (imageUrl.isEmpty) {
      return Container(
        width: 75,
        height: 75,

        decoration: BoxDecoration(
          color: Colors.grey.shade200,

          borderRadius:
          BorderRadius.circular(10),
        ),

        child: Icon(
          mediaType == 'video'
              ? Icons.video_library
              : Icons.image,

          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(10),

      child: Image.network(
        imageUrl,

        width: 75,
        height: 75,

        fit: BoxFit.cover,

        errorBuilder:
            (context, error, stack) {
          return Container(
            width: 75,
            height: 75,

            color: Colors.grey.shade200,

            child: const Icon(
              Icons.broken_image,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(
            selectedTab == 0
                ? Icons.image_not_supported
                : Icons.dashboard_customize_outlined,

            size: 70,

            color: Colors.grey,
          ),

          const SizedBox(height: 16),

          Text(
            selectedTab == 0
                ? 'No Status Found'
                : 'No Template Found',

            style: TextStyle(
              color: textColor,

              fontSize: 20,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            selectedCategoryId == null
                ? 'Select a category or add a new item'
                : 'No items available in this category',

            style: TextStyle(
              color: subTextColor,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: addItem,

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              primaryColor,

              foregroundColor:
              Colors.white,
            ),

            icon:
            const Icon(Icons.add),

            label: Text(
              selectedTab == 0
                  ? 'Add Status'
                  : 'Add Template',
            ),
          ),
        ],
      ),
    );
  }
}