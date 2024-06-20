import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kubrick/controllers/recording_controller.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Kubrick Transcriber'),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            var controller = Get.find<RecordingsController>();
            switch (value) {
              case 'A-Z':
                controller.recordings.sort((a, b) => a.name.value.compareTo(b.name.value));
                break;
              case 'Z-A':
                controller.recordings.sort((a, b) => b.name.value.compareTo(a.name.value));
                break;
              case 'Newest-Oldest':
                controller.recordings.sort((a, b) => b.createdAt.value.compareTo(a.createdAt.value));
                break;
              case 'Oldest-Newest':
                controller.recordings.sort((a, b) => a.createdAt.value.compareTo(b.createdAt.value));
                break;
            }
            controller.update();
          },
          itemBuilder: (BuildContext context) {
            return ['A-Z', 'Z-A', 'Newest-Oldest', 'Oldest-Newest'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        )
      ],
    );
  }
}