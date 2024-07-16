import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileApiService {
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

  // GET: files
  // TODO: get files from the server and add files that arent already on the local device as an option to download

  // POST: /files/upload
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

  // GET: /files/{file_id}

  // POST: /files/{file_id}
  Future<void> uploadChunk(String fileId, int chunk, int size, Uint8List file, {int maxRetries = 3}) async {
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
    print('Deleting file $fileId');
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
      throw Exception('Failed to delete file');
    }
  }

  // POST: /files/{file_id}/complete
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
}