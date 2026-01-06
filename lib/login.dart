import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

 Future<void> login() async {
  if (userCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
   showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text("Login Failed"),
    content: const Text("Invalid username or password"),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("OK"),
      ),
    ],
  ),
);
    return;
  }

  setState(() => loading = true);

  try {
    final res = await http.post(
      Uri.parse(Api.login),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": userCtrl.text.trim(),
        "password": passCtrl.text.trim(),
      }),
    );

    debugPrint("STATUS CODE: ${res.statusCode}");
    debugPrint("RESPONSE BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final String token = data['token'];
      final String refreshToken = data['refreshToken'];


  debugPrint("===== LOGIN SUCCESS =====");
  debugPrint("ACCESS TOKEN:");
  debugPrint(token);
  debugPrint("REFRESH TOKEN:");
  debugPrint(refreshToken);
  debugPrint("=========================");



      if (token.isEmpty || refreshToken.isEmpty) {
  throw Exception("Token missing");
}


      // ✅ SAVE TOKEN
     await Api.saveTokens(token, refreshToken);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  } catch (e) {
    debugPrint("LOGIN ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login failed"))
    );
  }

  setState(() => loading = false);
}


 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            "assets/images/Tyre.jpg", 
            fit: BoxFit.cover,
          ),
        ),
        Container(
          color: Colors.grey.withOpacity(0.6),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      backgroundImage:
          const AssetImage('assets/images/tyreIcon.jpg'),
    ),
    const SizedBox(width: 12),
    const Text(
      "TyreHub Login",
      style: TextStyle(
        color: Colors.deepOrangeAccent,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),

                  const SizedBox(height: 20),
                  const Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 10),

                  // USERNAME 
                  TextField(
                    controller: userCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Username",
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.person_outline, color: Colors.white54),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 0, 0, 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  PASSWORD 
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.white54),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 0, 0, 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  //  LOGIN BUTTON 
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle( color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  FOOTER 
                  const Center(
                    child: Text(
                      "© 2025 Inventory System",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
