import 'dart:async';
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

  Future<String> postTranscription(String uploadId) async {
    final url = Uri.parse('$baseUrl/files/$uploadId/transcriptions');
    final response = await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      }
    );

    if(response.statusCode != 200) {
      throw Exception('Failed to post transcription');
    }

    final responseBody = jsonDecode(response.body);
    final transcriptionId = responseBody['data']['transcription']['id'];

    return transcriptionId;
  }

  Future<Map<String, dynamic>> pollTranscription(String uploadId, String transcriptionId) async {
    final url = Uri.parse('$baseUrl/files/$uploadId/transcriptions/$transcriptionId');
    final completer = Completer<Map<String, dynamic>>();

    Timer.periodic(const Duration(seconds: 15), (timer) async {
      final response = await http.get(
        url,
        headers: <String, String> {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        }
      );

      if(response.statusCode != 200) {
        timer.cancel();
        if(!completer.isCompleted) {
          completer.completeError('Failed to poll transcription');
        }
      }

      final responseBody = jsonDecode(response.body);
      final transcriptionStatus = responseBody['data']['transcription']['status'];

      if(transcriptionStatus == 'complete') {
        timer.cancel();
        print('We made it!');
        if(!completer.isCompleted) {
          completer.complete(responseBody);
        }
      } else {
        if (responseBody['data']['transcription']['status'] == 'error') {
          timer.cancel();
          if(!completer.isCompleted) {
            completer.completeError(responseBody['data']['transcription']['error']);
          }
        }
        print('Transcription not completed...retrying in 15 seconds');
      }
    });

    return completer.future;
  }
}