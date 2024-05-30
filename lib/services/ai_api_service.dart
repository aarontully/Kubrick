import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String token = '3de210c9-5f7d-45bd-803d-67edcc6fcfe7';

  ApiService({required this.baseUrl});

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
}