import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/content_category.dart';
import '../../network/api_service.dart';
import '../../services/content_category_api.dart';
import 'dart:typed_data';
const saffron = Color(0xFFFF6B00);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class TemplateFormPage extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? template;

  const TemplateFormPage({
    super.key,
    this.isEdit = false,
    this.template,
  });

  @override
  State<TemplateFormPage> createState() =>
      _TemplateFormPageState();
}

class _TemplateFormPageState
    extends State<TemplateFormPage> {
  final _formKey =
  GlobalKey<FormState>();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final titleHi =
  TextEditingController();

  final titleEn =
  TextEditingController();

  final textHi =
  TextEditingController();

  final textEn =
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

  // IMPORTANT:
  // File -> XFile
  XFile? selectedFile;

  // =========================================================
  // STATES
  // =========================================================

  bool loading = false;
  bool categoriesLoading = true;

  // =========================================================
  // EDIT
  // =========================================================

  bool get isEdit =>
      widget.isEdit &&
          widget.template != null;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _fillEditData();
    }

    loadCategories();
  }

  // =========================================================
  // FILL EDIT DATA
  // =========================================================

  void _fillEditData() {
    final data =
    widget.template!;

    titleHi.text =
        (data['titleHi'] ??
            data['title'] ??
            '')
            .toString();

    titleEn.text =
        (data['titleEn'] ??
            data['titleEnglish'] ??
            '')
            .toString();

    textHi.text =
        (data['textHi'] ??
            data['contentHi'] ??
            '')
            .toString();

    textEn.text =
        (data['textEn'] ??
            data['contentEn'] ??
            '')
            .toString();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    titleHi.dispose();
    titleEn.dispose();
    textHi.dispose();
    textEn.dispose();

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
        '==============================',
      );

      debugPrint(
        'LOADING TEMPLATE CATEGORIES',
      );

      debugPrint(
        '==============================',
      );

      final result =
      await categoryApi
          .getCategories('template');

      debugPrint(
        'TEMPLATE CATEGORY COUNT: '
            '${result.length}',
      );

      for (final category in result) {
        debugPrint(
          'CATEGORY => '
              'id=${category.id}, '
              'name=${category.name}, '
              'nameEn=${category.nameEn}',
        );
      }

      ContentCategory?
      editCategory;

      // =====================================================
      // EDIT CATEGORY
      // =====================================================

      if (isEdit) {
        final data =
        widget.template!;

        dynamic categoryId;

        if (data['category'] is Map) {
          categoryId =
              data['category']['_id'] ??
                  data['category']['id'] ??
                  data['category']['categoryId'];
        } else {
          categoryId =
              data['categoryId'] ??
                  data['category'];
        }

        debugPrint(
          'TEMPLATE CATEGORY ID: '
              '$categoryId',
        );

        if (categoryId != null) {
          for (final category
          in result) {
            if (category.id.toString() ==
                categoryId.toString()) {
              editCategory =
                  category;
              break;
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        categories = result;
        selectedCategory =
            editCategory;
        categoriesLoading = false;
      });

      debugPrint(
        'FINAL CATEGORY COUNT: '
            '${categories.length}',
      );

      debugPrint(
        '==============================',
      );
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Template category load failed:\n$e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> pickImage() async {
    if (loading) return;

    try {
      final picker =
      ImagePicker();

      final XFile? result =
      await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (result == null) return;

      debugPrint(
        'TEMPLATE IMAGE SELECTED: '
            '${result.name}',
      );

      if (!mounted) return;

      setState(() {
        selectedFile = result;
      });
    } catch (e) {
      debugPrint(
        'TEMPLATE IMAGE PICK ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Image select failed: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> save() async {
    if (loading) return;

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Template category select करें',
          ),
        ),
      );

      return;
    }

    // ADD MODE
    if (!isEdit &&
        selectedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Template image select करें',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/template/upload',
      );

      debugPrint(
        '========================================',
      );

      debugPrint(
        'TEMPLATE SAVE',
      );

      debugPrint(
        'MODE: '
            '${isEdit ? 'EDIT' : 'ADD'}',
      );

      debugPrint(
        'URL: $uri',
      );

      debugPrint(
        '========================================',
      );

      final request =
      http.MultipartRequest(
        isEdit ? 'PUT' : 'POST',
        uri,
      );

      // =====================================================
      // HEADERS
      // =====================================================

      request.headers[
      'Authorization'] =
          ApiConstants.token;

      // =====================================================
      // FIELDS
      // =====================================================

      request.fields['titleHi'] =
          titleHi.text.trim();

      request.fields['titleEn'] =
          titleEn.text.trim();

      request.fields['textHi'] =
          textHi.text.trim();

      request.fields['textEn'] =
          textEn.text.trim();

      request.fields['categoryId'] =
          selectedCategory!.id
              .toString();

      // =====================================================
      // EDIT ID
      // =====================================================

      if (isEdit &&
          widget.template != null) {
        final id =
            widget.template!['_id'] ??
                widget.template!['id'];

        if (id != null) {
          request.fields['id'] =
              id.toString();
        }
      }

      // =====================================================
      // IMAGE
      // =====================================================

      if (selectedFile != null) {
        debugPrint(
          'Reading image: '
              '${selectedFile!.name}',
        );

        final bytes =
        await selectedFile!
            .readAsBytes();

        debugPrint(
          'Image size: '
              '${bytes.length} bytes',
        );

        if (bytes.isEmpty) {
          throw Exception(
            'Unable to read selected image',
          );
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'media',
            bytes,
            filename:
            selectedFile!.name,
          ),
        );

        debugPrint(
          'Image added to multipart',
        );
      }

      // =====================================================
      // SEND
      // =====================================================

      debugPrint(
        'Sending template request...',
      );

      final streamedResponse =
      await request.send();

      final response =
      await http.Response
          .fromStream(
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
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor:
            Colors.green,
            content: Text(
              isEdit
                  ? 'Template updated successfully'
                  : 'Template added successfully',
            ),
          ),
        );

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
          'Template save failed '
          '(${response.statusCode})';

      try {
        final body =
        jsonDecode(
          response.body,
        );

        if (body is Map) {
          message =
              body['message'] ??
                  body['error'] ??
                  message;
        }
      } catch (_) {
        message =
        'Server returned non-JSON response '
            '(${response.statusCode})';
      }

      throw Exception(message);
    } catch (e, stackTrace) {
      debugPrint(
        'TEMPLATE SAVE ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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

        title: Text(
          isEdit
              ? 'Edit Template'
              : 'Add Template',

          style: const TextStyle(
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 700,
          ),

          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              24,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  // =================================================
                  // TITLE HI
                  // =================================================

                  _label(
                    'Title Hindi',
                  ),

                  _field(
                    titleHi,
                    'उदाहरण: श्री राम मंत्र',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // TITLE EN
                  // =================================================

                  _label(
                    'Title English',
                  ),

                  _field(
                    titleEn,
                    'Example: Shri Ram Mantra',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // CATEGORY
                  // =================================================

                  _label(
                    'Template Category',
                  ),

                  categoriesLoading
                      ? const LinearProgressIndicator(
                    color: saffron,
                  )
                      : DropdownButtonFormField<
                      ContentCategory>(
                    value:
                    selectedCategory,

                    isExpanded:
                    true,

                    decoration:
                    _decoration(
                      'Select Category',
                    ),

                    items:
                    categories
                        .map(
                          (e) {
                        return DropdownMenuItem<
                            ContentCategory>(
                          value: e,

                          child:
                          Text(
                            e.name,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        );
                      },
                    ).toList(),

                    validator:
                        (value) {
                      if (value ==
                          null) {
                        return 'Category required';
                      }

                      return null;
                    },

                    onChanged:
                    loading
                        ? null
                        : (value) {
                      setState(
                            () {
                          selectedCategory =
                              value;
                        },
                      );
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // HINDI CONTENT
                  // =================================================

                  _label(
                    'Hindi Content',
                  ),

                  _multiline(
                    textHi,
                    'यहाँ Hindi content लिखें',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // ENGLISH CONTENT
                  // =================================================

                  _label(
                    'English Content',
                  ),

                  _multiline(
                    textEn,
                    'Enter English content',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // IMAGE
                  // =================================================

                  _label(
                    'Template Image',
                  ),

                  _imagePicker(),

                  if (isEdit)
                    const Padding(
                      padding:
                      EdgeInsets.only(
                        top: 8,
                      ),
                      child: Text(
                        'New image select करना optional है.',
                        style: TextStyle(
                          color:
                          Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 28,
                  ),

                  // =================================================
                  // SAVE BUTTON
                  // =================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,

                    child:
                    ElevatedButton.icon(
                      onPressed:
                      loading
                          ? null
                          : save,

                      style:
                      ElevatedButton
                          .styleFrom(
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

                      icon: loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color: Colors
                              .white,
                        ),
                      )
                          : Icon(
                        isEdit
                            ? Icons
                            .save
                            : Icons
                            .cloud_upload,
                      ),

                      label: Text(
                        loading
                            ? isEdit
                            ? 'Updating...'
                            : 'Uploading...'
                            : isEdit
                            ? 'Update Template'
                            : 'Add Template',

                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  Widget _imagePicker() {
    return GestureDetector(
      onTap:
      loading ? null : pickImage,

      child: Container(
        width:
        double.infinity,

        height: 250,

        decoration:
        BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(
            18,
          ),

          border:
          Border.all(
            color:
            saffron.withOpacity(
              .3,
            ),
          ),
        ),

        child:
        selectedFile != null
            ? FutureBuilder<
            Uint8List>(
          future:
          selectedFile!
              .readAsBytes(),

          builder:
              (context,
              snapshot) {
            if (snapshot
                .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                CircularProgressIndicator(
                  color:
                  saffron,
                ),
              );
            }

            if (snapshot
                .hasError ||
                !snapshot.hasData ||
                snapshot
                    .data!
                    .isEmpty) {
              return const Center(
                child: Icon(
                  Icons
                      .broken_image,
                  size: 50,
                ),
              );
            }

            return ClipRRect(
              borderRadius:
              BorderRadius
                  .circular(
                18,
              ),

              child:
              Image.memory(
                snapshot.data!,
                width:
                double.infinity,
                height:
                double.infinity,
                fit: BoxFit.cover,
              ),
            );
          },
        )
            : _existingImagePreview(),
      ),
    );
  }

  // =========================================================
  // EXISTING IMAGE
  // =========================================================

  Widget _existingImagePreview() {
    if (!isEdit) {
      return const Column(
        mainAxisAlignment:
        MainAxisAlignment
            .center,

        children: [
          Icon(
            Icons
                .add_photo_alternate,
            size: 50,
            color: saffron,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Template image select करें',

            style: TextStyle(
              fontWeight:
              FontWeight.w700,
              color: brown,
            ),
          ),
        ],
      );
    }

    final imageUrl =
    _existingImage();

    if (imageUrl == null) {
      return const Column(
        mainAxisAlignment:
        MainAxisAlignment
            .center,

        children: [
          Icon(
            Icons.broken_image,
            size: 50,
            color: saffron,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'No existing image',
            style: TextStyle(
              color: brown,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            18,
          ),

          child:
          Image.network(
            imageUrl,

            width:
            double.infinity,

            height:
            double.infinity,

            fit: BoxFit.cover,

            errorBuilder:
                (_, __, ___) {
              return Container(
                color:
                Colors.grey.shade100,

                child:
                const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          right: 12,
          bottom: 12,

          child: Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration:
            BoxDecoration(
              color:
              Colors.black
                  .withOpacity(
                .65,
              ),

              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),

            child: const Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Icon(
                  Icons.edit,
                  color:
                  Colors.white,
                  size: 18,
                ),

                SizedBox(
                  width: 6,
                ),

                Text(
                  'Change Image',

                  style: TextStyle(
                    color:
                    Colors.white,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EXISTING IMAGE URL
  // =========================================================

  String? _existingImage() {
    if (!isEdit) {
      return null;
    }

    final data =
    widget.template!;

    final value =
        data['mediaUrl'] ??
            data['imageUrl'] ??
            data['thumbnailUrl'] ??
            data['media'];

    if (value == null) {
      return null;
    }

    final url =
    value.toString().trim();

    return url.isEmpty
        ? null
        : url;
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _label(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),

      child: Text(
        text,

        style:
        const TextStyle(
          fontWeight:
          FontWeight.w800,
          color: brown,
        ),
      ),
    );
  }

  // =========================================================
  // FIELD
  // =========================================================

  Widget _field(
      TextEditingController controller,
      String hint,
      ) {
    return TextFormField(
      controller: controller,

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'This field is required';
        }

        return null;
      },

      decoration:
      _decoration(hint),
    );
  }

  // =========================================================
  // MULTILINE
  // =========================================================

  Widget _multiline(
      TextEditingController controller,
      String hint,
      ) {
    return TextFormField(
      controller: controller,

      maxLines: 5,

      decoration:
      _decoration(hint),
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