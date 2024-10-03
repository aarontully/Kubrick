import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  Map<Permission, PermissionStatus> statuses = {};

  Future<void> requestPermissions(BuildContext context) async {
    try {
      statuses = await [
        Permission.microphone,
        //Permission.storage,
      ].request();

      if (statuses[Permission.microphone]!.isDenied) {
        throw PermissionAccessDeniedError();
      }
    } on PermissionAccessDeniedError catch (e) {
      print('Permissions error: $e');
      final deniedPermissions = statuses.entries.where((entry) => entry.value == PermissionStatus.denied);
      String deniedPermissionString = deniedPermissions.map((entry) => entry.key.toString()).join(', ');

      String message = 'Please enable the following permissions: $deniedPermissionString. ';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                requestPermissions(context);
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('App Settings'),
            )
          ],
        ),
      );
    } catch (e) {
      print('Unknown error: $e');
    }
  }
}

class PermissionAccessDeniedError implements Exception {}