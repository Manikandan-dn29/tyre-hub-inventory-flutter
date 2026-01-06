import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'scanner.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class IssuedUnit {
  final String name;
  final String barcode;
  final int quantity;
   final File? image; 

  IssuedUnit({
    required this.name,
    required this.barcode,
    this.quantity = 1,
    this.image,
  });
}

class _IssuePageState extends State<IssuePage> {
  List<dynamic> items = [];
  int? selectedItemId;

  int submittedCount = 0;
  String? currentBarcode;
  bool loading = true;

   String? uploadedImagePath; 

  List<IssuedUnit> issuedUnits = [];

  File? capturedImage; // ✅ ADDED
  final ImagePicker _picker = ImagePicker();
  
  get imagePath => null;
  
// ✅ ADDED

  @override
  void initState() {
    super.initState();
    loadItems();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load items: $e")),
      );
    }
  }

    /// 📷 CAMERA CAPTURE
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

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${Api.baseUrl}/upload"),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(body);
      uploadedImagePath = json['imagePath']; // ✅ STORED
    } else {
      throw Exception("Image upload failed");
    }
  }


  Future<void> submitUnit() async {
    if (currentBarcode == null || selectedItemId == null) return;

    setState(() => loading = true);

    final token = await Api.getToken();
    final res = await http.post(
      Uri.parse("${Api.issue}/unit"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
     body: jsonEncode({
      "itemId": selectedItemId,
      "barcode": currentBarcode,
      "quantity": 1,
      "type": "OUT",
      "imagePath": uploadedImagePath,  // 🔥 THIS WAS MISSING
      }),
    );

    

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final itemName =
          items.firstWhere((i) => i['id'] == selectedItemId)['name'];

      setState(() {
        submittedCount++;
        issuedUnits.add(IssuedUnit(
          name: itemName,
          barcode: currentBarcode!,
          quantity: 1,
           image: capturedImage,
        ));
        currentBarcode = null;
         capturedImage = null;
         uploadedImagePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unit Issued ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.body)),
      );
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

  void manualBarcodeEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Barcode"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter barcode",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => currentBarcode = ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Issue Material",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold, fontSize: 20),
        ),
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

                 TextField(
                          decoration: const InputDecoration(
                            labelText: "Supplier Name",
                            prefixIcon: Icon(Icons.factory),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                              
               DropdownButtonFormField<int>(
                      value: selectedItemId,
                      hint: const Text("Select Item"),
                    
                      items: items
                          .map<DropdownMenuItem<int>>(
                            (item) => DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(
                                item['name'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: "Item",
                        prefixIcon: Icon(Icons.inventory_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (v) => setState(() => selectedItemId = v),
                    ),
               

                const SizedBox(height: 20),

                /// BARCODE ACTIONS
             Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade600,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner,color: Colors.white,),
                                label: const Text("Scan",style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: manualBarcodeEntry,
                                icon: const Icon(Icons.keyboard,color: Colors.white,),
                                label: const Text("Manual",style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (currentBarcode != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Barcode: $currentBarcode",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),

                            /// 📷 CAMERA BUTTON
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Image"),
                ),


                /// 🖼 IMAGE PREVIEW + RETAKE
                if (capturedImage != null) ...[
                  const SizedBox(height: 10),
                  Image.file(capturedImage!, height: 200, fit: BoxFit.cover),
                  TextButton.icon(
                    onPressed: captureImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retake"),
                  ),
                ],




                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: submitUnit,
                            child: const Text(
                              "Submit Issue",
                              style: TextStyle(color: Colors.white,fontSize: 16,),
                            ),
                          ),
                        ),
                      ],
                    ),
               

                const SizedBox(height: 20),

                /// ISSUE SUMMARY
                if (issuedUnits.isNotEmpty) ...[
                  const Text(
                    "Issued Details",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...issuedUnits.map(
                    (u) => Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.inventory, color: Colors.red),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Barcode: ${u.barcode}"),
                            Text("Quantity: ${u.quantity}"),
                            if (u.image != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.file(
                                u.image!,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Total Issued Units: $submittedCount",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
    );
  }
}
