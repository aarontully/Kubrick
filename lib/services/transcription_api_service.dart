import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/auth_service.dart';
import 'package:kubrick/services/database_helper.dart';

class TranscriptionApiService {
  final String baseUrl = 'https://transcription.staging.endemolshine.com.au/api/v1';
  AuthService authService = AuthService();

  Future<String> postTranscription(String uploadId) async {
    final url = Uri.parse('$baseUrl/files/$uploadId/transcriptions');
    final session = await authService.getToken();
    final token = session['auth_token'];
    final response = await http.post(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to post transcription');
    }

    final responseBody = jsonDecode(response.body);
    final transcriptionId = responseBody['data']['transcription']['id'];

    return transcriptionId;
  }

  Future<Map<String, dynamic>> pollTranscription(
      String uploadId, String transcriptionId) async {
        final session = await authService.getToken();
    final token = session['auth_token'];
    final url =
        Uri.parse('$baseUrl/files/$uploadId/transcriptions/$transcriptionId');
    final completer = Completer<Map<String, dynamic>>();

    Timer.periodic(const Duration(seconds: 15), (timer) async {
      final response = await http.get(url, headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode != 200) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError('Failed to poll transcription');
        }
      }

      final responseBody = jsonDecode(response.body);
      final transcriptionStatus =
          responseBody['data']['transcription']['status'];

      if (transcriptionStatus == 'complete') {
        timer.cancel();
        print('We made it!');
        if (!completer.isCompleted) {
          completer.complete(responseBody);
        }
      } else {
        if (responseBody['data']['transcription']['status'] == 'error') {
          timer.cancel();
          if (!completer.isCompleted) {
            completer
                .completeError(responseBody['data']['transcription']['error']);
          }
        }
        print('Transcription not completed...retrying in 15 seconds');
      }
    });

    return completer.future;
  }

  Future downloadTranscription(String uploadId, String transcriptionId) async {
    final url = Uri.parse('$baseUrl/files/$uploadId/transcriptions/$transcriptionId/download');
    final session = await authService.getToken();
    final token = session['auth_token'];

    final response = await http.get(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to download transcription');
    }

    return response.body;
  }

  Future<bool> updateSpeakerName(String uploadId, String transcriptionId, String speakerName, int speakerNumber) async {
    final url = Uri.parse('$baseUrl/files/$uploadId/transcriptions/$transcriptionId/speaker');
    final session = await authService.getToken();
    final token = session['auth_token'];

    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': speakerName,
        'number': speakerNumber,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update speaker name');
    }

    return true;
  }

  Future getAllTranscriptions(Recording recording) async {
    final url = Uri.parse('$baseUrl/files/${recording.uploadId}/transcriptions');
    final session = await authService.getToken();
    final token = session['auth_token'];

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      }
    );

    if (response.statusCode == 200) {
      print(response.body);
      final responseBody = jsonDecode(response.body);
      final transcriptionList = responseBody['data']['transcriptions'];
      for (final transcription in transcriptionList) {
        final recordingTranscript = await getTranscription(recording.uploadId!, transcription['id']);
        recording.transcription = recordingTranscript;
        await DatabaseHelper.updateRecording(recording);
      }
    }
  }

  Future getTranscription(String fileId, String transcriptionId) async {
    final url = Uri.parse('$baseUrl/files/$fileId/transcriptions/$transcriptionId');
    final session = await authService.getToken();
    final token = session['auth_token'];

    final response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      }
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody;
    }
  }
}