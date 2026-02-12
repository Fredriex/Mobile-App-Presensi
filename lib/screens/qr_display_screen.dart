import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart'; // <--- Library Baru
import 'package:google_fonts/google_fonts.dart';

class QrDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> scheduleItem;

  const QrDisplayScreen({super.key, required this.scheduleItem});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  // Pastikan URL ini benar
  final String baseUrl = "https://presensimusik.infinityfreeapp.com/attendance/scan";

  Future<void> _saveQrCode() async {
    setState(() => _isSaving = true);

    try {
      // 1. Cek Izin Akses (Library Gal menangani ini otomatis, tapi kita cek dulu)
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Tangkap Gambar dari Layar
      final Uint8List? image = await _screenshotController.capture();

      if (image != null) {
        // 3. Simpan ke Galeri menggunakan GAL
        // name: opsional, album: opsional
        await Gal.putImageBytes(image, name: "QR_${widget.scheduleItem['name']}");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Berhasil Disimpan di Galeri!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle jika user menolak izin
        if (e.toString().contains("access")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Izinkan akses foto untuk menyimpan QR")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan: $e")),
          );
        }
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrData = "$baseUrl/${widget.scheduleItem['id']}";
    final String scheduleName = widget.scheduleItem['name'] ?? 'Jadwal';
    final String date = widget.scheduleItem['date'] ?? '-';
    final String time = "${widget.scheduleItem['service_start_time']} - ${widget.scheduleItem['end_time']}";

    return Scaffold(
      appBar: AppBar(
        title: Text("QR Code Jadwal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AREA YANG AKAN DI-SCREENSHOT
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white, // Wajib Putih
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 15, spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SCAN SAYA",
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 4),
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(scheduleName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(date, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      Text(time, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQrCode,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_alt),
                  label: Text(_isSaving ? "Menyimpan..." : "Simpan ke Galeri"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Otomatis masuk ke Album Foto", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}