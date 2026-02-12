import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'qr_spot_screen.dart'; // Pastikan file ini ada
import '../services/api_service.dart';
import 'login_webview.dart';
import 'manage_schedule_screen.dart';
import 'home_screen.dart';
// import 'monitoring_screen.dart'; // Matikan jika belum ada

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getDashboard();
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains("BLOCK_BY_INFINITYFREE")) {
        if (mounted) {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LoginWebview()));
          _loadDashboard();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Admin",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            Text(
              "Overview Sistem Presensi",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _loadDashboard,
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text("Gagal memuat data"))
          : RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Menu Utama", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildModernMenuGrid(),
              const SizedBox(height: 24),
              _buildActiveScheduleCard(),
              const SizedBox(height: 24),
              Text("Ringkasan Bulan Ini", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total Hadir",
                      "${_data!['hadir_bulan_ini'] ?? 0}",
                      Colors.green,
                      Icons.people_alt_rounded,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      "Kegiatan",
                      "${_data!['total_jadwal'] ?? 0}",
                      Colors.blueAccent,
                      Icons.event_note_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text("Analisis Kehadiran", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildChartSection(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Baru Saja Hadir", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentList(), // FOTO DIPERBAIKI DI SINI
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMenuButton(
            icon: Icons.edit_calendar_rounded,
            label: "Kelola",
            color: Colors.blueAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageScheduleScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMenuButton(
            icon: Icons.monitor_heart_rounded,
            label: "Semua",
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMenuButton(
            icon: Icons.qr_code_scanner_rounded,
            label: "QR Spot",
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrSpotScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScheduleCard() {
    final active = _data!['active_schedule'];

    if (active == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Tidak ada jadwal aktif saat ini", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text("SEDANG BERLANGSUNG", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Icon(Icons.wifi_tethering, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            active['name'] ?? "Jadwal Tanpa Nama",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Mulai: ${active['service_start_time'] ?? '-'} WIB",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Detail Monitoring")));
              },
              icon: const Icon(Icons.visibility, color: Color(0xFF4F46E5)),
              label: const Text("Lihat Monitoring Live"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    int onTime = _data!['chart_data']?['on_time'] ?? 0;
    int late = _data!['chart_data']?['late'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(value: onTime.toDouble(), color: Colors.green, radius: 25, showTitle: false),
                  PieChartSectionData(value: late.toDouble(), color: Colors.redAccent, radius: 22, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, "Tepat Waktu", "$onTime Orang"),
                const SizedBox(height: 12),
                _buildLegendItem(Colors.redAccent, "Terlambat", "$late Orang"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // --- PERBAIKAN: FOTO SUDAH MUNCUL KEMBALI ---
  Widget _buildRecentList() {
    List recent = _data!['recent_attendances'] ?? [];
    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text("Belum ada data kehadiran.", style: GoogleFonts.poppins(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: recent.map<Widget>((item) {
        bool isLate = (item['status'] ?? '').toString().toLowerCase().contains('telat');

        // Logika untuk menampilkan Foto
        String? photoPath = item['photo_path'];
        String? fullPhotoUrl;
        if (photoPath != null && photoPath.isNotEmpty) {
          // Pakai route bypass hosting
          fullPhotoUrl = "https://presensimusik.infinityfreeapp.com/lihat-gambar/$photoPath";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // Tampilkan FOTO jika ada URL, jika tidak tampilkan inisial
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.indigo.shade50,
              backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
              child: fullPhotoUrl == null
                  ? Text(
                (item['name'] ?? 'U')[0].toString().toUpperCase(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.indigo),
              )
                  : null,
            ),
            title: Text(item['name'] ?? '-', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(item['position'] ?? 'Musik', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLate ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['status'] ?? '-',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLate ? Colors.red : Colors.green
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}