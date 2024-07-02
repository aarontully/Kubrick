import 'dart:convert';

import 'package:kubrick/models/transcription_class.dart';
import 'package:http/http.dart' as http;

class TranscriptionApiService {
  final String baseUrl = 'https://transcription.staging.endemolshine.com.au/api/v1';
  final String token = '3de210c9-5f7d-45bd-803d-67edcc6fcfe7';

  Future<Data> fetchTranscription(String fileId, int chunks, int size, String name) async {
    final url = Uri.parse('$baseUrl/files/$fileId/transcriptions');
    final response = await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      }
    );

    if(response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return Data.fromJson(responseBody['data']);
    } else {
      throw Exception('Failed to transcribe audio');
    }
  }
}