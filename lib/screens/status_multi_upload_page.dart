import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/content_category.dart';
import '../../services/content_category_api.dart';
import '../../services/status_api.dart';

const saffron = Color(0xFFFF6B00);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class StatusMultipleUploadPage extends StatefulWidget {
  const StatusMultipleUploadPage({
    super.key,
  });

  @override
  State<StatusMultipleUploadPage> createState() =>
      _StatusMultipleUploadPageState();
}

class _StatusMultipleUploadPageState
    extends State<StatusMultipleUploadPage> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final titleHiController = TextEditingController();
  final titleEnController = TextEditingController();
  final durationController = TextEditingController();

  // =========================================================
  // SERVICES
  // =========================================================

  final StatusApi api = StatusApi();
  final ContentCategoryApi categoryApi = ContentCategoryApi();

  // =========================================================
  // DATA
  // =========================================================

  List<ContentCategory> categories = [];

  ContentCategory? selectedCategory;

  List<XFile> selectedFiles = [];

  // =========================================================
  // STATES
  // =========================================================

  bool loadingCategories = true;
  bool uploading = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    titleHiController.dispose();
    titleEnController.dispose();
    durationController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD CATEGORIES
  // =========================================================

  Future<void> loadCategories() async {
    if (!mounted) return;

    setState(() {
      loadingCategories = true;
    });

    try {
      final data =
      await categoryApi.getCategories('status');

      if (!mounted) return;

      setState(() {
        categories = data;

        if (categories.isNotEmpty) {
          selectedCategory = categories.first;
        }

        loadingCategories = false;
      });
    } catch (e) {
      debugPrint(
        'STATUS CATEGORY ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        categories = [];
        selectedCategory = null;
        loadingCategories = false;
      });

      _showMessage(
        'Category load failed: $e',
        error: true,
      );
    }
  }

  // =========================================================
  // PICK MULTIPLE MEDIA
  // =========================================================

  Future<void> pickMultipleMedia() async {
    if (uploading) return;

    try {
      final picker = ImagePicker();

      final results =
      await picker.pickMultipleMedia();

      if (results.isEmpty) return;

      if (!mounted) return;

      setState(() {
        selectedFiles = results;
      });

      _showMessage(
        '${selectedFiles.length} files selected',
      );
    } catch (e) {
      debugPrint(
        'MULTIPLE MEDIA PICK ERROR: $e',
      );

      _showMessage(
        'Media select failed: $e',
        error: true,
      );
    }
  }

  // =========================================================
  // REMOVE FILE
  // =========================================================

  void removeFile(int index) {
    if (uploading) return;

    if (index < 0 ||
        index >= selectedFiles.length) {
      return;
    }

    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================

  void clearAllFiles() {
    if (uploading) return;

    setState(() {
      selectedFiles.clear();
    });
  }

  // =========================================================
  // GET TITLES
  // =========================================================

  List<String> _parseTitles(
      String value,
      ) {
    return value
        .split(',')
        .map(
          (item) => item.trim(),
    )
        .where(
          (item) => item.isNotEmpty,
    )
        .toList();
  }

  // =========================================================
  // VALIDATE
  // =========================================================

  bool validateForm() {
    if (selectedFiles.isEmpty) {
      _showMessage(
        'At least one image/video select करें',
        error: true,
      );

      return false;
    }

    if (selectedCategory == null) {
      _showMessage(
        'Category select करें',
        error: true,
      );

      return false;
    }

    final hiTitles = _parseTitles(
      titleHiController.text,
    );

    final enTitles = _parseTitles(
      titleEnController.text,
    );

    if (hiTitles.isEmpty) {
      _showMessage(
        'Hindi titles enter करें',
        error: true,
      );

      return false;
    }

    if (enTitles.isEmpty) {
      _showMessage(
        'English titles enter करें',
        error: true,
      );

      return false;
    }

    if (hiTitles.length !=
        selectedFiles.length) {
      _showMessage(
        'Hindi titles ${selectedFiles.length} hone chahiye.\n'
            'Abhi ${hiTitles.length} hain.',
        error: true,
      );

      return false;
    }

    if (enTitles.length !=
        selectedFiles.length) {
      _showMessage(
        'English titles ${selectedFiles.length} hone chahiye.\n'
            'Abhi ${enTitles.length} hain.',
        error: true,
      );

      return false;
    }

    final durationText =
    durationController.text.trim();

    if (durationText.isNotEmpty) {
      final duration =
      int.tryParse(durationText);

      if (duration == null ||
          duration < 0) {
        _showMessage(
          'Duration valid number hona chahiye',
          error: true,
        );

        return false;
      }
    }

    return true;
  }

  // =========================================================
  // UPLOAD ALL
  // =========================================================

  Future<void> uploadAll() async {
    if (uploading) return;

    if (!validateForm()) {
      return;
    }

    final duration =
        int.tryParse(
          durationController.text.trim(),
        ) ??
            0;

    setState(() {
      uploading = true;
    });

    try {
      await api.uploadMultipleStatus(
        media: selectedFiles,
        titleHi: titleHiController.text.trim(),
        titleEn: titleEnController.text.trim(),
        categoryId: selectedCategory!.id,
        durationSeconds: duration,
      );

      if (!mounted) return;

      _showMessage(
        '${selectedFiles.length} statuses uploaded successfully',
        success: true,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      debugPrint(
        'MULTIPLE STATUS UPLOAD ERROR: $e',
      );

      if (!mounted) return;

      _showMessage(
        e.toString(),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
      String message, {
        bool error = false,
        bool success = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error
            ? Colors.red
            : success
            ? Colors.green
            : brown,
        content: Text(message),
        duration: const Duration(
          seconds: 3,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Multiple Status Upload',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                // =================================================
                // INFO
                // =================================================

                _buildInfoCard(),

                const SizedBox(height: 20),

                // =================================================
                // CATEGORY
                // =================================================

                _label('Category'),

                _buildCategoryDropdown(),

                const SizedBox(height: 22),

                // =================================================
                // MEDIA
                // =================================================

                _label(
                  'Images / Videos',
                ),

                _buildMediaSection(),

                const SizedBox(height: 22),

                // =================================================
                // HINDI TITLE
                // =================================================

                _label(
                  'Hindi Names',
                ),

                TextFormField(
                  controller:
                  titleHiController,

                  maxLines: 5,

                  enabled: !uploading,

                  style: const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'शुभ प्रभात, शुभ संध्या, जय श्री राम',
                  ),
                ),

                const SizedBox(height: 8),

                _buildTitleCount(
                  titleHiController,
                  'Hindi',
                ),

                const SizedBox(height: 20),

                // =================================================
                // ENGLISH TITLE
                // =================================================

                _label(
                  'English Names',
                ),

                TextFormField(
                  controller:
                  titleEnController,

                  maxLines: 5,

                  enabled: !uploading,

                  style: const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'Good Morning, Good Evening, Jai Shri Ram',
                  ),
                ),

                const SizedBox(height: 8),

                _buildTitleCount(
                  titleEnController,
                  'English',
                ),

                const SizedBox(height: 20),

                // =================================================
                // DURATION
                // =================================================

                _label(
                  'Duration (Video only)',
                ),

                TextFormField(
                  controller:
                  durationController,

                  enabled: !uploading,

                  keyboardType:
                  TextInputType.number,

                  decoration:
                  _decoration(
                    'Example: 10',
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // UPLOAD BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child:
                  ElevatedButton.icon(
                    onPressed:
                    uploading
                        ? null
                        : uploadAll,

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      saffron,
                      foregroundColor:
                      Colors.white,

                      disabledBackgroundColor:
                      saffron.withOpacity(
                        .5,
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),
                    ),

                    icon: uploading
                        ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .cloud_upload_rounded,
                    ),

                    label: Text(
                      uploading
                          ? 'Uploading...'
                          : 'Upload All'
                          ' (${0})',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (selectedFiles.isNotEmpty)
                  Center(
                    child: Text(
                      '${selectedFiles.length} media selected',
                      style: TextStyle(
                        color:
                        Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFO CARD
  // =========================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: saffron.withOpacity(.08),

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          saffron.withOpacity(.2),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.info_outline,
            color: saffron,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Multiple images/videos select करें. '
                  'Hindi और English names comma (,) से अलग करें. '
                  'Names का order selected media के order से match होना चाहिए.',
              style: TextStyle(
                color: brown,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
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
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(12),
        ),

        child: const Center(
          child:
          CircularProgressIndicator(
            color: saffron,
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return Container(
        width: double.infinity,

        padding:
        const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(12),

          border: Border.all(
            color:
            Colors.red.withOpacity(.2),
          ),
        ),

        child: const Text(
          'No status category available',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return DropdownButtonFormField<
        ContentCategory>(
      value: selectedCategory,

      isExpanded: true,

      decoration:
      _decoration(
        'Select Category',
      ),

      items: categories.map(
            (category) {
          return DropdownMenuItem<
              ContentCategory>(
            value: category,

            child: Text(
              category.name,
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),

      onChanged: uploading
          ? null
          : (value) {
        setState(() {
          selectedCategory =
              value;
        });
      },
    );
  }

  // =========================================================
  // MEDIA SECTION
  // =========================================================

  Widget _buildMediaSection() {
    return Column(
      children: [
        // ================================================
        // SELECT BUTTON
        // ================================================

        InkWell(
          onTap: uploading
              ? null
              : pickMultipleMedia,

          borderRadius:
          BorderRadius.circular(18),

          child: Container(
            width: double.infinity,

            padding:
            const EdgeInsets.symmetric(
              vertical: 28,
              horizontal: 20,
            ),

            decoration:
            BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.circular(
                18,
              ),

              border: Border.all(
                color:
                saffron.withOpacity(
                  .3,
                ),
                width: 1.3,
              ),
            ),

            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,

                  decoration:
                  BoxDecoration(
                    color: saffron
                        .withOpacity(.1),
                    shape:
                    BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons
                        .collections_outlined,
                    color: saffron,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'Select Multiple Media',
                  style: TextStyle(
                    color: brown,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Images या Videos',
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : pickMultipleMedia,

                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    saffron,

                    side:
                    const BorderSide(
                      color: saffron,
                    ),
                  ),

                  icon: const Icon(
                    Icons.add,
                  ),

                  label: const Text(
                    'Select Files',
                  ),
                ),
              ],
            ),
          ),
        ),

        // ================================================
        // SELECTED FILES
        // ================================================

        if (selectedFiles.isNotEmpty)
          const SizedBox(height: 14),

        if (selectedFiles.isNotEmpty)
          _buildSelectedFiles(),
      ],
    );
  }

  // =========================================================
  // SELECTED FILES
  // =========================================================

  Widget _buildSelectedFiles() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          saffron.withOpacity(.2),
        ),
      ),

      child: Column(
        children: [
          // ==============================================
          // HEADER
          // ==============================================

          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '${selectedFiles.length} files selected',
                  style: const TextStyle(
                    color: brown,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              TextButton(
                onPressed:
                uploading
                    ? null
                    : clearAllFiles,
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const Divider(),

          // ==============================================
          // FILE LIST
          // ==============================================

          ...selectedFiles
              .asMap()
              .entries
              .map(
                (entry) {
              final index =
                  entry.key;

              final file =
                  entry.value;

              return _buildFileRow(
                index,
                file,
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILE ROW
  // =========================================================

  Widget _buildFileRow(
      int index,
      XFile file,
      ) {
    final name =
    file.name.toLowerCase();

    final isVideo =
        name.endsWith('.mp4') ||
            name.endsWith('.mov') ||
            name.endsWith('.avi') ||
            name.endsWith('.mkv') ||
            name.endsWith('.webm') ||
            name.endsWith('.m4v');

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: cream,

        borderRadius:
        BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          // =============================================
          // NUMBER
          // =============================================

          Container(
            width: 32,
            height: 32,

            alignment:
            Alignment.center,

            decoration:
            BoxDecoration(
              color:
              saffron.withOpacity(
                .12,
              ),

              borderRadius:
              BorderRadius.circular(
                8,
              ),
            ),

            child: Text(
              '${index + 1}',

              style: const TextStyle(
                color: saffron,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // =============================================
          // ICON
          // =============================================

          Icon(
            isVideo
                ? Icons
                .video_library_outlined
                : Icons
                .image_outlined,

            color: isVideo
                ? deepOr
                : saffron,

            size: 22,
          ),

          const SizedBox(width: 10),

          // =============================================
          // NAME
          // =============================================

          Expanded(
            child: Text(
              file.name,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style: const TextStyle(
                color: brown,
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          // =============================================
          // REMOVE
          // =============================================

          IconButton(
            onPressed: uploading
                ? null
                : () {
              removeFile(index);
            },

            icon: const Icon(
              Icons.close,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TITLE COUNT
  // =========================================================

  Widget _buildTitleCount(
      TextEditingController controller,
      String language,
      ) {
    return ValueListenableBuilder<
        TextEditingValue>(
      valueListenable: controller,

      builder:
          (context, value, child) {
        final titles =
        _parseTitles(value.text);

        final filesCount =
            selectedFiles.length;

        final matched =
            filesCount > 0 &&
                titles.length ==
                    filesCount;

        return Row(
          children: [
            Icon(
              matched
                  ? Icons.check_circle
                  : Icons.info_outline,

              size: 15,

              color: matched
                  ? Colors.green
                  : Colors.grey,
            ),

            const SizedBox(width: 5),

            Text(
              '$language titles: ${titles.length}'
                  ' / $filesCount',

              style: TextStyle(
                color: matched
                    ? Colors.green
                    : Colors.grey.shade600,

                fontSize: 12,

                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _label(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),

      child: Text(
        text,

        style: const TextStyle(
          color: brown,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _decoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        color: Colors.grey.shade500,
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),

        borderSide:
        BorderSide.none,
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),

        borderSide:
        BorderSide.none,
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),

        borderSide:
        const BorderSide(
          color: saffron,
          width: 1.5,
        ),
      ),
    );
  }
}