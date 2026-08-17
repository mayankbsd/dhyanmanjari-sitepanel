
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class AddVisheshSangrahPage extends StatefulWidget {
final bool isDark;

// EDIT DATA
final Map<String, dynamic>? editData;

const AddVisheshSangrahPage({
super.key,
this.isDark = false,
this.editData,
});

bool get isEdit =>
editData != null &&
editData!["granthId"] != null;

@override
State<AddVisheshSangrahPage> createState() =>
_AddVisheshSangrahPageState();
}

class _AddVisheshSangrahPageState
extends State<AddVisheshSangrahPage> {

final _formKey = GlobalKey<FormState>();

final _titleCtrl = TextEditingController();
final _englishCtrl = TextEditingController();
final _descCtrl = TextEditingController();
final _contentCtrl = TextEditingController();

bool _isLoading = false;
bool _catLoading = true;

List<Map<String, dynamic>> _categories = [];

int? _selectedCategoryId;

// IMAGE
Uint8List? _selectedImageBytes;
String? _selectedImageName;

String? _existingImageUrl;

@override
void initState() {
super.initState();

_loadCategories();

// ==============================
// EDIT DATA FILL
// ==============================

if (widget.isEdit) {
final data = widget.editData!;

_titleCtrl.text =
data["title"]?.toString() ?? "";

_englishCtrl.text =
data["titleEnglish"]?.toString() ?? "";

_descCtrl.text =
data["description"]?.toString() ?? "";

// ------------------------------
// CATEGORY
// ------------------------------

if (data["categoryId"] != null) {
_selectedCategoryId =
int.tryParse(
data["categoryId"].toString(),
);
}

// ------------------------------
// IMAGE
// ------------------------------

_existingImageUrl =
data["imageUrl"]?.toString() ??
data["image"]?.toString();

// ------------------------------
// PAGES -> CONTENT
// ------------------------------

final pages = data["pages"];

if (pages is List) {
_contentCtrl.text = pages
    .map((e) => e.toString())
    .join("\n");
}
}
}

@override
void dispose() {
_titleCtrl.dispose();
_englishCtrl.dispose();
_descCtrl.dispose();
_contentCtrl.dispose();

super.dispose();
}

// ======================================================
// LOAD CATEGORIES
// ======================================================

Future<void> _loadCategories() async {
try {
final res = await http.get(
Uri.parse(
"${ApiConstants.baseUrl}/categories",
),
headers: {
"Content-Type": "application/json",
"Authorization": ApiConstants.token,
},
);

if (res.statusCode == 200) {
final data = jsonDecode(res.body);

final list =
data["data"] as List<dynamic>? ?? [];

if (!mounted) return;

setState(() {
_categories = list
    .map(
(e) => {
"categoryId": e["categoryId"],
"categoryName": e["categoryName"],
},
)
    .toList();

_catLoading = false;
});
} else {
if (mounted) {
setState(() {
_catLoading = false;
});
}
}
} catch (e) {
if (mounted) {
setState(() {
_catLoading = false;
});
}
}
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
_selectedImageBytes = file.bytes;
_selectedImageName = file.name;
});
} catch (e) {
_showMessage(
"Image select karne mein error",
);
}
}

// ======================================================
// SPLIT PAGES
// ======================================================

List<String> _splitIntoPages(
String content,
) {
final lines = content
    .split('\n')
    .where(
(l) => l.trim().isNotEmpty,
)
    .toList();

final pages = <String>[];

for (int i = 0;
i < lines.length;
i += 4) {

final end =
(i + 4 < lines.length)
? i + 4
    : lines.length;

pages.add(
lines
    .sublist(i, end)
    .join('\n'),
);
}

return pages;
}

// ======================================================
// SAVE / UPDATE
// ======================================================

