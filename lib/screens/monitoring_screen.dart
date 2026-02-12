import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_webview.dart';

class MonitoringScreen extends StatefulWidget {
  final int scheduleId;

  const MonitoringScreen({super.key, required this.scheduleId});

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

      print("Monitoring Data: $result"); // DEBUG LIHAT JSON

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
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Live"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text("Gagal memuat data"))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    List attendees = _data?['data'] ?? [];
    itemBuilder: (context, index) {
      final item = attendees[index];
      print("Item: $item");
    };
    if (attendees.isEmpty) {
      return const Center(child: Text("Belum ada yang hadir."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final item = attendees[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: item['photo_url'] != null
                  ? NetworkImage(item['photo_url'])
                  : null,
              child: item['photo_url'] == null
                  ? Text(item['guest_name'][0])
                  : null,
            ),
            title: Text(
              item['guest_name'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${item['instrument']} • ${item['check_in_time']}",
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item['status'] == "Terlambat"
                    ? Colors.red[50]
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['status'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: item['status'] == "Terlambat"
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ),
          ),
        );
      },
    );

  }
}
