import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_webview.dart';

class MonitoringScreen extends StatefulWidget {
  final int scheduleId;
  final String? scheduleName; // Opsional, untuk judul AppBar

  const MonitoringScreen({
    super.key,
    required this.scheduleId,
    this.scheduleName,
  });

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getMonitoring(widget.scheduleId);
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains("BLOCK_BY_INFINITYFREE")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menghubungkan ke Server...")));
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginWebview()));
          _loadData();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat: $e")));
        }
      }
    }
  }

  // Menampilkan Foto Fullscreen
  void _showPhotoDialog(String photoUrl, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data statistik dari JSON (pastikan backend mengirim key ini)
    // Jika backend strukturnya { "schedule": {...}, "attendances": [...], "summary": { "total": 10, ... } }
    // Sesuaikan parsing di bawah ini. Kode ini mengasumsikan kita hitung manual atau backend kirim flat.

    final List attendances = _data?['attendances'] ?? [];

    // Hitung manual statistik jika backend tidak menyediakan ringkasan langsung
    int total = attendances.length;
    int lateCount = attendances.where((a) => (a['is_late'] == 1 || a['is_late'] == true || (a['late_minutes'] ?? 0) > 0)).length;
    int onTimeCount = total - lateCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.scheduleName ?? "Detail Monitoring", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            Text("Live Update", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STATISTIK CARD ROW
              Row(
                children: [
                  Expanded(child: _buildStatCard("Total", "$total", Colors.blueAccent, Icons.group)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Tepat", "$onTimeCount", Colors.green, Icons.check_circle)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Telat", "$lateCount", Colors.redAccent, Icons.warning)),
                ],
              ),

              const SizedBox(height: 24),

              // 2. HEADER LIST
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Daftar Kehadiran", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("${attendances.length} Orang", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),

              // 3. ATTENDANCE LIST
              attendances.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendances.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = attendances[index];
                  return _buildAttendeeCard(item);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: KARTU PESERTA ---
  Widget _buildAttendeeCard(dynamic item) {
    bool isLate = (item['late_minutes'] ?? 0) > 0;

    // URL Foto dengan bypass hosting
    String? photoPath = item['photo_path'];
    String? fullPhotoUrl;
    if (photoPath != null && photoPath.isNotEmpty) {
      fullPhotoUrl = "https://presensimusik.infinityfreeapp.com/lihat-gambar/$photoPath";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // FOTO PROFIL
        leading: GestureDetector(
          onTap: () {
            if (fullPhotoUrl != null) _showPhotoDialog(fullPhotoUrl, item['guest_name']);
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.indigo.shade50,
            backgroundImage: fullPhotoUrl != null ? NetworkImage(fullPhotoUrl) : null,
            child: fullPhotoUrl == null
                ? Text((item['guest_name'] ?? 'U')[0].toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.indigo))
                : null,
          ),
        ),
        // NAMA & INSTRUMEN
        title: Text(
          item['guest_name'] ?? 'Tanpa Nama',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.music_note, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(item['instrument'] ?? '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                // Pastikan API mengirim 'check_in_time' atau format jamnya
                Text(item['check_in_at'] != null ? item['check_in_at'].toString().split(' ').last.substring(0,5) : '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ],
        ),
        // STATUS BADGE
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLate ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLate ? "Telat ${item['late_minutes']}m" : "Tepat Waktu",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLate ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: STATISTIK ---
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.person_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Belum ada yang hadir.", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}