import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddAartiPage extends StatefulWidget {
  final bool isDark;

  // Complete API data for edit
  final Map<String, dynamic>? editData;

  const AddAartiPage({
    super.key,
    this.isDark = false,
    this.editData,
  });

  bool get isEdit =>
      editData != null &&
          editData!["id"] != null;

  int? get aartiId {
    if (editData == null) return null;

    final value = editData!["id"];

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  String get existingImageUrl {
    return (editData?["imageUrl"] ?? "")
        .toString()
        .trim();
  }

  @override
  State<AddAartiPage> createState() =>
      _AddAartiPageState();
}

class _AddAartiPageState
    extends State<AddAartiPage> {

  final _formKey =
  GlobalKey<FormState>();

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController englishTitleController =
  TextEditingController();

  final TextEditingController durationController =
  TextEditingController();

  final TextEditingController languageController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  bool isLoading = false;

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _fillEditData();
  }

  void _fillEditData() {
    if (!widget.isEdit) return;

    final data = widget.editData!;

    titleController.text =
        (data["title"] ?? "").toString();

    englishTitleController.text =
        (data["titleEnglish"] ?? "").toString();

    durationController.text =
        (data["duration"] ?? "").toString();

    languageController.text =
        (data["language"] ?? "").toString();

    descriptionController.text =
        (data["description"] ?? "").toString();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    titleController.dispose();
    englishTitleController.dispose();
    durationController.dispose();
    languageController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      if (file.bytes == null) {
        _showMessage(
          "Image select nahi ho saki",
        );
        return;
      }

      setState(() {
        selectedImageBytes = file.bytes;
        selectedImageName = file.name;
      });
    } catch (e) {
      debugPrint(
        "IMAGE PICK ERROR: $e",
      );

      _showMessage(
        "Image select karne mein error",
      );
    }
  }

  // =========================================================
  // SAVE / UPDATE
  // =========================================================

  Future<void> _saveAarti() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final bool edit = widget.isEdit;

      late final Uri url;

      if (edit) {
        url = Uri.parse(
          "${ApiConstants.aarti}/${widget.aartiId}",
        );
      } else {
        url = Uri.parse(
          ApiConstants.aarti,
        );
      }

      debugPrint(
        "AARTI URL: $url",
      );

      debugPrint(
        "AARTI METHOD: ${edit ? "PUT" : "POST"}",
      );

      // =====================================================
      // MULTIPART REQUEST
      // =====================================================

      final request = http.MultipartRequest(
        edit ? "PUT" : "POST",
        url,
      );

      // =====================================================
      // AUTH
      // =====================================================

      request.headers["Authorization"] =
          ApiConstants.token;

      // =====================================================
      // TEXT FIELDS
      // =====================================================

      request.fields["title"] =
          titleController.text.trim();

      request.fields["titleEnglish"] =
          englishTitleController.text.trim();

      request.fields["duration"] =
      durationController.text.trim().isEmpty
          ? "5 min"
          : durationController.text.trim();

      request.fields["language"] =
      languageController.text.trim().isEmpty
          ? "Hindi"
          : languageController.text.trim();

      request.fields["description"] =
          descriptionController.text.trim();

      // =====================================================
      // IMAGE
      // =====================================================

      if (selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            selectedImageBytes!,
            filename:
            selectedImageName ?? "aarti.jpg",
          ),
        );

        debugPrint(
          "NEW AARTI IMAGE: $selectedImageName",
        );
      } else {
        debugPrint(
          "NO NEW IMAGE - KEEP EXISTING IMAGE",
        );
      }

      // =====================================================
      // SEND
      // =====================================================

      final response =
      await request.send();

      final responseBody =
      await response.stream
          .bytesToString();

      debugPrint(
        "AARTI STATUS: ${response.statusCode}",
      );

      debugPrint(
        "AARTI RESPONSE: $responseBody",
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage(
          edit
              ? "Aarti updated successfully"
              : "Aarti added successfully",
        );

        // Dashboard ko refresh signal
        Navigator.pop(
          context,
          true,
        );
      } else {
        _showMessage(
          "Failed: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint(
        "AARTI SAVE ERROR: $e",
      );

      if (mounted) {
        _showMessage(
          "Something went wrong",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // IMAGE PREVIEW
  // =========================================================

  Widget _buildImagePreview(
      Color cardColor,
      Color textColor,
      ) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green
              .withOpacity(0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(16),
        child: selectedImageBytes != null
            ? Image.memory(
          selectedImageBytes!,
          fit: BoxFit.cover,
        )
            : widget.existingImageUrl.isNotEmpty
            ? Image.network(
          widget.existingImageUrl,
          fit: BoxFit.cover,
          loadingBuilder:
              (
              context,
              child,
              loadingProgress,
              ) {
            if (loadingProgress ==
                null) {
              return child;
            }

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          },
          errorBuilder:
              (_, __, ___) {
            return _imagePlaceholder(
              textColor,
            );
          },
        )
            : _imagePlaceholder(
          textColor,
        ),
      ),
    );
  }

  Widget _imagePlaceholder(
      Color textColor,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 50,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            "Aarti Image",
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TEXT FIELD HELPER
  // =========================================================

  InputDecoration _inputDecoration(
      String hint,
      Color cardColor,
      ) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
      fillColor: cardColor,
      filled: true,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? Colors.grey[900]!
        : const Color(0xfff4f6f9);

    final cardColor = widget.isDark
        ? Colors.grey[850]!
        : Colors.white;

    final textColor = widget.isDark
        ? Colors.white
        : Colors.black87;

    const accentColor =
        Colors.green;

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? "Update Aarti"
              : "Add New Aarti",
        ),
        backgroundColor:
        accentColor,
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(24),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // =================================================
              // IMAGE
              // =================================================

              Text(
                "Aarti Image",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              _buildImagePreview(
                cardColor,
                textColor,
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,

                child:
                OutlinedButton.icon(
                  onPressed:
                  isLoading
                      ? null
                      : _pickImage,

                  icon: const Icon(
                    Icons.upload_rounded,
                  ),

                  label: Text(
                    selectedImageBytes != null
                        ? "Change Image"
                        : widget.isEdit &&
                        widget
                            .existingImageUrl
                            .isNotEmpty
                        ? "Change Image"
                        : "Select Image",
                  ),

                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    accentColor,

                    side:
                    const BorderSide(
                      color: accentColor,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // TITLE
              // =================================================

              Text(
                "Title (Hindi)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                titleController,

                decoration:
                _inputDecoration(
                  "Enter Aarti Title in Hindi",
                  cardColor,
                ),

                style: TextStyle(
                  color: textColor,
                ),

                validator: (value) =>
                value == null ||
                    value.trim().isEmpty
                    ? "Title required"
                    : null,
              ),

              const SizedBox(height: 20),

              // =================================================
              // ENGLISH TITLE
              // =================================================

              Text(
                "Title (English)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                englishTitleController,

                decoration:
                _inputDecoration(
                  "Enter Aarti Title in English",
                  cardColor,
                ),

                style: TextStyle(
                  color: textColor,
                ),

                validator: (value) =>
                value == null ||
                    value.trim().isEmpty
                    ? "English Title required"
                    : null,
              ),

              const SizedBox(height: 20),

              // =================================================
              // DURATION
              // =================================================

              Text(
                "Duration",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                durationController,

                decoration:
                _inputDecoration(
                  "Enter duration (e.g., 5 min)",
                  cardColor,
                ),

                style: TextStyle(
                  color: textColor,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // LANGUAGE
              // =================================================

              Text(
                "Language",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                languageController,

                decoration:
                _inputDecoration(
                  "Enter language (e.g., Hindi)",
                  cardColor,
                ),

                style: TextStyle(
                  color: textColor,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // DESCRIPTION
              // =================================================

              Text(
                "Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                descriptionController,

                maxLines: 15,

                decoration:
                _inputDecoration(
                  "Enter Aarti description",
                  cardColor,
                ),

                style: TextStyle(
                  color: textColor,
                ),

                validator: (value) =>
                value == null ||
                    value.trim().isEmpty
                    ? "Description required"
                    : null,
              ),

              const SizedBox(height: 30),

              // =================================================
              // SAVE / UPDATE
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    accentColor,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  onPressed:
                  isLoading
                      ? null
                      : _saveAarti,

                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    widget.isEdit
                        ? "Update Aarti"
                        : "Save Aarti",

                    style:
                    const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}