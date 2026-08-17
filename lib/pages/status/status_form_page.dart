
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/content_category.dart';
import '../../models/status_model.dart';
import '../../services/content_category_api.dart';
import '../../services/status_api.dart';

const saffron = Color(0xFFFF6B00);
const deepOr = Color(0xFFB5451B);
const cream = Color(0xFFFFF8F0);
const brown = Color(0xFF2C1810);

class StatusFormPage extends StatefulWidget {
  final StatusModel? status;

  const StatusFormPage({
    super.key,
    this.status,
  });

  @override
  State<StatusFormPage> createState() => _StatusFormPageState();
}

class _StatusFormPageState extends State<StatusFormPage> {
  final _formKey = GlobalKey<FormState>();

  final titleHi = TextEditingController();
  final titleEn = TextEditingController();
  final duration = TextEditingController();

  final StatusApi api = StatusApi();
  final ContentCategoryApi categoryApi = ContentCategoryApi();

  List<ContentCategory> categories = [];

  ContentCategory? selectedCategory;

  XFile? selectedFile;

  bool loading = false;
  bool categoriesLoading = true;

  bool get isEdit => widget.status != null;

  @override
  void initState() {
    super.initState();

    if (widget.status != null) {
      titleHi.text = widget.status!.title;

      // Agar model mein English title available hai
      // to yahan set karna.
      //
      // Current StatusModel agar sirf title expose karta hai
      // to English title API/model mein add karna hoga.

      duration.text =
          widget.status!.durationSeconds.toString();
    }

    loadCategories();
  }

  @override
  void dispose() {
    titleHi.dispose();
    titleEn.dispose();
    duration.dispose();
    super.dispose();
  }

