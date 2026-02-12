import 'dart:io';
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

  final String baseQrUrl = "https://presensimusik.infinityfreeapp.com/q/";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- CRUD FUNCTIONS ---

  Future<void> _handleLinkSchedule(int spotId, int? scheduleId) async {
    await api.updateQrSpot(spotId, scheduleId: scheduleId);
    loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Koneksi Jadwal Diperbarui"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteSpot(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Spot?"),
        content: const Text("Spot ini akan hilang permanen dan QR Code lama tidak akan berfungsi lagi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Hapus"),
          ),
        ],
      ),
    ) ??
        false;

    if (confirm) {
      await api.deleteQrSpot(id);
      loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spot Dihapus")));
      }
    }
  }

  // Form Dialog
  void _showFormDialog({Map<String, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final codeCtrl = TextEditingController(text: item?['unique_code'] ?? '');
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? "Edit Spot" : "Tambah Spot Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Nama Lokasi",
                hintText: "Contoh: Pintu Depan",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration: InputDecoration(
                labelText: "Kode Unik (ID)",
                hintText: "Contoh: DOOR_1",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.qr_code),
                helperText: "Kode ini akan menjadi isi QR Code",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
              Navigator.pop(ctx);

              bool success;
              if (isEdit) {
                success = await api.updateQrSpot(item['id'], name: nameCtrl.text, uniqueCode: codeCtrl.text, scheduleId: -999);
              } else {
                success = await api.createQrSpot(nameCtrl.text, codeCtrl.text);
              }

              if (success) {
                loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Data Diupdate" : "Spot Dibuat")));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  // --- QR FUNCTIONS ---

  Future<void> saveQr() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) await Permission.storage.request();

    final image = await screenshotController.capture();
    if (image == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = "QR_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File("${directory.path}/$fileName");
      await file.writeAsBytes(image);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Disimpan di: ${file.path}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal simpan gambar")));
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
              Text("MASTER QR CODE", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(spotName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: "$baseQrUrl$uniqueCode",
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Text(uniqueCode, style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: saveQr,
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text("Simpan ke Galeri"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Titik QR (Spots)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            Text("Kelola lokasi scan fisik", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.indigo,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: Text("Spot Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : spots.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final spot = spots[index];
          return _buildModernSpotCard(spot);
        },
      ),
    );
  }

  Widget _buildModernSpotCard(dynamic spot) {
    bool isLinked = spot['current_schedule_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // HEADER: Nama & Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Bulat Besar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isLinked ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_2, color: isLinked ? Colors.green : Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),

                // Info Utama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              spot['name'] ?? "Tanpa Nama",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          spot['unique_code'] ?? '-',
                          style: GoogleFonts.sourceCodePro(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu 3 Titik (Edit/Delete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') _showFormDialog(item: spot);
                    if (value == 'delete') _deleteSpot(spot['id']);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.blue), SizedBox(width: 12), Text('Edit Nama/Kode')]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Hapus Spot')]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CONTROL PANEL (Jadwal)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("JADWAL TERHUBUNG", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    // Badge Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLinked ? Colors.green : Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLinked ? "LIVE" : "IDLE",
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row: Dropdown + Tombol Lihat QR
                Row(
                  children: [
                    // Dropdown
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: spot['current_schedule_id'],
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            hint: Text("Pilih Jadwal...", style: GoogleFonts.poppins(fontSize: 13)),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(Icons.link_off, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text("Putus Koneksi (Idle)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              ...schedules.map<DropdownMenuItem<int?>>((s) {
                                return DropdownMenuItem<int?>(
                                  value: s['id'],
                                  child: Text(s['name'], overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13)),
                                );
                              }).toList(),
                            ],
                            onChanged: (val) => _handleLinkSchedule(spot['id'], val),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Tombol Lihat QR (Primary Action)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => showQrDialog(spot['unique_code'], spot['name']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.qr_code_2, size: 24),
                      ),
                    ),
                  ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]),
            child: Icon(Icons.add_location_alt_rounded, size: 60, color: Colors.indigo.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text("Belum ada Spot QR", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text("Tekan tombol + untuk membuat\ntitik scan baru (Contoh: Pintu Depan)", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}