Future<void> _save() async {
if (!_formKey.currentState!.validate()) {
return;
}

if (_selectedCategoryId == null) {
_showMessage(
"Please select a category",
);
return;
}

setState(() {
_isLoading = true;
});

try {
final pages = _splitIntoPages(
_contentCtrl.text.trim(),
);

final bool isEdit = widget.isEdit;

final String url = isEdit
? "${ApiConstants.baseUrl}/granths/${widget.editData!["granthId"]}"
    : "${ApiConstants.baseUrl}/granths";

// ==================================================
// MULTIPART REQUEST
// ==================================================

final request = http.MultipartRequest(
isEdit ? "PUT" : "POST",
Uri.parse(url),
);

// ==================================================
// AUTH
// ==================================================

request.headers["Authorization"] =
ApiConstants.token;

// ==================================================
// TEXT FIELDS
// ==================================================

request.fields["title"] =
_titleCtrl.text.trim();

request.fields["titleEnglish"] =
_englishCtrl.text.trim();

request.fields["description"] =
_descCtrl.text.trim();

request.fields["duration"] =
"5 min";

request.fields["language"] =
"Hindi";

request.fields["categoryId"] =
_selectedCategoryId.toString();

// ==================================================
// PAGES
// ==================================================

// Backend req.body mein pages JSON string
// ke form mein receive karega.

request.fields["pages"] =
jsonEncode(pages);

// ==================================================
// IMAGE
// ==================================================

// Add mode:
// image select ki hai to upload

// Edit mode:
// image select ki hai to NEW image upload
// image select nahi ki hai to old image same rahegi

if (_selectedImageBytes != null) {
request.files.add(
http.MultipartFile.fromBytes(
"image",
_selectedImageBytes!,
filename:
_selectedImageName ??
"granth.jpg",
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
"GRANTH RESPONSE: $responseBody",
);

if (!mounted) return;

final data =
jsonDecode(responseBody);

if (response.statusCode == 200 ||
response.statusCode == 201) {

if (data["success"] == true) {
_showMessage(
isEdit
? "Granth updated successfully"
    : "Granth added successfully",
);

Navigator.pop(
context,
true,
);
} else {
_showMessage(
data["message"] ??
"Operation failed",
);
}
} else {
_showMessage(
data["message"] ??
"Failed: ${response.statusCode}",
);
}
} catch (e) {
debugPrint(
"GRANTH SAVE ERROR: $e",
);

if (mounted) {
_showMessage(
"Server error: $e",
);
}
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

// ======================================================
// IMAGE PREVIEW
// ======================================================

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
color:
Colors.red.withOpacity(0.25),
),
),
child: ClipRRect(
borderRadius:
BorderRadius.circular(16),

child:
_selectedImageBytes != null
? Image.memory(
_selectedImageBytes!,
fit: BoxFit.cover,
)
    : (_existingImageUrl != null &&
_existingImageUrl!
    .trim()
    .isNotEmpty)
? Image.network(
_existingImageUrl!,
fit: BoxFit.cover,
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
color:
Colors.grey.shade400,
),
const SizedBox(height: 8),
Text(
"Granth Image",
style: TextStyle(
color:
Colors.grey.shade500,
),
),
],
),
);
}

// ======================================================
// MESSAGE
// ======================================================

void _showMessage(
String message,
) {
ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content: Text(message),
),
);
}

// ======================================================
// BUILD
// ======================================================

