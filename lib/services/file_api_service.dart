import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kubrick/controllers/shared_state.dart';
import 'package:kubrick/models/metadata_class.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileApiService {
  final String baseUrl = 'https://transcription.staging.endemolshine.com.au/api/v1';
  final SharedState sharedState = Get.find<SharedState>();

  Future<String?> fetchToken() async {
    var session = await AuthService().getToken();
    return session['auth_token'];
  }

  // GET: files
  Future<List<dynamic>> getRemoteFiles() async {
    final token = await fetchToken();
    final url = Uri.parse('$baseUrl/files');

    String userId = await AuthService().getUserId();
    final queryParams = {
      'filter[uploader_id]': userId,
    };

    final uri = url.replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if(response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      return responseBody['data']['files'];
    } else {
      return [];
    }
  }

  // POST: /files/upload
  Future<String> initUpload(int chunks, String name, int size, Recording recording) async {
    final token = await fetchToken();
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
        'metadata': recording.metadata.value.toMap(),
      }),
    );

    final responseBody = jsonDecode(response.body);
  if (response.statusCode == 200) {
      if(responseBody['data'] != null && responseBody['data']['file'] != null) {
        return responseBody['data']['file']['id'];
      } else {
        throw Exception('Failed to initialise: ${responseBody['error']} - ${responseBody['message']}');
      }
    } else {
      throw Exception('Failed to initialise: ${responseBody['message']}');
    }
  }

  // GET: /files/{file_id}
  Future<Recording> getFileInfo(String fileId) async {
    final token = await fetchToken();
    final url = Uri.parse('$baseUrl/files/$fileId');
    final response = await http.get(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if(response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final String path;
      final String fileName;
      Metadata? metadata;

      if (responseBody['data']['file']['metadata'] == null) {
        Directory directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/${responseBody['data']['file']['name']}';
        fileName = p.basename(path);
      } else {
        metadata = Metadata.fromMap(responseBody['data']['file']['metadata']);

        String hours = metadata.timecode.hour.toString().padLeft(2, '0');
        String minutes = metadata.timecode.minute.toString().padLeft(2, '0');
        Directory directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/${metadata.shoot_day}_${metadata.interview_day}_${metadata.contestant}_${metadata.camera}_${metadata.audio}_${hours}_${minutes}_${metadata.producer}.m4a';
        fileName = p.basename(path);
      }

      Recording newRecording = Recording(
        path: path, // this should be the path
        createdAt: DateTime.parse(responseBody['data']['file']['created_at']),
        name: fileName, // this should be the metadata name
        //status: 'Not Uploaded',
        uploadId: responseBody['data']['file']['id'],
        //transcriptionId: null,
        //transcription: null,
        metadata: metadata,
        //speakers: [],
        user_id: responseBody['data']['file']['uploader_id'],
      );
      return newRecording;
    } else {
      throw Exception('Failed to get file info');
    }
  }

  // POST: /files/{file_id}
  Future<void> uploadChunk(String fileId, int chunk, int size, Uint8List file, {int maxRetries = 3}) async {
    final token = await fetchToken();
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = Uri.parse('$baseUrl/files/$fileId');

        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          file,
          filename: '$fileId-chunk-$chunk',
          contentType: MediaType('application', 'octet-stream'),
        );

        var request = http.MultipartRequest('POST', url)
          ..fields['chunk'] = chunk.toString()
          ..fields['size'] = size.toString()
          ..files.add(multipartFile);

          request.headers.addAll(<String, String>{
            'Authorization': 'Bearer $token',
          });

          var streamedResponse = await request.send();

          var response = await http.Response.fromStream(streamedResponse);

          if(response.statusCode == 200) {
            //upload was successful and can break out of the loop
            break;
          } else {
            throw Exception('Failed to upload chunk');
          }
      } catch (e) {
        // TODO: inform the user that connection was unsuccessful and retry later
        print(e);
      }
    }
  }

  // DELETE: /files/{file_id}
  Future<void> deleteFile(String fileId) async {
    final token = await fetchToken();
    final url = Uri.parse('$baseUrl/files/$fileId');
    final response = await http.delete(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if(response.statusCode != 200) {
      print('Status code: ${response.statusCode}. Response: ${response.body}');
    } else {
      print('Remote file deleted: $fileId');
    }
  }

  // POST: /files/{file_id}/complete
  Future<void> completeUpload(String fileId) async {
    final token = await fetchToken();
    final url = Uri.parse('$baseUrl/files/$fileId/complete');
    await http.post(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // GET: /files/{file_id}/download
  Future<String> downloadFile(Recording recording) async {
    final token = await fetchToken();
    final url = Uri.parse('$baseUrl/files/${recording.uploadId}/download');

    final response = await http.get(
      url,
      headers: <String, String> {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if(response.statusCode == 200) {
      final metadata = recording.metadata.value;
      String hours = metadata.timecode.hour.toString().padLeft(2, '0');
      String minutes = metadata.timecode.minute.toString().padLeft(2, '0');

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${metadata.shoot_day}_${metadata.interview_day}_${metadata.contestant}_${metadata.camera}_${metadata.audio}_${hours}_${minutes}_${metadata.producer}.m4a';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw Exception('Failed to download file}');
    }
  }
}