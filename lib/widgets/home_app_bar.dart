import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Kubrick Transcriber'),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Add filter logic here
          })
      ],
    );
  }
}