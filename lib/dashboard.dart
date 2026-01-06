import 'dart:async';
// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:mrf_inventory/notification_page.dart';
import 'package:mrf_inventory/notification_service.dart';
import 'package:mrf_inventory/stock_adjustment.dart';
import 'api.dart';
import 'grn.dart';
import 'issue.dart';
import 'items_page.dart';
import 'stock_page.dart';
import 'transaction_page.dart';
import 'login.dart';
import 'current_stock_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {


Widget _erpCard(
  String title,
  IconData icon,
  Color accentColor,
  Widget page,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 26),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}



// Toggle button state
// ignore: prefer_final_fields
List<bool> _toggleSelections = [true, false, false];
StockRange _selectedRange = StockRange.day;




int _stockBadgeCount = 2; 


 late String _currentTime;
    Timer? _clockTimer;
 

 Timer? _expiryTimer;
  DateTime? _tokenExpiry;
  String _countdownText = "";

 int _navIndex = 0;

  @override
  void initState() {
    super.initState();

     ///  LIVE CLOCK
    _currentTime = _formatDateTime(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = _formatDateTime(DateTime.now());
      });
    });

     /// 🔐 TOKEN CHECK AFTER FIRST FRAME
   WidgetsBinding.instance.addPostFrameCallback((_) async {
      var token = await Api.getToken();

  debugPrint("===== DASHBOARD TOKEN =====");
  debugPrint("ACCESS TOKEN:");
  debugPrint(token ?? "NULL");
  debugPrint("===========================");

      if (!mounted) return;

     if (token == null) {
  _goToLogin();
  return;
}

if (Api.isTokenExpired(token)) {
  final refreshed = await Api.refreshAccessToken();

  if (!refreshed) {
    await Api.removeToken();
    _goToLogin();
    return;
  }

  // get new token after refresh
  token = await Api.getToken();
}

_tokenExpiry = Api.getTokenExpiry(token!);
if (_tokenExpiry != null) {
  _startExpiryCountdown();
}
    });
  }
 void _startExpiryCountdown() {
    _expiryTimer?.cancel();

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _tokenExpiry == null) return;

      final remaining = _tokenExpiry!.difference(DateTime.now());

      if (remaining.isNegative) {
        _expiryTimer?.cancel();
        _handleTokenExpiry(); // async handled safely
      } else {
        final minutes = remaining.inMinutes.remainder(60);
        final seconds = remaining.inSeconds.remainder(60);

        setState(() {
          _countdownText =
              "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        });
      }
    });
  }


   ///  REFRESH TOKEN
  Future<void> _handleTokenExpiry() async {
    final refreshed = await Api.refreshAccessToken();

  debugPrint("===== TOKEN REFRESH =====");
  debugPrint("REFRESH STATUS: $refreshed");


    if (!refreshed) {
      await Api.removeToken();
      _goToLogin();
      return;
    }

    final newToken = await Api.getToken();
    if (newToken == null) {
      _goToLogin();
      return;
    }

    _tokenExpiry = Api.getTokenExpiry(newToken);
    if (_tokenExpiry != null) {
      _startExpiryCountdown();
    }
  }


