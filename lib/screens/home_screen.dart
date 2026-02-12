import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_webview.dart';
import 'manage_schedule_screen.dart'; // Menu Kelola (CRUD)
import 'qr_display_screen.dart';
import 'monitoring_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getSchedules();
      if (mounted) {
        setState(() {
          _schedules = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains("BLOCK_BY_INFINITYFREE")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menghubungkan ke Server...")));
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginWebview()));
          _loadSchedules();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          // Silent fail atau tampilkan snackbar
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background modern (abu-abu muda)
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daftar Jadwal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Pilih jadwal untuk memantau", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageScheduleScreen()))
                    .then((_) => _loadSchedules()); // Refresh saat kembali
              },
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.settings, color: Colors.white, size: 20),
              ),
              tooltip: "Kelola Jadwal",
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadSchedules,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: _schedules.length,
          itemBuilder: (context, index) {
            final item = _schedules[index];
            return _buildScheduleCard(item);
          },
        ),
      ),
    );
  }

  // --- WIDGET: KARTU JADWAL YANG DIPERBAGUS ---
  Widget _buildScheduleCard(dynamic item) {
    final bool isActive = item['is_active'] == true || item['is_active'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Border hijau jika aktif
        border: isActive ? Border.all(color: Colors.green, width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MonitoringScreen(
                  scheduleId: item['id'],
                  scheduleName: item['name'] ?? 'Detail Monitoring',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 1. Indikator Ikon Kiri
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.broadcast_on_personal : Icons.event,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Teks Informasi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Status Kecil
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "SEDANG AKTIF",
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),

                      Text(
                        item['name'] ?? 'Tanpa Nama',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "${item['service_start_time']} - ${item['end_time']}",
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Tombol QR Code (Terpisah)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_2, color: Colors.indigo),
                    tooltip: "Tampilkan QR",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QrDisplayScreen(scheduleItem: item),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: EMPTY STATE (JIKA KOSONG) ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada jadwal tersedia.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Buat jadwal baru di menu Kelola.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}