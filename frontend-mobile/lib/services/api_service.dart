/// SENTINEL API Service — REST + WebSocket
/// Canon: idea.md §8.1, Flutter_Agent.md §6

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import '../models/models.dart';

class RunEvent {
  final String event;
  final Map<String, dynamic> data;
  final String timestamp;

  RunEvent({required this.event, required this.data, required this.timestamp});

  factory RunEvent.fromJson(Map<String, dynamic> json) => RunEvent(
        event: json['event'] ?? '',
        data: json['data'] ?? {},
        timestamp: json['timestamp'] ?? '',
      );
}

class ApiService {
  final String _baseUrl = AppConfig.apiBase;

  /// POST /api/v1/runs → start a new analysis run
  Future<Map<String, dynamic>> startRun({
    required String scenario,
    required List<Map<String, dynamic>> sources,
    required Map<String, dynamic> constraints,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/runs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'scenario': scenario,
        'sources': sources,
        'constraints': constraints,
      }),
    );

    if (response.statusCode == 202) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start run: ${response.statusCode} ${response.body}');
    }
  }

  /// GET /api/v1/runs/{run_id} → fetch completed report
  Future<RunReport> getRunReport(String runId) async {
    final response = await http.get(Uri.parse('$_baseUrl/runs/$runId'));
    if (response.statusCode == 200) {
      return RunReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Run not found: ${response.statusCode}');
    }
  }

  /// GET /api/v1/runs/{run_id}/trace → fetch full ADK trace JSON
  Future<Map<String, dynamic>> getAdkTrace(String runId) async {
    final response = await http.get(Uri.parse('$_baseUrl/runs/$runId/trace'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Trace not found: ${response.statusCode}');
    }
  }

  /// POST /api/v1/runs/{run_id}/approvals → submit approval decision
  Future<void> submitApproval(String runId, String approvalId, String decision, {String? modification}) async {
    await http.post(
      Uri.parse('$_baseUrl/runs/$runId/approvals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'approval_id': approvalId,
        'decision': decision,
        if (modification != null) 'modification': modification,
      }),
    );
  }

  /// WebSocket stream for live run events
  Stream<RunEvent> connectWebSocket(String runId) {
    final wsUrl = AppConfig.wsRunUrl(runId);
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    return channel.stream.map((message) {
      final json = jsonDecode(message as String);
      return RunEvent.fromJson(json);
    });
  }
}
