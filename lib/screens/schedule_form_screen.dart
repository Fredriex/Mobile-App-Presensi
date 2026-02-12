import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'login_webview.dart';

class ScheduleFormScreen extends StatefulWidget {
  // Jika item null = Tambah Baru, Jika ada = Edit
  final Map<String, dynamic>? item;

  const ScheduleFormScreen({super.key, this.item});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;

  // Time Variables
  TimeOfDay? _lateLimitTime;
  TimeOfDay? _briefingTime;
  TimeOfDay? _serviceStartTime;
  TimeOfDay? _endTime;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?['name'] ?? '');
    _isActive = widget.item?['is_active'] == 1 || widget.item?['is_active'] == true;

    if (widget.item != null) {
      _lateLimitTime = _parseTime(widget.item!['late_limit_time']);
      _briefingTime = _parseTime(widget.item!['briefing_time']);
      _serviceStartTime = _parseTime(widget.item!['service_start_time']);
      _endTime = _parseTime(widget.item!['end_time']);
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TimeOfDay? initial, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo),
            timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi Manual Waktu
    if (_lateLimitTime == null || _briefingTime == null || _serviceStartTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mohon lengkapi semua data waktu!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'late_limit_time': _formatTime(_lateLimitTime),
      'briefing_time': _formatTime(_briefingTime),
      'service_start_time': _formatTime(_serviceStartTime),
      'end_time': _formatTime(_endTime),
      'is_active': _isActive,
    };

    try {
      bool success;
      if (widget.item == null) {
        success = await _api.createSchedule(data);
      } else {
        success = await _api.updateSchedule(widget.item!['id'], data);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null ? "Jadwal Berhasil Dibuat" : "Jadwal Berhasil Diupdate"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleError(Object e) async {
    if (e.toString().contains("BLOCK_BY_INFINITYFREE")) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memperbarui Koneksi...")));
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginWebview()));
        _submit();
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEditing ? "Edit Jadwal" : "Buat Jadwal Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: INFORMASI UMUM
              Text("Informasi Umum", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Nama Kegiatan / Ibadah",
                        labelStyle: GoogleFonts.poppins(fontSize: 14),
                        hintText: "Contoh: Ibadah Raya 1",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.event_note_rounded),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (val) => val!.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 2: PENGATURAN WAKTU
              Text("Pengaturan Waktu", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildTimeCard(
                      title: "Batas Wajib Hadir",
                      subtitle: "Lewat jam ini dianggap TELAT",
                      color: Colors.redAccent,
                      icon: Icons.timer_off_outlined,
                      time: _lateLimitTime,
                      onTap: () => _selectTime(_lateLimitTime, (t) => _lateLimitTime = t),
                    ),
                    const Divider(height: 24),
                    _buildTimeCard(
                      title: "Mulai Briefing",
                      subtitle: "Waktu briefing tim dimulai",
                      color: Colors.orangeAccent,
                      icon: Icons.mic_none_rounded,
                      time: _briefingTime,
                      onTap: () => _selectTime(_briefingTime, (t) => _briefingTime = t),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactTimeCard(
                            title: "Mulai Ibadah",
                            color: Colors.green,
                            time: _serviceStartTime,
                            onTap: () => _selectTime(_serviceStartTime, (t) => _serviceStartTime = t),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactTimeCard(
                            title: "Selesai",
                            color: Colors.blueGrey,
                            time: _endTime,
                            onTap: () => _selectTime(_endTime, (t) => _endTime = t),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 3: STATUS AKTIF
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  border: Border.all(color: _isActive ? Colors.green.withOpacity(0.5) : Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: Text("Status Jadwal", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _isActive ? "Jadwal Aktif (Bisa Scan QR)" : "Jadwal Tidak Aktif",
                    style: GoogleFonts.poppins(fontSize: 12, color: _isActive ? Colors.green : Colors.grey),
                  ),
                  value: _isActive,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _isActive = val),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                      color: _isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing ? "Update Perubahan" : "Simpan Jadwal Baru",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TIME CARD BESAR ---
  Widget _buildTimeCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: time == null ? Colors.red.withOpacity(0.3) : Colors.transparent),
              ),
              child: Text(
                time?.format(context) ?? "--:--",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: time == null ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TIME CARD KECIL (COMPACT) ---
  Widget _buildCompactTimeCard({
    required String title,
    required Color color,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 14, color: color),
                const SizedBox(width: 6),
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                time?.format(context) ?? "--:--",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: time == null ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}