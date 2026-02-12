import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';

class QrSpotScreen extends StatefulWidget {
  const QrSpotScreen({super.key});

  @override
  State<QrSpotScreen> createState() => _QrSpotScreenState();
}

class _QrSpotScreenState extends State<QrSpotScreen> {
  final ApiService api = ApiService();
  final ScreenshotController screenshotController = ScreenshotController();

  List spots = [];
  List schedules = [];
  bool isLoading = true;

  // URL Dasar untuk QR Code
  final String baseQrUrl = "https://presensimusik.infinityfreeapp.com/q/";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      // Asumsi fungsi ini ada di ApiService Anda sesuai kode awal
      final spotData = await api.getQrSpots();
      final scheduleData = await api.getSchedules();

      if (mounted) {
        setState(() {
          spots = spotData;
          schedules = scheduleData;
          isLoading = false;
        });
      }
    } catch (e) {
      print("ERROR LOAD DATA: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateSpot(int spotId, int? scheduleId) async {
    // Tampilkan loading kecil atau snackbar proses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Memperbarui Spot..."), duration: Duration(milliseconds: 500)),
    );

    await api.updateQrSpot(spotId, scheduleId);
    await loadData(); // Reload agar UI sync

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil diperbarui!"), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> saveQr() async {
    // Minta Izin Penyimpanan (Untuk Android < 13)
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final image = await screenshotController.capture();
    if (image == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory(); // Lebih aman di Android baru
      // Atau gunakan getExternalStorageDirectory untuk folder publik (perlu izin lebih)

      final fileName = "QR_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File("${directory.path}/$fileName");

      await file.writeAsBytes(image);

      if (mounted) {
        Navigator.pop(context); // Tutup Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("QR disimpan di: ${file.path}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal simpan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void showQrDialog(String uniqueCode, String spotName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("QR Master", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
              Text(spotName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        // PERBAIKAN UTAMA DI SINI:
        // Kita bungkus content dengan SizedBox agar lebarnya jelas
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: "$baseQrUrl$uniqueCode",
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(0), // Reset padding internal QR
                        ),
                        const SizedBox(height: 10),
                        Text(
                          uniqueCode,
                          style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                        ),
                        const Text("Scan untuk Absen", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveQr,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text("Simpan ke Galeri"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background modern
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Titik QR (Spots)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            Text("Kelola lokasi scan QR Code", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : spots.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          return _buildSpotCard(spot);
        },
      ),
    );
  }

  Widget _buildSpotCard(dynamic spot) {
    // Cek apakah ada jadwal yang nempel
    bool isLinked = spot['current_schedule_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // HEADER KARTU
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLinked ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isLinked ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot['name'] ?? "Lokasi Tanpa Nama",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Icon(Icons.qr_code, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            "ID: ${spot['unique_code']}",
                            style: GoogleFonts.sourceCodePro(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Lihat QR",
                  onPressed: () => showQrDialog(spot['unique_code'], spot['name']),
                  icon: const Icon(Icons.qr_code_2, size: 32, color: Colors.indigo),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // BAGIAN DROPDOWN (CONTROL PANEL)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Jadwal Terhubung:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: spot['current_schedule_id'],
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.indigo),
                      hint: const Text("Pilih Jadwal..."),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.highlight_off, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text("Tidak Terkait (Idle)", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        ...schedules.map<DropdownMenuItem<int?>>((s) {
                          bool isActive = s['is_active'] == 1 || s['is_active'] == true;
                          return DropdownMenuItem<int?>(
                            value: s['id'],
                            child: Row(
                              children: [
                                Icon(Icons.event, color: isActive ? Colors.green : Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  s['name'],
                                  style: TextStyle(
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? Colors.black87 : Colors.grey
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        updateSpot(spot['id'], value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada Spot QR.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}