  Future<void> loadCategories() async {
    if (!mounted) return;

    setState(() {
      categoriesLoading = true;
    });

    try {
      debugPrint('==============================');
      debugPrint('LOADING STATUS CATEGORIES');
      debugPrint('==============================');

      final data = await categoryApi.getCategories('status');

      debugPrint(
        'STATUS CATEGORY COUNT: ${data.length}',
      );

      for (final category in data) {
        debugPrint(
          'CATEGORY => '
              'id=${category.id}, '
              'nameHi=${category.name}, '
              'nameEn=${category.nameEn}',
        );
      }

      ContentCategory? editCategory;

      // EDIT MODE
      if (widget.status != null) {
        final statusCategory =
            widget.status!.category;

        if (statusCategory != null) {
          final categoryId =
              statusCategory['_id'] ??
                  statusCategory['id'] ??
                  statusCategory['categoryId'];

          debugPrint(
            'STATUS CATEGORY ID: $categoryId',
          );

          if (categoryId != null) {
            for (final category in data) {
              if (category.id.toString() ==
                  categoryId.toString()) {
                editCategory = category;
                break;
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        categories = data;
        selectedCategory = editCategory;
        categoriesLoading = false;
      });

      debugPrint(
        'FINAL CATEGORY COUNT: ${categories.length}',
      );

      debugPrint('==============================');
    } catch (e, stackTrace) {
      debugPrint(
        'STATUS CATEGORY ERROR: $e',
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Status category load failed:\n$e',
          ),
        ),
      );
    }
  }


  Future<void> pickMedia() async {
    final picker = ImagePicker();

    final XFile? result = await picker.pickMedia();

    if (result == null) return;

    if (!mounted) return;

    setState(() {
      selectedFile = result;
    });
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category select करें'),
        ),
      );
      return;
    }

    // Add mode mein media compulsory
    if (!isEdit && selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media select करें'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (isEdit) {
        // ==============================
        // UPDATE
        // ==============================

        await api.updateStatus(
          id: widget.status!.id,
          media: selectedFile,
          titleHi: titleHi.text.trim(),
          titleEn: titleEn.text.trim(),
          categoryId: selectedCategory!.id,
          durationSeconds:
          int.tryParse(duration.text.trim()) ?? 0,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Status updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ==============================
        // ADD
        // ==============================

        await api.uploadStatus(
          media: selectedFile!,
          titleHi: titleHi.text.trim(),
          titleEn: titleEn.text.trim(),
          categoryId: selectedCategory!.id,
          durationSeconds:
          int.tryParse(duration.text.trim()) ?? 0,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Status uploaded successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Status' : 'Add Status',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  _label('Status Title (Hindi)'),

                  TextFormField(
                    controller: titleHi,
                    decoration: _decoration(
                      'उदाहरण: शुभ प्रभात',
                    ),
                    validator: (v) {
                      if (v == null ||
                          v.trim().isEmpty) {
                        return 'Hindi title required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _label('Status Title (English)'),

                  TextFormField(
                    controller: titleEn,
                    decoration: _decoration(
                      'Example: Good Morning',
                    ),
                    validator: (v) {
                      if (v == null ||
                          v.trim().isEmpty) {
                        return 'English title required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _label('Category'),

                  categoriesLoading
                      ? const LinearProgressIndicator(
                    color: saffron,
                  )
                      : DropdownButtonFormField<
                      ContentCategory>(
                    value: selectedCategory,

                    decoration:
                    _decoration(
                      'Select Category',
                    ),

                    items: categories
                        .map(
                          (e) =>
                          DropdownMenuItem(
                            value: e,
                            child: Text(
                              '${e.name}',
                            ),
                          ),
                    )
                        .toList(),

                    onChanged: (v) {
                      setState(() {
                        selectedCategory = v;
                      });
                    },

                    validator: (value) {
                      if (value == null) {
                        return 'Category required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  _label(
                    isEdit
                        ? 'Media'
                        : 'Media',
                  ),

                  _mediaPicker(),

                  const SizedBox(height: 8),

                  if (isEdit)
                    const Text(
                      'Edit करते समय नया media select करना optional है.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 18),

                  _label(
                    'Duration (Video only)',
                  ),

                  TextFormField(
                    controller: duration,
                    keyboardType:
                    TextInputType.number,
                    decoration: _decoration(
                      'Seconds',
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed:
                      loading ? null : save,

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor: saffron,
                        foregroundColor:
                        Colors.white,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        isEdit
                            ? Icons.save
                            : Icons.cloud_upload,
                      ),

                      label: Text(
                        loading
                            ? isEdit
                            ? 'Updating...'
                            : 'Uploading...'
                            : isEdit
                            ? 'Update Status'
                            : 'Upload Status',

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


  Widget _mediaPicker() {
    return GestureDetector(
      onTap: pickMedia,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: saffron.withOpacity(.3),
          ),
        ),
        child: selectedFile != null
            ? FutureBuilder(
          future: selectedFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: saffron,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                ),
              );
            }

            return ClipRRect(
              borderRadius:
              BorderRadius.circular(18),
              child: Image.memory(
                snapshot.data!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          },
        )
            : _existingMediaPreview(),
      ),
    );
  }



  Widget _existingMediaPreview() {
    if (!isEdit) {
      return Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Icon(
            Icons.cloud_upload_rounded,
            size: 50,
            color: saffron,
          ),

          const SizedBox(height: 10),

          const Text(
            'Image / Video select करें',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
        ],
      );
    }

    final status = widget.status!;

    final imageUrl =
    status.thumbnailUrl.isNotEmpty
        ? status.thumbnailUrl
        : status.mediaUrl;

    return Stack(
      children: [

        ClipRRect(
          borderRadius:
          BorderRadius.circular(18),

          child: Image.network(
            imageUrl,

            width: double.infinity,
            height: double.infinity,

            fit: BoxFit.cover,

            errorBuilder:
                (_, __, ___) {
              return Container(
                color: Colors.grey.shade100,

                child: const Center(
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
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: Colors.black
                  .withOpacity(.65),

              borderRadius:
              BorderRadius.circular(10),
            ),

            child: const Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),

                SizedBox(width: 6),

                Text(
                  'Change Media',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _label(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 7),

      child: Text(
        text,

        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: brown,
        ),
      ),
    );
  }

  InputDecoration _decoration(
      String hint,
      ) {
    return InputDecoration(
      hintText: hint,

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),

        borderSide: BorderSide.none,
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),

        borderSide:
        const BorderSide(
          color: saffron,
          width: 1.5,
        ),
      ),
    );
  }
}