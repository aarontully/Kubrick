import 'package:flutter/material.dart';

class ConversationTab extends StatelessWidget {
  final List transcription;

  const ConversationTab({super.key, required this.transcription});

  @override
  Widget build(BuildContext context) {
    String? currentSpeaker;
    return SingleChildScrollView(
      child: Stack(
        children: [
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
              children: transcription.expand<Widget>((paragraph) {
                var speaker = paragraph['speaker'].toString();
                var sentences = paragraph['sentences'];
                List<Widget> widgets = [];

                  if (currentSpeaker != speaker) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Speaker: $speaker',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    );
                  }
                  currentSpeaker = speaker;
                  widgets.add(
                    Text(
                      sentences.map((sentence) => sentence['text']).join(' '),
                    ),
                  );
                  return widgets;
                }).toList(),
              ),
            )
          ),
            /*child: const Positioned(
            top: 12.0,
            right: 12.0,
            child: Icon(
              Icons.copy,
            ),*/
        ],
      )
    );
  }
}