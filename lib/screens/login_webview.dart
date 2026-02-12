import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginWebview extends StatefulWidget {
  const LoginWebview({super.key});

  @override
  State<LoginWebview> createState() => _LoginWebviewState();
}

class _LoginWebviewState extends State<LoginWebview> {
  late final WebViewController controller;

  // --- BAGIAN YANG HILANG (INI PENYEBAB ERROR) ---
  bool isLoading = true;
  // -----------------------------------------------

  // Identitas Samaran (User Agent) agar server tidak curiga
  final String userAgentRahasia = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36";

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgentRahasia) // Pasang Identitas Samaran
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            // Halaman selesai loading, saatnya curi cookie!
            await _extractCookie();

            // Matikan loading jika masih di halaman ini
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
        ),
      )
    // Gunakan HTTPS agar Android senang
      ..loadRequest(Uri.parse('https://presensimusik.infinityfreeapp.com/login'));
  }

  Future<void> _extractCookie() async {
    try {
      // Jalankan Javascript untuk mengambil cookie dokumen
      final Object result = await controller.runJavaScriptReturningResult('document.cookie');
      final String cookies = result.toString();

      // Bersihkan format string
      String cleanCookies = cookies.replaceAll('"', '');

      if (cleanCookies.contains('__test')) {
        // HORE! Cookie keamanan InfinityFree ditemukan
        print("✅ Cookie Ditemukan: $cleanCookies");

        // Simpan ke memori HP
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cookie_bypass', cleanCookies);

        if (mounted) {
          // Kembali ke halaman utama dengan membawa kabar gembira
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Koneksi ke Server Berhasil!")),
          );
        }
      }
    } catch (e) {
      print("Gagal ambil cookie: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Menghubungkan ke Server...")),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          // Indikator Loading (Spinner)
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Sedang melewati keamanan...", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}