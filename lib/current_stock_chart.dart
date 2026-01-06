import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

enum StockRange { day, week, month }

class CurrentStockChart extends StatefulWidget {
  final StockRange range;

  const CurrentStockChart({
    super.key,
    required this.range,
  });

  @override
  State<CurrentStockChart> createState() => _CurrentStockChartState();
}

class _CurrentStockChartState extends State<CurrentStockChart> {
  bool loading = true;
  List<FlSpot> spots = [];  

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  @override
  void didUpdateWidget(covariant CurrentStockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      loadStock();
    }
  }

  Future<void> loadStock() async {
  setState(() => loading = true);

  final token = await Api.getToken();
  final res = await http.get(
    Uri.parse(Api.stock),
    headers: {"Authorization": "Bearer $token"},
  );

  final List data = jsonDecode(res.body);

  final List<FlSpot> chartSpots = [];
  final List<String> names = [];
  double x = 0;

  for (var s in data) {
    final qty = s['quantity'];
    if (qty == null) continue;

    // ✅ SAFE item name extraction
    String name = "Item ${x.toInt() + 1}";
    if (s['itemName'] != null) {
      name = s['itemName'].toString();
    } else if (s['item'] != null && s['item']['name'] != null) {
      name = s['item']['name'].toString();
    }


    chartSpots.add(
      FlSpot(x, (qty as num).toDouble()),
    );
     names.add(name);

    x++;
  }

  setState(() {
    spots = chartSpots;
    loading = false;
     itemNames = names;
  });
}
List<String> itemNames = [];



  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text("No stock data", style: TextStyle(color: Colors.white)),
      );
    }

    return Container(
      height: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
           bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    interval: 1,
    getTitlesWidget: (value, _) {
      final index = value.toInt();

      if (index < 0 || index >= itemNames.length) {
        return const SizedBox.shrink();
      }

      return SideTitleWidget(
        axisSide: AxisSide.bottom,
        space: 6,
        child: Transform.rotate(
          angle: 0, // 🔥 tilt text
          child: Text(
            itemNames[index],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    },
  ),
),

            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.deepOrangeAccent,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepOrangeAccent.withOpacity(0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
