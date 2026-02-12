import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_webview.dart';

class MonitoringScreen extends StatefulWidget {
  final int scheduleId;
  final String? scheduleName;

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
    _loadMonitoring();
  }

  Future<void> _loadMonitoring() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getMonitoring(widget.scheduleId);

      // DEBUG: Lihat isi data di console
      print("DATA MONITORING: $result");

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
            context,
            MaterialPageRoute(builder: (_) => const LoginWebview()),
          );
          _loadMonitoring();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  void _showFullImage(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => const Column(
                        children: [
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          Text("Gagal memuat gambar"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.red,
                radius: 14,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
              widget.scheduleName ?? "Monitoring Live",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            Text(
              _data != null ? "${_data!['total_attendances'] ?? 0} Hadir" : "Memuat...",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(onPressed: _loadMonitoring, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text("Gagal memuat data"))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // Backend Anda menggunakan key 'data', jadi kita ambil itu.
    List attendees = _data?['data'] ?? [];

    if (attendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text("Belum ada data kehadiran.", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final item = attendees[index];

        // 1. DATA NAMA & INFO
        String name = item['guest_name'] ?? item['name'] ?? 'Tanpa Nama';
        String instrument = item['instrument'] ?? '-';
        String checkIn = item['check_in_time'] ?? item['check_in_at'] ?? '-';

        // 2. LOGIKA URL FOTO (Anti Error 404)
        String? photoUrl;
        String? rawPhoto = item['photo_url']; // Sesuai update backend di atas

        if (rawPhoto != null && rawPhoto.isNotEmpty) {
          // Backend sudah mengirim full URL (https://...), jadi langsung pakai
          photoUrl = rawPhoto;
        }

        // 3. LOGIKA STATUS & TELAT
        bool isLate = (item['status'] ?? '').toString().toLowerCase().contains('terlambat');
        int lateMinutes = item['late_minutes'] ?? 0; // Backend sudah kirim ini sekarang

        String statusDisplay = isLate ? "TERLAMBAT" : "TEPAT WAKTU";
        if (isLate && lateMinutes > 0) {
          statusDisplay += "\n($lateMinutes Menit)";
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (photoUrl != null) {
                _showFullImage(context, photoUrl, name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada foto")));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // AVATAR
                  Hero(
                    tag: "avatar_$index",
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.indigo.shade50,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.indigo))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),

                  // INFO UTAMA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.music_note, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(instrument, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(checkIn, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLate ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isLate ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusDisplay,
                      textAlign: TextAlign.center,
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
          ),
        );
      },
    );
  }
}