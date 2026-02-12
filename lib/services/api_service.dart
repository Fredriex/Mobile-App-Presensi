import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://presensimusik.infinityfreeapp.com/api";
  final String userAgentRahasia = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36";

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? cookie = prefs.getString('cookie_bypass');

    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Cookie": cookie ?? "",
      "User-Agent": userAgentRahasia
    };
    if (isJson) headers['Content-Type'] = 'application/json';
    return headers;
  }

  void _checkBlock(http.Response response) {
    if (response.body.contains("<html>") || response.body.contains("__test") || response.statusCode == 403) {
      throw Exception("BLOCK_BY_INFINITYFREE");
    }
  }

  // --- API DASHBOARD ---
  Future<Map<String, dynamic>> getDashboard() async {
    final headers = await _getHeaders(isJson: false);
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'), headers: headers);
      _checkBlock(response);
      return json.decode(response.body);
    } catch (e) { rethrow; }
  }

  // --- API CRUD JADWAL ---
  Future<List<dynamic>> getSchedules() async {
    final headers = await _getHeaders(isJson: false);
    try {
      final response = await http.get(Uri.parse('$baseUrl/schedules'), headers: headers);
      _checkBlock(response);
      final data = jsonDecode(response.body);
      return data['data'];
    } catch (e) { rethrow; }
  }

  Future<bool> createSchedule(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    try {
      final response = await http.post(Uri.parse('$baseUrl/schedules'), headers: headers, body: jsonEncode(data));
      _checkBlock(response);
      return response.statusCode == 200;
    } catch (e) { rethrow; }
  }

  Future<bool> updateSchedule(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    try {
      final response = await http.put(Uri.parse('$baseUrl/schedules/$id'), headers: headers, body: jsonEncode(data));
      _checkBlock(response);
      return response.statusCode == 200;
    } catch (e) { rethrow; }
  }

  Future<bool> deleteSchedule(int id) async {
    final headers = await _getHeaders(isJson: false);
    try {
      final response = await http.delete(Uri.parse('$baseUrl/schedules/$id'), headers: headers);
      _checkBlock(response);
      return response.statusCode == 200;
    } catch (e) { rethrow; }
  }

  // --- API MONITORING ---
  Future<Map<String, dynamic>> getMonitoring(int scheduleId) async {
    final headers = await _getHeaders(isJson: false);
    try {
      final response = await http.get(Uri.parse('$baseUrl/monitoring/$scheduleId'), headers: headers);
      _checkBlock(response);
      return json.decode(response.body);
    } catch (e) { rethrow; }
  }
  // ===============================
// QR SPOTS
// ===============================

  Future<List<dynamic>> getQrSpots() async {
    final headers = await _getHeaders(isJson: false);

    final response = await http.get(
      Uri.parse('$baseUrl/qr-spots'),
      headers: headers,
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    _checkBlock(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception("Failed load QR Spots");
    }
  }


  Future<bool> updateQrSpot(int id, int? scheduleId) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/qr-spots/$id'),
      headers: headers,
      body: jsonEncode({
        "current_schedule_id": scheduleId
      }),
    );

    _checkBlock(response);

    return response.statusCode == 200;
  }


}



