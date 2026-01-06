import 'dart:convert';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'scanner.dart';

class GrnPage extends StatefulWidget {
  const GrnPage({super.key});

  @override
  State<GrnPage> createState() => _GrnPageState();
}

class _GrnPageState extends State<GrnPage> {
  // ---------------- STATE ----------------
  List<dynamic> items = [];
  int? selectedItemId;

  final supplierCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  String? selectedLocation;
  final List<String> locations = ["MAIN STORE", "GODOWN", "WAREHOUSE-2"];

  int totalQty = 0;
  int submittedCount = 0;
  String? currentBarcode;
  
  bool loading = true;
  XFile? capturedImage;
  final ImagePicker _picker = ImagePicker();

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    loadItems();
  }

  // ---------------- API ----------------
  Future<void> loadItems() async {
    setState(() => loading = true);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load items: $e")));
    }
  }

  // ---------------- CAMERA ----------------
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() => capturedImage = image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Camera error")));
    }
  }

  // ---------------- GRN ----------------
  void startGrn() {
    if (supplierCtrl.text.isEmpty ||
        selectedItemId == null ||
        qtyCtrl.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      totalQty = int.tryParse(qtyCtrl.text) ?? 0;
      submittedCount = 0;
      currentBarcode = null;
      capturedImage = null;
    });
  }

  Future<void> submitUnit() async {
    if (currentBarcode == null) return;

     String? imagePath;

      // 📷 Upload image first
  if (capturedImage != null) {
    imagePath = await uploadImage(File(capturedImage!.path));
  }

    final token = await Api.getToken();
    final res = await http.post(
      Uri.parse("${Api.grn}/unit"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "itemId": selectedItemId,
        "barcode": currentBarcode,
        "supplier": supplierCtrl.text,
        "location": selectedLocation,
         "imagePath": imagePath,
      }),
    );

    if (res.statusCode == 200) {
      setState(() {
        submittedCount++;
        currentBarcode = null;
        capturedImage = null;
      });

      if (submittedCount == totalQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GRN Completed ✅")),
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.body)));
    }
  }

  // ---------------- MANUAL BARCODE ----------------
  void manualBarcodeEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Barcode"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter barcode",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => currentBarcode = ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final itemName = selectedItemId == null
        ? "-"
        : items.firstWhere((e) => e['id'] == selectedItemId)['name'];

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("GRN - Goods Receipt",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [


                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              AssetImage('assets/images/tyreIcon.jpg'),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                              colors: [
                                Colors.deepOrange,
                                Colors.redAccent
                              ],
                            ).createShader(
                          Rect.fromLTWH(
                              0, 0, bounds.width, bounds.height),
                        ),
                        child: const Text(
                          "TyreHub",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                   const SizedBox(height: 30),
                // -------- MASTER FORM --------
                TextField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(
                    labelText: "Supplier",
                    prefixIcon: Icon(Icons.store_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  decoration: const InputDecoration(
                    labelText: "Item",
                    prefixIcon: Icon(Icons.inventory_2_outlined),
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

                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    prefixIcon: Icon(Icons.numbers_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: locations
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedLocation = v),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900),
                  onPressed: startGrn,
                  child: const Text("Start GRN",
                      style: TextStyle(color: Colors.white)),
                ),

                // --------- GRN CARD ----------
                if (totalQty > 0) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            itemName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            "$submittedCount / $totalQty",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue),
                          ),

                          const Divider(height: 30),

                          if (currentBarcode != null)
                            const SizedBox(height: 14),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text("Scan Barcode"),
                            onPressed: () async {
                              final code = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ScannerPage()),
                              );
                              if (code != null) {
                                setState(() => currentBarcode = code);
                              }
                            },
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.keyboard),
                            label: const Text("Manual Entry"),
                            onPressed: manualBarcodeEntry,
                          ),

                          const SizedBox(height: 10),

                            // -------- BARCODE DISPLAY --------
                          if (currentBarcode != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blueGrey),
                              ),
                             child: Row(
  children: [
    const Icon(Icons.qr_code, color: Colors.blueGrey),
    const SizedBox(width: 10),

    const Text(
      "BARCODE ID : ",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    ),

    Expanded(
      child: Text(
        currentBarcode!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

                              ),
                         

                            SizedBox(height: 12,),

                         

                          if (capturedImage != null) ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(capturedImage!.path),
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],

                           ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text(capturedImage == null
                                ? "Capture Photo"
                                : "Retake Photo"),
                            onPressed: currentBarcode == null
                                ? null
                                : pickImageFromCamera,
                          ),


                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blueGrey.shade900),
                            onPressed:
                                currentBarcode == null ? null : submitUnit,
                            child: const Text("Submit Unit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
  Future<String?> uploadImage(File image) async {
  final token = await Api.getToken();

  final request = http.MultipartRequest(
    "POST",
    Uri.parse(Api.upload),
  );

  request.headers["Authorization"] = "Bearer $token";
  request.files.add( 
    await http.MultipartFile.fromPath("file", image.path),
  );

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await http.Response.fromStream(response);
    return jsonDecode(res.body)["imagePath"];
  }

  return null;
}

}
