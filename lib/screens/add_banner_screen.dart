
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_service.dart';

class AddBannerPage extends StatefulWidget {
const AddBannerPage({
super.key,
});

@override
State<AddBannerPage> createState() =>
_AddBannerPageState();
}

class _AddBannerPageState
extends State<AddBannerPage> {
final _titleController =
TextEditingController();

final _orderController =
TextEditingController();

Uint8List? _imageBytes;
String? _imageName;
String? _imageMimeType;

bool _isLoading = false;

// =========================================================
// PICK IMAGE
// =========================================================

Future<void> _pickImage() async {
try {
final picker = ImagePicker();

final picked = await picker.pickImage(
source: ImageSource.gallery,
imageQuality: 85,
);

if (picked == null) return;

final bytes =
await picked.readAsBytes();

if (!mounted) return;

setState(() {
_imageBytes = bytes;

_imageName = picked.name;

_imageMimeType =
picked.mimeType ??
_getMimeType(
picked.name,
);
});

debugPrint(
'Image selected:',
);

debugPrint(
'Name: ${picked.name}',
);

debugPrint(
'MimeType: $_imageMimeType',
);

debugPrint(
'Size: ${bytes.length} bytes',
);
} catch (e) {
debugPrint(
'Image picker error: $e',
);

_showMsg(
'Image select नहीं हो सकी',
);
}
}

// =========================================================
// MIME TYPE
// =========================================================

String _getMimeType(
String fileName) {
final name =
fileName.toLowerCase();

if (name.endsWith('.png')) {
return 'image/png';
}

if (name.endsWith('.webp')) {
return 'image/webp';
}

if (name.endsWith('.gif')) {
return 'image/gif';
}

if (name.endsWith('.bmp')) {
return 'image/bmp';
}

if (name.endsWith('.jpg') ||
name.endsWith('.jpeg')) {
return 'image/jpeg';
}

return 'image/jpeg';
}

// =========================================================
// SUBMIT
// =========================================================

Future<void> _submitBanner() async {
if (_imageBytes == null) {
_showMsg(
'Please select an image',
);
return;
}

setState(() {
_isLoading = true;
});

try {
final uri = Uri.parse(
'${ApiConstants.baseUrl}/banner',
);

debugPrint(
'==============================',
);

debugPrint(
'BANNER UPLOAD START',
);

debugPrint(
'URL: $uri',
);

debugPrint(
'File: $_imageName',
);

debugPrint(
'Mime: $_imageMimeType',
);

debugPrint(
'Size: ${_imageBytes!.length}',
);

// =====================================================
// MULTIPART REQUEST
// =====================================================

final request =
http.MultipartRequest(
'POST',
uri,
);

// =====================================================
// HEADERS
// =====================================================

request.headers.addAll({
'Authorization':
ApiConstants.token,
'Accept':
'application/json',
});

// =====================================================
// FIELDS
// =====================================================

request.fields['title'] =
_titleController.text.trim();

request.fields['order'] =
_orderController.text
    .trim()
    .isEmpty
? '0'
    : _orderController.text
    .trim();

// =====================================================
// MIME TYPE
// =====================================================

final mime =
_imageMimeType ??
_getMimeType(
_imageName ??
'banner.jpg',
);

final parts =
mime.split('/');

final contentType =
parts.length == 2
? MediaType(
parts[0],
parts[1],
)
    : MediaType(
'image',
'jpeg',
);

// =====================================================
// IMAGE FILE
// =====================================================

request.files.add(
http.MultipartFile.fromBytes(
'image',
_imageBytes!,
filename:
_imageName ??
'banner.jpg',
contentType:
contentType,
),
);

debugPrint(
'Multipart file added',
);

debugPrint(
'Content-Type: $contentType',
);

// =====================================================
// SEND
// =====================================================

final streamedResponse =
await request.send();

final response =
await http.Response.fromStream(
streamedResponse,
);

debugPrint(
'Status Code: ${response.statusCode}',
);

debugPrint(
'Response: ${response.body}',
);

debugPrint(
'==============================',
);

// =====================================================
// RESPONSE
// =====================================================

if (response.statusCode >= 200 &&
response.statusCode < 300) {
try {
final data =
jsonDecode(response.body);

if (data['success'] == true) {
_showMsg(
'Banner added successfully',
);

if (mounted) {
Navigator.pop(
context,
true,
);
}

return;
}

_showMsg(
data['message'] ??
data['error'] ??
'Something went wrong',
);
} catch (e) {
_showMsg(
'Server returned invalid response',
);

debugPrint(
'JSON decode error: $e',
);
}

return;
}

// =====================================================
// ERROR RESPONSE
// =====================================================

String message =
'Upload failed (${response.statusCode})';

try {
final data =
jsonDecode(response.body);

message =
data['message'] ??
data['error'] ??
message;
} catch (_) {
// Server ने JSON नहीं भेजा
// जैसे HTML error page
debugPrint(
'Non JSON response received',
);
}

_showMsg(message);
} catch (e, stackTrace) {
debugPrint(
'Banner upload error: $e',
);

debugPrint(
stackTrace.toString(),
);

_showMsg(
'Upload error: $e',
);
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

// =========================================================
// MESSAGE
// =========================================================

void _showMsg(
String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content:
Text(message),
),
);
}

// =========================================================
// DISPOSE
// =========================================================

@override
void dispose() {
_titleController.dispose();
_orderController.dispose();

super.dispose();
}

// =========================================================
// BUILD
// =========================================================

@override
Widget build(
BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Add Banner',
),
),

body: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 500,
),

child: Padding(
padding:
const EdgeInsets.all(
24,
),

child: ListView(
shrinkWrap: true,

children: [

// =================================================
// IMAGE PICKER
// =================================================

GestureDetector(
onTap: _isLoading
? null
    : _pickImage,

child: Container(
height: 180,
width:
double.infinity,

decoration:
BoxDecoration(
color:
Colors.grey.shade200,

borderRadius:
BorderRadius.circular(
12,
),
),

child:
_imageBytes != null
? ClipRRect(
borderRadius:
BorderRadius.circular(
12,
),

child:
Image.memory(
_imageBytes!,
fit: BoxFit.cover,
),
)
    : const Center(
child: Icon(
Icons
    .add_photo_alternate,
size: 48,
),
),
),
),

const SizedBox(
height: 8,
),

if (_imageName != null)
Text(
_imageName!,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
fontSize: 12,
color:
Colors.grey,
),
),

const SizedBox(
height: 16,
),

// =================================================
// TITLE
// =================================================

TextField(
controller:
_titleController,

decoration:
const InputDecoration(
labelText:
'Title (optional)',
border:
OutlineInputBorder(),
),
),

const SizedBox(
height: 12,
),

// =================================================
// ORDER
// =================================================

TextField(
controller:
_orderController,

keyboardType:
TextInputType.number,

decoration:
const InputDecoration(
labelText:
'Order (optional)',
border:
OutlineInputBorder(),
),
),

const SizedBox(
height: 24,
),

// =================================================
// SUBMIT
// =================================================

ElevatedButton(
onPressed:
_isLoading
? null
    : _submitBanner,

style:
ElevatedButton.styleFrom(
padding:
const EdgeInsets
    .symmetric(
vertical: 14,
),
),

child:
_isLoading
? const SizedBox(
height: 20,
width: 20,

child:
CircularProgressIndicator(
strokeWidth: 2,
color:
Colors.white,
),
)
    : const Text(
'Add Banner',
),
),
],
),
),
),
),
);
}
}