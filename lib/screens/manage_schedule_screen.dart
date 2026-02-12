import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_webview.dart';
import 'schedule_form_screen.dart'; // Pastikan file form baru sudah diimport

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  // --- 1. LOAD DATA (READ) ---
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
      _handleError(e, _loadSchedules);
    }
  }

  // --- 2. BUKA FORM TAMBAH / EDIT ---
  Future<void> _openFormScreen({Map<String, dynamic>? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(item: item),
      ),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  // --- 3. FUNGSI HAPUS (DELETE) ---
  Future<void> _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Jadwal?"),
        content: const Text("PERINGATAN: Semua data presensi di dalam jadwal ini akan ikut terhapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await _api.deleteSchedule(id);
        await _loadSchedules();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal Dihapus")));
        }
      } catch (e) {
        _handleError(e, () => _deleteItem(id));
      }
    }
  }

  // --- 4. PENANGANAN ERROR ---
  Future<void> _handleError(Object e, Function retryCallback) async {
    if (e.toString().contains("BLOCK_BY_INFINITYFREE")) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memperbarui Koneksi Keamanan...")));
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginWebview()));
        retryCallback();
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Gagal"),
              content: Text(e.toString()),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu-abu muda modern
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kelola Jadwal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            Text("Buat, Edit, atau Hapus Jadwal", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Jadwal Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _openFormScreen(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: _schedules.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemBuilder: (context, index) {
          final item = _schedules[index];
          return _buildScheduleCard(item);
        },
      ),
    );
  }

  // --- WIDGET: KARTU JADWAL MODERN ---
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Indikator Warna di Sisi Kiri
              Container(
                width: 6,
                color: isActive ? Colors.green : Colors.grey.shade300,
              ),

              // 2. Konten Kartu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Status & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(isActive),
                          // Tombol Edit & Delete Kecil
                          Row(
                            children: [
                              _buildActionButton(
                                icon: Icons.edit_rounded,
                                color: Colors.orange,
                                onTap: () => _openFormScreen(item: item),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete_rounded,
                                color: Colors.red,
                                onTap: () => _deleteItem(item['id']),
                              ),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Judul Jadwal
                      Text(
                        item['name'] ?? 'Tanpa Nama',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),

                      const SizedBox(height: 8),

                      // Info Waktu (Baris Icon)
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 16, color: Colors.blueAccent.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text(
                            "${item['service_start_time']} - ${item['end_time']}",
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Info Tambahan (Wajib & Briefing)
                      Row(
                        children: [
                          _buildInfoChip(Icons.warning_amber_rounded, "Batas: ${item['late_limit_time'] ?? '-'}"),
                          const SizedBox(width: 12),
                          _buildInfoChip(Icons.mic_none_rounded, "Brief: ${item['briefing_time'] ?? '-'}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: BADGE STATUS ---
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: isActive ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(
            isActive ? "AKTIF" : "NON-AKTIF",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: INFO CHIP KECIL ---
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // --- WIDGET HELPER: TOMBOL AKSI KECIL ---
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // --- WIDGET HELPER: EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada jadwal dibuat.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Tekan tombol + untuk membuat jadwal baru.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}