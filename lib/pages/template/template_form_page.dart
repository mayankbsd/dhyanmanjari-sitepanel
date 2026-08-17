import 'dart:convert';
import 'dart:io';
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

class _TemplateFormPageState extends State<TemplateFormPage> {
final _formKey = GlobalKey<FormState>();

final titleHi = TextEditingController();
final titleEn = TextEditingController();
final textHi = TextEditingController();
final textEn = TextEditingController();

final ContentCategoryApi categoryApi =
ContentCategoryApi();

List<ContentCategory> categories = [];

ContentCategory? selectedCategory;

File? image;

bool loading = false;
bool categoriesLoading = true;

@override
void initState() {
super.initState();

if (widget.isEdit && widget.template != null) {
_fillEditData();
}

loadCategories();
}

void _fillEditData() {
final data = widget.template!;

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

@override
void dispose() {
titleHi.dispose();
titleEn.dispose();
textHi.dispose();
textEn.dispose();

super.dispose();
}

Future<void> loadCategories() async {
try {
final result =
await categoryApi.getCategories('template');

if (!mounted) return;

setState(() {
categories = result;
categoriesLoading = false;
});

if (widget.isEdit &&
widget.template != null) {
_selectEditCategory();
}
} catch (e) {
if (!mounted) return;

setState(() {
categoriesLoading = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(e.toString()),
),
);
}
}

void _selectEditCategory() {
final data = widget.template!;

dynamic categoryId;

if (data['category'] is Map) {
categoryId =
data['category']['_id'] ??
data['category']['id'];
} else {
categoryId =
data['categoryId'];
}

if (categoryId == null) return;

for (final category in categories) {
if (category.id.toString() ==
categoryId.toString()) {
setState(() {
selectedCategory = category;
});
break;
}
}
}

Future<void> pickImage() async {
final picker = ImagePicker();

final result =
await picker.pickImage(
source: ImageSource.gallery,
imageQuality: 90,
);

if (result == null) return;

setState(() {
image = File(result.path);
});
}

Future<void> save() async {
if (!_formKey.currentState!.validate()) {
return;
}

if (selectedCategory == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Template category select करें',
),
),
);
return;
}

if (!widget.isEdit && image == null) {
ScaffoldMessenger.of(context).showSnackBar(
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

final request =
http.MultipartRequest(
widget.isEdit ? 'PUT' : 'POST',
uri,
);

request.headers['Authorization'] =
ApiConstants.token;

request.fields['titleHi'] =
titleHi.text.trim();

request.fields['titleEn'] =
titleEn.text.trim();

request.fields['textHi'] =
textHi.text.trim();

request.fields['textEn'] =
textEn.text.trim();

request.fields['categoryId'] =
selectedCategory!.id.toString();

// EDIT में ID भेजें
if (widget.isEdit &&
widget.template != null) {
final id =
widget.template!['_id'] ??
widget.template!['id'];

if (id != null) {
request.fields['id'] =
id.toString();
}
}

// Add में image required
// Edit में image optional
if (image != null) {
request.files.add(
await http.MultipartFile.fromPath(
'media',
image!.path,
),
);
}

final streamedResponse =
await request.send();

final response =
await http.Response.fromStream(
streamedResponse,
);

if (!mounted) return;

if (response.statusCode >= 200 &&
response.statusCode < 300) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
widget.isEdit
? 'Template updated successfully'
    : 'Template added successfully',
),
),
);

Navigator.pop(context, true);
} else {
String message =
'Template save failed';

try {
final body =
jsonDecode(response.body);

message =
body['message'] ??
body['error'] ??
message;
} catch (_) {}

throw Exception(message);
}
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
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

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: cream,

appBar: AppBar(
backgroundColor: saffron,
foregroundColor: Colors.white,

title: Text(
widget.isEdit
? 'Edit Template'
    : 'Add Template',

style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
),

body: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 700,
),

child: SingleChildScrollView(
padding:
const EdgeInsets.all(24),

child: Form(
key: _formKey,

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
_label('Title Hindi'),

_field(
titleHi,
'उदाहरण: श्री राम मंत्र',
),

const SizedBox(height: 16),

_label('Title English'),

_field(
titleEn,
'Example: Shri Ram Mantra',
),

const SizedBox(height: 16),

_label('Template Category'),

categoriesLoading
? const LinearProgressIndicator(
color: saffron,
)
    : DropdownButtonFormField<
ContentCategory>(
value:
selectedCategory,

decoration:
_decoration(
'Select Category',
),

items:
categories.map(
(e) {
return DropdownMenuItem<
ContentCategory>(
value: e,

child: Text(
'${e.name}',
),
);
},
).toList(),

validator: (value) {
if (value == null) {
return 'Category required';
}

return null;
},

onChanged: (value) {
setState(() {
selectedCategory =
value;
});
},
),

const SizedBox(height: 16),

_label('Hindi Content'),

_multiline(
textHi,
'यहाँ Hindi content लिखें',
),

const SizedBox(height: 16),

_label('English Content'),

_multiline(
textEn,
'Enter English content',
),

const SizedBox(height: 16),

_label('Template Image'),

GestureDetector(
onTap: pickImage,

child: Container(
width: double.infinity,
height: 250,

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
),
),

child: image != null
? ClipRRect(
borderRadius:
BorderRadius.circular(
18,
),

child: Image.file(
image!,
fit: BoxFit.cover,
),
)
    : widget.isEdit &&
_existingImage() !=
null
? ClipRRect(
borderRadius:
BorderRadius.circular(
18,
),

child:
Image.network(
_existingImage()!,
fit: BoxFit.cover,

errorBuilder:
(_, __, ___) {
return _imagePlaceholder();
},
),
)
    : _imagePlaceholder(),
),
),

if (widget.isEdit)
const Padding(
padding:
EdgeInsets.only(
top: 8,
),
child: Text(
'New image select करना optional है.',
style: TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
),

const SizedBox(height: 28),

SizedBox(
width: double.infinity,
height: 52,

child: ElevatedButton.icon(
onPressed:
loading ? null : save,

style:
ElevatedButton.styleFrom(
backgroundColor:
saffron,

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
color:
Colors.white,
),
)
    : Icon(
widget.isEdit
? Icons.save
    : Icons
    .cloud_upload,
),

label: Text(
loading
? 'Saving...'
    : widget.isEdit
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

String? _existingImage() {
if (widget.template == null) {
return null;
}

final data = widget.template!;

final value =
data['mediaUrl'] ??
data['imageUrl'] ??
data['thumbnailUrl'] ??
data['media'];

if (value == null) return null;

final url = value.toString();

return url.isEmpty ? null : url;
}

Widget _imagePlaceholder() {
return const Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Icon(
Icons.add_photo_alternate,
size: 50,
color: saffron,
),

SizedBox(height: 10),

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

Widget _label(String text) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 7,
),

child: Text(
text,

style: const TextStyle(
fontWeight:
FontWeight.w800,
color: brown,
),
),
);
}

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

InputDecoration _decoration(
String hint,
) {
return InputDecoration(
hintText: hint,

filled: true,

fillColor: Colors.white,

border:
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

