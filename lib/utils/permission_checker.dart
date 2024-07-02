import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  static Future<void> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage
      ].request();

      if (statuses[Permission.microphone]!.isDenied ||
          statuses[Permission.storage]!.isDenied) {
        throw Exception('Permissions not granted');
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      rethrow;
    }
  }
}