@override
Widget build(
BuildContext context,
) {
final bgColor =
widget.isDark
? Colors.grey[900]!
    : const Color(
0xfff4f6f9,
);

final cardColor =
widget.isDark
? Colors.grey[850]!
    : Colors.white;

final textColor =
widget.isDark
? Colors.white
    : Colors.black87;

const accent =
Colors.red;

return Scaffold(
backgroundColor: bgColor,

appBar: AppBar(
title: Text(
widget.isEdit
? "Update Vishesh Sangrah"
    : "Add Vishesh Sangrah",
),
backgroundColor: accent,
),

body:
SingleChildScrollView(
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

_label(
"Granth Image",
),

const SizedBox(
height: 8,
),

_buildImagePreview(
cardColor,
textColor,
),

const SizedBox(
height: 12,
),

SizedBox(
width:
double.infinity,
height: 48,

child:
OutlinedButton.icon(
onPressed:
_isLoading
? null
    : _pickImage,

icon:
const Icon(
Icons.upload_rounded,
),

label: Text(
_selectedImageBytes !=
null
? "Change Image"
    : "Select Image",
),

style:
OutlinedButton
    .styleFrom(
foregroundColor:
accent,
side:
const BorderSide(
color: accent,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
12,
),
),
),
),
),

const SizedBox(
height: 25,
),

// ==================================================
// TITLE HINDI
// ==================================================

_label(
"Title (Hindi)",
),

const SizedBox(
height: 8,
),

TextFormField(
controller:
_titleCtrl,

style: TextStyle(
color: textColor,
),

decoration:
_deco(
"जैसे: शिव पुराण",
cardColor,
),

validator: (v) =>
v == null ||
v.trim().isEmpty
? "Title required"
    : null,
),

const SizedBox(
height: 20,
),

// ==================================================
// TITLE ENGLISH
// ==================================================

_label(
"Title (English)",
),

const SizedBox(
height: 8,
),

TextFormField(
controller:
_englishCtrl,

style: TextStyle(
color: textColor,
),

decoration:
_deco(
"e.g. Shiv Puran",
cardColor,
),

validator: (v) =>
v == null ||
v.trim().isEmpty
? "English title required"
    : null,
),

const SizedBox(
height: 20,
),

// ==================================================
// DESCRIPTION
// ==================================================

_label(
"Description",
),

const SizedBox(
height: 8,
),

TextFormField(
controller:
_descCtrl,

maxLines: 3,

style: TextStyle(
color: textColor,
),

decoration:
_deco(
"Short description...",
cardColor,
),

validator: (v) =>
v == null ||
v.trim().isEmpty
? "Description required"
    : null,
),

const SizedBox(
height: 20,
),

// ==================================================
// CATEGORY
// ==================================================

_label(
"Category *",
),

const SizedBox(
height: 8,
),

_catLoading
? const Center(
child:
CircularProgressIndicator(),
)
    : _categories.isEmpty
? Container(
padding:
const EdgeInsets
    .all(14),
decoration:
BoxDecoration(
color: Colors
    .red
    .shade50,
borderRadius:
BorderRadius
    .circular(
12,
),
border:
Border.all(
color: Colors
    .red
    .shade200,
),
),
child:
const Text(
"No categories found. Please add a category first.",
style: TextStyle(
color:
Colors.red,
),
),
)
    : Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 14,
),
decoration:
BoxDecoration(
color:
cardColor,
borderRadius:
BorderRadius
    .circular(
12,
),
border:
Border.all(
color: Colors
    .grey
    .shade400,
),
),
child:
DropdownButtonHideUnderline(
child:
DropdownButton<
int>(
isExpanded:
true,

value:
_categories.any(
(c) =>
c["categoryId"] ==
_selectedCategoryId,
)
? _selectedCategoryId
    : null,

hint:
const Text(
"Select Category",
),

dropdownColor:
cardColor,

style:
TextStyle(
color:
textColor,
fontSize:
15,
),

items: _categories
    .map(
(c) =>
DropdownMenuItem<
int>(
value: int.tryParse(
c["categoryId"]
    .toString(),
),
child:
Text(
c["categoryName"]
    ?.toString() ??
"",
),
),
)
    .toList(),

onChanged:
(val) {
setState(
() {
_selectedCategoryId =
val;
},
);
},
),
),
),

const SizedBox(
height: 20,
),

// ==================================================
// CONTENT
// ==================================================

_label(
"Content (4 lines = 1 page)",
),

const SizedBox(
height: 8,
),

TextFormField(
controller:
_contentCtrl,

maxLines: 20,

style: TextStyle(
color: textColor,
),

decoration:
_deco(
"Paste full content here...\n4 lines = 1 page",
cardColor,
),

validator: (v) =>
v == null ||
v.trim().isEmpty
? "Content required"
    : null,
),

const SizedBox(
height: 30,
),

// ==================================================
// SAVE / UPDATE
// ==================================================

SizedBox(
width:
double.infinity,
height: 52,

child:
ElevatedButton(
style:
ElevatedButton
    .styleFrom(
backgroundColor:
accent,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
12,
),
),
),

onPressed:
_isLoading
? null
    : _save,

child: _isLoading
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
? "Update Granth"
    : "Save Granth",
style:
const TextStyle(
fontSize: 18,
),
),
),
),

const SizedBox(
height: 30,
),
],
),
),
),
);
}

// ======================================================
// LABEL
// ======================================================

Widget _label(
String text,
) {
return Text(
text,
style: const TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
);
}

// ======================================================
// INPUT DECORATION
// ======================================================

InputDecoration _deco(
String hint,
Color fill,
) {
return InputDecoration(
hintText: hint,
filled: true,
fillColor: fill,
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
);
}
}

