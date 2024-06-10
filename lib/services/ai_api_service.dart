import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://transcription.staging.endemolshine.com.au/api/v1';
  final String token = '3de210c9-5f7d-45bd-803d-67edcc6fcfe7';

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<String> initUpload(int chunks, String name, int size) async {
    final url = Uri.parse('$baseUrl/files/uploads/init');
    final response = await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chunks': chunks,
        'name': name,
        'size': size,
      }),
    );
    final responseBody = jsonDecode(response.body);
    if(responseBody['data'] != null && responseBody['data']['upload'] != null) {
      return responseBody['data']['upload']['id'];
    } else {
      throw Exception('Failed to init upload');
    }
  }

  Future<void> uploadChunk(String uploadId, int chunk, int size, List<int> file) async {
    final url = Uri.parse('$baseUrl/files/uploads/$uploadId');
    await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/octet-stream',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chunk': chunk,
        'size': size,
        'file': base64Encode(file),
      }),
    );
  }

  Future<void> completeUpload(String uploadId) async {
    final url = Uri.parse('$baseUrl/files/uploads/$uploadId/complete');
    await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }
}