import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddChalisaPage extends StatefulWidget {
  final bool isDark;

  // Edit ke time complete object yahan aayega
  final Map<String, dynamic>? editData;

  const AddChalisaPage({
    super.key,
    this.isDark = false,
    this.editData,
  });

  bool get isEdit => editData != null;

  @override
  State<AddChalisaPage> createState() => _AddChalisaPageState();
}

class _AddChalisaPageState extends State<AddChalisaPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController englishTitleController =
  TextEditingController();

  final TextEditingController contentController =
  TextEditingController();

  bool isLoading = false;

  // ======================================================
  // IMAGE
  // ======================================================

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  // ======================================================
  // INIT
  // ======================================================

  @override
  void initState() {
    super.initState();

    if (widget.editData != null) {
      final data = widget.editData!;

      titleController.text =
          (data["title"] ?? "").toString();

      englishTitleController.text =
          (data["titleEnglish"] ?? "").toString();

      // Existing Chalisa content
      String description =
      (data["description"] ?? "").toString();

      // Agar description available nahi hai
      // to pages se content banane ki koshish
      if (description.trim().isEmpty &&
          data["pages"] is List) {
        final pages =
        (data["pages"] as List)
            .map((e) => e.toString())
            .toList();

        description = pages.join("\n");
      }

      contentController.text = description;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    englishTitleController.dispose();
    contentController.dispose();

    super.dispose();
  }

  // ======================================================
  // SPLIT INTO PAGES
  // 4 LINES = 1 PAGE
  // ======================================================

  List<String> _splitIntoPages(String content) {
    final lines = content
        .split('\n')
        .where(
          (line) => line.trim().isNotEmpty,
    )
        .toList();

    final List<String> pages = [];

    for (int i = 0; i < lines.length; i += 4) {
      final int end =
      (i + 4 < lines.length)
          ? i + 4
          : lines.length;

      pages.add(
        lines.sublist(i, end).join('\n'),
      );
    }

    return pages;
  }

  // ======================================================
  // PICK IMAGE
  // ======================================================

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
      debugPrint("IMAGE PICK ERROR: $e");

      _showMessage(
        "Image select karne mein error",
      );
    }
  }

  // ======================================================
  // EXISTING IMAGE URL
  // ======================================================

  String get existingImageUrl {
    if (widget.editData == null) {
      return "";
    }

    return (
        widget.editData!["imageUrl"] ?? ""
    ).toString().trim();
  }

  // ======================================================
  // SAVE / UPDATE
  // ======================================================

  Future<void> _saveChalisa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final bool isEdit = widget.isEdit;

      final int? id =
      widget.editData?["id"] != null
          ? int.tryParse(
        widget.editData!["id"].toString(),
      )
          : null;

      final Uri url = isEdit
          ? Uri.parse(
        "${ApiConstants.chalisha}/$id",
      )
          : Uri.parse(
        ApiConstants.chalisha,
      );

      // ==================================================
      // MULTIPART REQUEST
      // ==================================================

      final request = http.MultipartRequest(
        isEdit ? "PUT" : "POST",
        url,
      );

      // ==================================================
      // AUTH
      // ==================================================

      request.headers["Authorization"] =
          ApiConstants.token;

      // ==================================================
      // CONTENT
      // ==================================================

      final String content =
      contentController.text.trim();

      final List<String> pages =
      _splitIntoPages(content);

      // ==================================================
      // TEXT FIELDS
      // ==================================================

      request.fields["title"] =
          titleController.text.trim();

      request.fields["titleEnglish"] =
          englishTitleController.text.trim();

      request.fields["duration"] =
      "5 min";

      request.fields["language"] =
      "Hindi";

      request.fields["description"] =
          content;

      // pages ko JSON string mein bhejenge
      request.fields["pages"] =
          jsonEncode(pages);

      // ==================================================
      // IMAGE
      // ==================================================

      if (selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            selectedImageBytes!,
            filename:
            selectedImageName ??
                "chalisa.jpg",
          ),
        );
      }

      // ==================================================
      // SEND
      // ==================================================

      final response =
      await request.send();

      final responseBody =
      await response.stream
          .bytesToString();

      debugPrint(
        "CHALISA RESPONSE: $responseBody",
      );

      if (!mounted) return;

      // ==================================================
      // RESPONSE
      // ==================================================

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(responseBody);
      } catch (_) {}

      if (response.statusCode == 200 &&
          data["success"] == true) {
        _showMessage(
          isEdit
              ? "✅ Chalisa updated successfully"
              : "✅ Chalisa added successfully",
        );

        Navigator.pop(
          context,
          true,
        );
      } else {
        _showMessage(
          data["message"] ??
              "Failed to save Chalisa",
        );
      }
    } catch (e) {
      debugPrint(
        "CHALISA SAVE ERROR: $e",
      );

      if (mounted) {
        _showMessage(
          "Server error: $e",
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

  // ======================================================
  // MESSAGE
  // ======================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ======================================================
  // IMAGE PREVIEW
  // ======================================================

  Widget _buildImagePreview(
      Color cardColor,
      Color textColor,
      ) {
    Widget image;

    // New selected image
    if (selectedImageBytes != null) {
      image = Image.memory(
        selectedImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Existing image
    else if (existingImageUrl.isNotEmpty) {
      image = Image.network(
        existingImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _imagePlaceholder(
            textColor,
          );
        },
      );
    }

    // No image
    else {
      image = _imagePlaceholder(
        textColor,
      );
    }

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          Colors.deepPurple.withOpacity(
            0.25,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(16),
        child: image,
      ),
    );
  }

  // ======================================================
  // IMAGE PLACEHOLDER
  // ======================================================

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
            "Chalisa Image",
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // BUILD
  // ======================================================

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
        Colors.deepPurple;

    return Scaffold(
      backgroundColor: bgColor,

      // ==================================================
      // APP BAR
      // ==================================================

      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? "Update Chalisa"
              : "Add New Chalisa",
        ),
        backgroundColor:
        accentColor,
      ),

      // ==================================================
      // BODY
      // ==================================================

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(24),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // ==================================================
              // IMAGE
              // ==================================================

              Text(
                "Chalisa Image",
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
                    selectedImageBytes !=
                        null
                        ? "Change Image"
                        : existingImageUrl
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
                      color:
                      accentColor,
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

              // ==================================================
              // TITLE HINDI
              // ==================================================

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

                style: TextStyle(
                  color: textColor,
                ),

                decoration:
                InputDecoration(
                  hintText:
                  "Enter Chalisa Title in Hindi",

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),

                  filled: true,
                  fillColor: cardColor,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Title required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TITLE ENGLISH
              // ==================================================

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

                style: TextStyle(
                  color: textColor,
                ),

                decoration:
                InputDecoration(
                  hintText:
                  "Enter Chalisa Title in English",

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),

                  filled: true,
                  fillColor: cardColor,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "English Title required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CONTENT
              // ==================================================

              Text(
                "Content",
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
                contentController,

                maxLines: 20,

                style: TextStyle(
                  color: textColor,
                ),

                decoration:
                InputDecoration(
                  hintText:
                  "Paste full Chalisa text here...\n4 lines = 1 page",

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),

                  filled: true,
                  fillColor: cardColor,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Content required";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE / UPDATE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,

                child:
                ElevatedButton(
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
                      : _saveChalisa,

                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                      strokeWidth:
                      2.5,
                    ),
                  )
                      : Text(
                    widget.isEdit
                        ? "Update Chalisa"
                        : "Save Chalisa",

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