void _goToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }



   @override
  void dispose() {
    _clockTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }



   String _formatDateTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? "PM" : "AM";
    return "${dt.day.toString().padLeft(2, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.year}  "
        "${hour12.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')} $amPm";
  }

   /// 🚪 LOGOUT CONFIRMATION
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await Api.removeToken();
              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          SizedBox.expand(
            child: Image.asset(
              "assets/images/TyreBackGround.jpg",
              fit: BoxFit.fill,
            ),
          ),

          // DARK OVERLAY
          // ignore: deprecated_member_use
          Container(color: Colors.black.withOpacity(0.45)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

               Align(
  alignment: Alignment.topRight,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      //  NOTIFICATION ICON
      Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
            onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationPage()),
        );
        setState(() {});
      },
    ),
    if (NotificationService.unreadCount() > 0)
      Positioned(
        right: 6,
        top: 6,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: Text(
            NotificationService.unreadCount().toString(),
            style: const TextStyle(
                color: Colors.white, fontSize: 10),
          ),
        ),
      ),
  ],
),

      //  LOGOUT ICON
      IconButton(
        icon: const Icon(
          Icons.power_settings_new_rounded,
          color: Colors.white,
        ),
        onPressed: _showLogoutDialog,
      ),
    ],
  ),
),

                // HEADER CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 14),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),  
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                        
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 23,
                          backgroundImage: AssetImage('assets/images/tyreIcon.jpg'),
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.deepOrange, Colors.redAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            "TyreHub",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // DATE TIME
                Text(
                  _currentTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),

                 ///  COUNTDOWN
                if (_countdownText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Session expires in: $_countdownText",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),


                const SizedBox(height: 10),

 // GRID + CHART (SCROLLABLE)
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      children: [
                        _erpCard("GRN (IN)",
                            Icons.arrow_downward,
                            Colors.greenAccent,
                            const GrnPage()),
                        _erpCard("Issue (OUT)",
                            Icons.arrow_upward,
                            Colors.redAccent,
                            const IssuePage()),
                        _erpCard("Items Master",
                            Icons.inventory_2_outlined,
                            Colors.blueAccent,
                            const ItemsPage()),
                        _erpCard("Stock Balance",
                            Icons.warehouse_outlined,
                            Colors.tealAccent,
                            const StockPage()),
                       _erpCard(
                             "Stock Adjustment",
                             Icons.build_circle,
                           Colors.orangeAccent,
                            const StockAdjustmentPage()),

                      ],
                    ),

                    const SizedBox(height: 18),

                  CurrentStockChart(range: _selectedRange),






                    const SizedBox(height: 16),

                  _toggleSection(),

                    const SizedBox(height: 12),


                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    

    // ✅ BOTTOM NAV BAR (CORRECT POSITION)
   bottomNavigationBar: BottomNavigationBar(
  currentIndex: _navIndex,
  backgroundColor: Colors.black,
  selectedItemColor: Colors.white54,
  unselectedItemColor: Colors.white54,
  type: BottomNavigationBarType.fixed,
 onTap: (index) async {
  if (_navIndex == index) return; // prevent reload

  setState(() => _navIndex = index);

  switch (index) {
    case 0:
      // Dashboard (chart is already here)
      return;

    case 1:
      setState(() => _stockBadgeCount = 0);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StockPage()),
      );
      break;

    case 2:
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionPage()),
      );
      break;

    case 3:
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ItemsPage()),
      );
      break;
  }

  // restore dashboard index when coming back
  if (mounted) {
    setState(() => _navIndex = 0);
  }
},

  items: [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: "Dashboard",
    ),

    // ✅ STOCK WITH BADGE
    BottomNavigationBarItem(
      icon: _badgeIcon(
        icon: Icons.warehouse,
        count: _stockBadgeCount,
      ),
      label: "Stock",
    ),

    const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: "Transactions",
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2),
      label: "Items",
    ),
  ],
),

  );
}


Widget _toggleSection() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: ToggleButtons(
      isSelected: _toggleSelections,
      onPressed: (index) {
        setState(() {
          for (int i = 0; i < _toggleSelections.length; i++) {
            _toggleSelections[i] = i == index;
          }
          _selectedRange = StockRange.values[index];
        });
      },
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.white,
      color: Colors.white70,
      fillColor: Colors.deepOrangeAccent,
      borderColor: Colors.white24,
      selectedBorderColor: Colors.deepOrangeAccent,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
      children: const [
        Text("Day"),
        Text("Week"),
        Text("Month"),
      ],
    ),
  );
}



Widget _badgeIcon({
  required IconData icon,
  required int count,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon),
      if (count > 0)
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
  }

 
       
