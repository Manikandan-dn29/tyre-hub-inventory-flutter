import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'scanner.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  List<dynamic> items = [];
  int? selectedItemId;
  String? currentBarcode;

  String adjustmentType = "DAMAGE"; // DAMAGE / LOSS / CORRECTION
  int correctionQty = 1;

  bool loading = true;

  File? capturedImage;
  String? uploadedImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final token = await Api.getToken();
      final res = await http.get(
        Uri.parse(Api.items),
        headers: {"Authorization": "Bearer $token"},
      );
      final parsed = await compute(jsonDecode, res.body);
      setState(() {
        items = parsed;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  /// 📷 CAMERA
  Future<void> captureImage() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return;

    final file = File(photo.path);
    setState(() => capturedImage = file);

    await uploadImage(file);
  }

  Future<void> uploadImage(File file) async {
    final token = await Api.getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse(Api.upload),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      uploadedImagePath = jsonDecode(body)["imagePath"];
    } else {
      throw Exception("Image upload failed");
    }
  }

  /// 📦 SUBMIT ADJUSTMENT
  Future<void> submitAdjustment() async {
    if (selectedItemId == null ||
        currentBarcode == null ||
        uploadedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields & capture image")),
      );
      return;
    }

    setState(() => loading = true);

    final token = await Api.getToken();
    final res = await http.post(
      Uri.parse("${Api.baseUrl}/adjustment/unit"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "itemId": selectedItemId,
        "barcode": currentBarcode,
        "type": adjustmentType,
        "quantity": adjustmentType == "CORRECTION" ? correctionQty : 1,
        "imagePath": uploadedImagePath,
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stock adjusted successfully ✅")),
      );
      setState(() {
        currentBarcode = null;
        capturedImage = null;
        uploadedImagePath = null;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.body)));
    }
  }

  void scanBarcode() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
    if (code != null) {
      setState(() => currentBarcode = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Adjustment",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: "Item",
                    border: OutlineInputBorder(),
                  ),
                  items: items
                      .map<DropdownMenuItem<int>>(
                        (e) => DropdownMenuItem(
                          value: e['id'],
                          child: Text(e['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedItemId = v),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: adjustmentType,
                  decoration: const InputDecoration(
                    labelText: "Adjustment Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "DAMAGE", child: Text("Damage")),
                    DropdownMenuItem(value: "LOSS", child: Text("Loss")),
                    DropdownMenuItem(
                        value: "CORRECTION", child: Text("Correction")),
                  ],
                  onChanged: (v) => setState(() => adjustmentType = v!),
                ),

                if (adjustmentType == "CORRECTION") ...[
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Correction Quantity (+ / -)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        correctionQty = int.tryParse(v) ?? 1,
                  ),
                ],

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Scan Barcode"),
                ),

                if (currentBarcode != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Barcode: $currentBarcode",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Image"),
                ),

                if (capturedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(capturedImage!, height: 180),
                  ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  onPressed: submitAdjustment,
                  child: const Text("Submit Adjustment",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}
