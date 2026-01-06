import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<dynamic> allTransactions = []; // full list from API
  List<dynamic> transactions = []; // currently displayed
  bool loading = true;
  bool loadingMore = false;
  int page = 0; // current page
  final int pageSize = 20; // number of items per page

  Map<int, String> itemMap = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadItems().then((_) => loadAllTransactions());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !loadingMore) {
        loadMoreTransactions();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        itemMap = {for (var item in data) item['id']: item['name']};
      }
    } catch (e) {
      debugPrint("Item load error: $e");
    }
  }

  Future<void> loadAllTransactions() async {
    try {
      final token = await Api.getToken();
      final res = await http.get(
        Uri.parse(Api.transactions),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        allTransactions = jsonDecode(res.body);
        transactions = [];
        page = 0;
        loadMoreTransactions(); // load first page
      }
    } catch (e) {
      debugPrint("Transaction load error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void loadMoreTransactions() {
    if (loadingMore) return;
    if (page * pageSize >= allTransactions.length) return;

    setState(() => loadingMore = true);

    // calculate start and end index for next page
    final start = page * pageSize;
    final end = start + pageSize;
    final nextPageItems =
        allTransactions.sublist(start, end > allTransactions.length ? allTransactions.length : end);

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        transactions.addAll(nextPageItems);
        page++;
        loadingMore = false;
      });
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return "";
    try {
      DateTime dt = DateTime.parse(value.toString());
      return DateFormat("dd MMM yyyy • hh:mm a").format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Transactions",style: TextStyle(color: Colors.white),)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text("No transactions found"))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: transactions.length + (loadingMore ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index == transactions.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final t = transactions[index];
                    final bool isIn =
                        t['type']?.toString().toUpperCase() == "IN";
                    final itemName = itemMap[t['itemId']] ?? "Unknown Product";
                    final qty = (t['quantity'] is num)
                        ? (t['quantity'] as num).toInt().toString()
                        : t['quantity'].toString();
                    final dateText = formatDate(t['createdAt'] ?? t['date']);
                    final String? imagePath = t['imagePath'];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: isIn ? Colors.green : Colors.red,
                              child: Icon(
                                isIn ? Icons.arrow_downward : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Quantity: $qty"),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (imagePath != null && imagePath.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  Api.imageBase.endsWith("/")
                                      ? "${Api.imageBase}$imagePath"
                                      : "${Api.imageBase}/$imagePath",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
