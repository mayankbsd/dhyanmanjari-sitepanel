import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/content_category.dart';
import '../../network/api_service.dart';
import '../../services/content_category_api.dart';

const saffron = Color(0xFFFF6B00);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class TemplateMultipleUploadPage extends StatefulWidget {
  const TemplateMultipleUploadPage({
    super.key,
  });

  @override
  State<TemplateMultipleUploadPage> createState() =>
      _TemplateMultipleUploadPageState();
}

class _TemplateMultipleUploadPageState
    extends State<TemplateMultipleUploadPage> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final titleHiController =
  TextEditingController();

  final titleEnController =
  TextEditingController();

  final textHiController =
  TextEditingController();

  final textEnController =
  TextEditingController();

  // =========================================================
  // SERVICES
  // =========================================================

  final ContentCategoryApi categoryApi =
  ContentCategoryApi();

  // =========================================================
  // DATA
  // =========================================================

  List<ContentCategory> categories = [];

  ContentCategory? selectedCategory;

  List<XFile> selectedFiles = [];

  // =========================================================
  // STATES
  // =========================================================

  bool categoriesLoading = true;
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
    textHiController.dispose();
    textEnController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD CATEGORIES
  // =========================================================

  Future<void> loadCategories() async {
    if (!mounted) return;

    setState(() {
      categoriesLoading = true;
    });

    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'LOADING TEMPLATE CATEGORIES',
      );

      final result =
      await categoryApi.getCategories(
        'template',
      );

      debugPrint(
        'TEMPLATE CATEGORY COUNT: '
            '${result.length}',
      );

      if (!mounted) return;

      setState(() {
        categories = result;

        if (categories.isNotEmpty) {
          selectedCategory =
              categories.first;
        }

        categoriesLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'TEMPLATE CATEGORY ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        categories = [];
        selectedCategory = null;
        categoriesLoading = false;
      });

      _showMessage(
        'Template category load failed:\n$e',
        error: true,
      );
    }
  }

  // =========================================================
  // PICK MULTIPLE IMAGES
  // =========================================================

  Future<void> pickMultipleImages() async {
    if (uploading) return;

    try {
      final picker = ImagePicker();

      final results =
      await picker.pickMultiImage(
        imageQuality: 90,
      );

      if (results.isEmpty) return;

      if (!mounted) return;

      setState(() {
        selectedFiles = results;
      });

      _showMessage(
        '${selectedFiles.length} images selected',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'MULTIPLE TEMPLATE IMAGE PICK ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _showMessage(
        'Image select failed: $e',
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
  // PARSE TITLES
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
    // -------------------------------------------------------
    // IMAGES
    // -------------------------------------------------------

    if (selectedFiles.isEmpty) {
      _showMessage(
        'At least one template image select करें',
        error: true,
      );

      return false;
    }

    // -------------------------------------------------------
    // CATEGORY
    // -------------------------------------------------------

    if (selectedCategory == null) {
      _showMessage(
        'Template category select करें',
        error: true,
      );

      return false;
    }

    // -------------------------------------------------------
    // TITLES
    // -------------------------------------------------------

    final hiTitles =
    _parseTitles(
      titleHiController.text,
    );

    final enTitles =
    _parseTitles(
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

    // -------------------------------------------------------
    // HINDI COUNT
    // -------------------------------------------------------

    if (hiTitles.length !=
        selectedFiles.length) {
      _showMessage(
        'Hindi titles ${selectedFiles.length} होने चाहिए.\n'
            'अभी ${hiTitles.length} हैं.',
        error: true,
      );

      return false;
    }

    // -------------------------------------------------------
    // ENGLISH COUNT
    // -------------------------------------------------------

    if (enTitles.length !=
        selectedFiles.length) {
      _showMessage(
        'English titles ${selectedFiles.length} होने चाहिए.\n'
            'अभी ${enTitles.length} हैं.',
        error: true,
      );

      return false;
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

    setState(() {
      uploading = true;
    });

    try {
      // =====================================================
      // URI
      // =====================================================

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/templates/upload-multiple',
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        'MULTIPLE TEMPLATE UPLOAD',
      );

      debugPrint(
        'URL: $uri',
      );

      debugPrint(
        'FILES: ${selectedFiles.length}',
      );

      debugPrint(
        '========================================',
      );

      // =====================================================
      // TITLES
      // =====================================================

      final hiTitles =
      _parseTitles(
        titleHiController.text,
      );

      final enTitles =
      _parseTitles(
        titleEnController.text,
      );

      // =====================================================
      // REQUEST
      // =====================================================

      final request =
      http.MultipartRequest(
        'POST',
        uri,
      );

      // =====================================================
      // HEADERS
      // =====================================================

      request.headers[
      'Authorization'] =
          ApiConstants.token;

      // =====================================================
      // COMMON FIELDS
      // =====================================================

      request.fields['categoryId'] =
          selectedCategory!.id.toString();

      request.fields['textHi'] =
          textHiController.text.trim();

      request.fields['textEn'] =
          textEnController.text.trim();

      // =====================================================
      // TITLES
      // =====================================================
      //
      // Backend receives:
      //
      // titleHi[0]
      // titleHi[1]
      // titleHi[2]
      //
      // titleEn[0]
      // titleEn[1]
      // titleEn[2]
      //
      // =====================================================

      for (int i = 0;
      i < hiTitles.length;
      i++) {
        request.fields[
        'titleHi[$i]'] =
        hiTitles[i];
      }

      for (int i = 0;
      i < enTitles.length;
      i++) {
        request.fields[
        'titleEn[$i]'] =
        enTitles[i];
      }

      // =====================================================
      // IMAGES
      // =====================================================

      for (int i = 0;
      i < selectedFiles.length;
      i++) {
        final file =
        selectedFiles[i];

        debugPrint(
          'Reading image $i: '
              '${file.name}',
        );

        final bytes =
        await file.readAsBytes();

        debugPrint(
          'Image $i size: '
              '${bytes.length} bytes',
        );

        if (bytes.isEmpty) {
          throw Exception(
            'Unable to read image: '
                '${file.name}',
          );
        }

        // IMPORTANT:
        // Same field name "media"
        // multiple times.
        request.files.add(
          http.MultipartFile.fromBytes(
            'media',
            bytes,
            filename: file.name,
          ),
        );

        debugPrint(
          'Image $i added to multipart',
        );
      }

      // =====================================================
      // SEND
      // =====================================================

      debugPrint(
        'Sending multiple template request...',
      );

      final streamedResponse =
      await request.send();

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'Response status: '
            '${response.statusCode}',
      );

      debugPrint(
        'Response body: '
            '${response.body}',
      );

      if (!mounted) return;

      // =====================================================
      // SUCCESS
      // =====================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        _showMessage(
          '${selectedFiles.length} templates uploaded successfully',
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

        return;
      }

      // =====================================================
      // ERROR
      // =====================================================

      String message =
          'Template upload failed '
          '(${response.statusCode})';

      try {
        final body =
        jsonDecode(
          response.body,
        );

        if (body is Map) {
          message =
              (body['message'] ??
                  body['error'] ??
                  message)
                  .toString();
        }
      } catch (_) {
        message =
        'Server returned non-JSON response '
            '(${response.statusCode})';
      }

      throw Exception(message);
    } catch (e, stackTrace) {
      debugPrint(
        'MULTIPLE TEMPLATE UPLOAD ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: error
            ? Colors.red
            : success
            ? Colors.green
            : brown,
        content: Text(message),
        duration:
        const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Multiple Template Upload',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 800,
          ),

          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                // =================================================
                // INFO
                // =================================================

                _buildInfoCard(),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // CATEGORY
                // =================================================

                _label(
                  'Template Category',
                ),

                _buildCategoryDropdown(),

                const SizedBox(
                  height: 22,
                ),

                // =================================================
                // IMAGES
                // =================================================

                _label(
                  'Template Images',
                ),

                _buildMediaSection(),

                const SizedBox(
                  height: 22,
                ),

                // =================================================
                // HINDI TITLES
                // =================================================

                _label(
                  'Hindi Titles',
                ),

                TextFormField(
                  controller:
                  titleHiController,

                  maxLines: 5,

                  enabled: !uploading,

                  style:
                  const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'शुभ प्रभात, जय श्री राम, हर हर महादेव',
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildTitleCount(
                  titleHiController,
                  'Hindi',
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // ENGLISH TITLES
                // =================================================

                _label(
                  'English Titles',
                ),

                TextFormField(
                  controller:
                  titleEnController,

                  maxLines: 5,

                  enabled: !uploading,

                  style:
                  const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'Good Morning, Jai Shri Ram, Har Har Mahadev',
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildTitleCount(
                  titleEnController,
                  'English',
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // HINDI CONTENT
                // =================================================

                _label(
                  'Hindi Content',
                ),

                TextFormField(
                  controller:
                  textHiController,

                  maxLines: 5,

                  enabled: !uploading,

                  style:
                  const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'यहाँ Hindi content लिखें',
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // ENGLISH CONTENT
                // =================================================

                _label(
                  'English Content',
                ),

                TextFormField(
                  controller:
                  textEnController,

                  maxLines: 5,

                  enabled: !uploading,

                  style:
                  const TextStyle(
                    color: brown,
                  ),

                  decoration:
                  _decoration(
                    'Enter English content',
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // =================================================
                // UPLOAD
                // =================================================

                SizedBox(
                  width:
                  double.infinity,
                  height: 54,

                  child:
                  ElevatedButton.icon(
                    onPressed:
                    uploading
                        ? null
                        : uploadAll,

                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      saffron,

                      foregroundColor:
                      Colors.white,

                      disabledBackgroundColor:
                      saffron
                          .withOpacity(
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
                        strokeWidth:
                        2,
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

                const SizedBox(
                  height: 10,
                ),

                if (selectedFiles
                    .isNotEmpty)
                  Center(
                    child: Text(
                      '${selectedFiles.length} templates selected',
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
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

      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color:
        saffron.withOpacity(.08),

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

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              'Multiple template images select करें. '
                  'Hindi और English titles comma (,) से अलग करें. '
                  'Title का order selected images के order से match होना चाहिए. '
                  'Hindi और English content सभी templates में same रहेगा.',

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
    if (categoriesLoading) {
      return Container(
        height: 56,

        decoration:
        BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(
            12,
          ),
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

        decoration:
        BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(
            12,
          ),

          border: Border.all(
            color:
            Colors.red.withOpacity(
              .2,
            ),
          ),
        ),

        child: const Text(
          'No template category available',
          style: TextStyle(
            color: Colors.red,
            fontWeight:
            FontWeight.w600,
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
        InkWell(
          onTap: uploading
              ? null
              : pickMultipleImages,

          borderRadius:
          BorderRadius.circular(
            18,
          ),

          child: Container(
            width: double.infinity,

            padding:
            const EdgeInsets
                .symmetric(
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
                color: saffron
                    .withOpacity(
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
                        .withOpacity(
                      .1,
                    ),
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
                  'Select Multiple Images',
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
                  'Template images',
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : pickMultipleImages,

                  style:
                  OutlinedButton
                      .styleFrom(
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

                  label:
                  const Text(
                    'Select Images',
                  ),
                ),
              ],
            ),
          ),
        ),

        if (selectedFiles
            .isNotEmpty)
          const SizedBox(
            height: 14,
          ),

        if (selectedFiles
            .isNotEmpty)
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

      padding:
      const EdgeInsets.all(14),

      decoration:
      BoxDecoration(
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
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  '${selectedFiles.length} images selected',
                  style:
                  const TextStyle(
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

                child:
                const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const Divider(),

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

      decoration:
      BoxDecoration(
        color: cream,

        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),

      child: Row(
        children: [
          // -------------------------------------------------
          // NUMBER
          // -------------------------------------------------

          Container(
            width: 32,
            height: 32,

            alignment:
            Alignment.center,

            decoration:
            BoxDecoration(
              color: saffron
                  .withOpacity(.12),

              borderRadius:
              BorderRadius.circular(
                8,
              ),
            ),

            child: Text(
              '${index + 1}',
              style:
              const TextStyle(
                color: saffron,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // -------------------------------------------------
          // THUMBNAIL
          // -------------------------------------------------

          FutureBuilder<Uint8List>(
            future:
            file.readAsBytes(),

            builder:
                (context, snapshot) {
              if (snapshot
                  .connectionState ==
                  ConnectionState
                      .waiting) {
                return Container(
                  width: 50,
                  height: 50,

                  decoration:
                  BoxDecoration(
                    color: Colors
                        .white,

                    borderRadius:
                    BorderRadius
                        .circular(
                      8,
                    ),
                  ),

                  child:
                  const Center(
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: saffron,
                    ),
                  ),
                );
              }

              if (snapshot
                  .hasData &&
                  snapshot.data!
                      .isNotEmpty) {
                return ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    8,
                  ),

                  child:
                  Image.memory(
                    snapshot.data!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                );
              }

              return Container(
                width: 50,
                height: 50,

                decoration:
                BoxDecoration(
                  color: Colors
                      .white,

                  borderRadius:
                  BorderRadius
                      .circular(
                    8,
                  ),
                ),

                child:
                const Icon(
                  Icons
                      .broken_image,
                  color: saffron,
                ),
              );
            },
          ),

          const SizedBox(
            width: 10,
          ),

          // -------------------------------------------------
          // NAME
          // -------------------------------------------------

          Expanded(
            child: Text(
              file.name,

              maxLines: 2,

              overflow:
              TextOverflow.ellipsis,

              style:
              const TextStyle(
                color: brown,
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          // -------------------------------------------------
          // REMOVE
          // -------------------------------------------------

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
        _parseTitles(
          value.text,
        );

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

            const SizedBox(
              width: 5,
            ),

            Text(
              '$language titles: '
                  '${titles.length} / '
                  '$filesCount',

              style: TextStyle(
                color: matched
                    ? Colors.green
                    : Colors
                    .grey
                    .shade600,

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

        style:
        const TextStyle(
          color: brown,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }

  // =========================================================
  // DECORATION
  // =========================================================

  InputDecoration _decoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        color:
        Colors.grey.shade500,
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets
          .symmetric(
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