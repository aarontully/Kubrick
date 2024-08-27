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
      title: const Text('Kubrick Transcriber', overflow: TextOverflow.clip,),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            var controller = Get.find<RecordingsController>();
            switch (value) {
              case 'A-Z/1-9':
                controller.recordings.sort((a, b) => a.name.value.compareTo(b.name.value));
                break;
              case 'Z-A/9-1':
                controller.recordings.sort((a, b) => b.name.value.compareTo(a.name.value));
                break;
              case 'Newest-Oldest':
                controller.recordings.sort((a, b) => b.createdAt.value.compareTo(a.createdAt.value));
                break;
              case 'Oldest-Newest':
                controller.recordings.sort((a, b) => a.createdAt.value.compareTo(b.createdAt.value));
                break;
              case 'Contestants A-Z':
                controller.recordings.sort((a, b) => a.metadata.value.contestant.compareTo(b.metadata.value.contestant));
                break;
              case 'Contestants Z-A':
                controller.recordings.sort((a, b) => b.metadata.value.contestant.compareTo(a.metadata.value.contestant));
                break;
              case 'Producers A-Z':
                controller.recordings.sort((a, b) => a.metadata.value.producer.compareTo(b.metadata.value.producer));
                break;
              case 'Producers Z-A':
                controller.recordings.sort((a, b) => b.metadata.value.producer.compareTo(a.metadata.value.producer));
                break;
              case 'Shoot Day A-Z':
                controller.recordings.sort((a, b) => a.metadata.value.shoot_day.compareTo(b.metadata.value.shoot_day));
                break;
              case 'Shoot Day Z-A':
                controller.recordings.sort((a, b) => b.metadata.value.shoot_day.compareTo(a.metadata.value.shoot_day));
                break;
              case 'Interview Day A-Z':
                controller.recordings.sort((a, b) => a.metadata.value.interview_day.compareTo(b.metadata.value.interview_day));
                break;
              case 'Interview Day Z-A':
                controller.recordings.sort((a, b) => b.metadata.value.interview_day.compareTo(a.metadata.value.interview_day));
                break;
            }
            controller.update();
          },
          itemBuilder: (BuildContext context) {
            return ['A-Z/1-9', 'Z-A/9-1', 'Newest-Oldest', 'Oldest-Newest', 'Contestants A-Z', 'Contestants Z-A', 'Producers A-Z', 'Producers Z-A', 'Shoot Day A-Z', 'Shoot Day Z-A', 'Interview Day A-Z', 'Interview Day Z-A'].map((String choice) {
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