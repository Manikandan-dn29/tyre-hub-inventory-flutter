import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  Map<int, String> itemMap = {}; // id -> name

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

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _items = data;
          _filteredItems = data;
          itemMap = {for (var item in data) item['id']: item['name']};
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        debugPrint("Failed to load items: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Error loading items: $e");
    }
  }

  void _search(String value) {
    setState(() {
      _filteredItems = _items.where((item) {
        return item['name']
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase()) ||
            item['itemCode']
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Item Master",style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: "Search item name / code",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // 📦 Item List
                Expanded(
                  child: _filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, i) {
                            final item = _filteredItems[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.blue.withOpacity(0.15),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("Code: ${item['itemCode']}"),
                                    Text("Unit: ${item['unit']}"),
                                    Text("Barcode: ${item['barcode']}"),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
