import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<dynamic> stock = [];
  bool loading = true;

  // itemId -> itemName
  Map<int, String> itemMap = {};

  @override
  void initState() {
    super.initState();
    loadItems().then((_) => loadStock());
  }

  // Load items
  Future<void> loadItems() async {
    final token = await Api.getToken();
    final res = await http.get(
      Uri.parse(Api.items),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    setState(() {
      itemMap = {
        for (var item in data) item['id'] as int: item['name'].toString()
      };
    });
  }

  // Load stock
  Future<void> loadStock() async {
    final token = await Api.getToken();
    final res = await http.get(
      Uri.parse(Api.stock),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() {
      stock = jsonDecode(res.body) ?? [];
      loading = false;
    });
  }

  Color qtyColor(int qty) {
    if (qty <= 1) return Colors.red;
    if (qty < 5) return Colors.orange;
    return Colors.green;
  }

  int parseQty(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt(); 
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Stock Overview",style: TextStyle(color:Colors.white),)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : stock.isEmpty
              ? const Center(child: Text("No stock available"))
              : ListView.builder(
                  itemCount: stock.length,
                  itemBuilder: (_, i) {
                    final s = stock[i];

                    final int itemId = s['itemId'] ?? 0;
                    final String itemName =
                        itemMap[itemId] ?? "Unknown Item";

                    final int quantity = parseQty(s['quantity']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              qtyColor(quantity).withOpacity(0.15),
                          child: Icon(Icons.inventory,
                              color: qtyColor(quantity)),
                        ),
                        title: Text(
                          itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Item ID: $itemId"),
                        trailing: Text(
                          "Qty: $quantity", // ✅ NO .0
                          style: TextStyle(
                            color: qtyColor(quantity),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
