import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kubrick/models/transcription_class.dart';

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
    final url = Uri.parse('$baseUrl/files/upload');
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
    if(responseBody['data'] != null && responseBody['data']['file'] != null) {
      return responseBody['data']['file']['id'];
    } else {
      throw Exception('Failed to init upload');
    }
  }

  Future<void> uploadChunk(String fileId, int chunk, int size, List<int> file, {int maxRetries = 3}) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = Uri.parse('$baseUrl/files/$fileId');
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
        // If the upload was successful, break out of the loop
        break;
      } catch (e) {
        // TODO: inform the user that connection was unsuccessful and retry later
      }
    }
  }

  Future<void> completeUpload(String fileId) async {
    final url = Uri.parse('$baseUrl/files/$fileId/complete');
    await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Data> fetchTranscription(String fileId, int chunks, int size, String name) async {
    final url = Uri.parse('$baseUrl/files/$fileId/transcriptions');
    final response = await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'chunks': chunks,
        'size': size,
        'name': name,
      }),
    );
    print(response.body);
    print(response.statusCode);
    if(response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return Data.fromJson(responseBody['data']);
    } else {
      throw Exception('Failed to transcribe audio');
    }
  }
}