import 'package:flutter/material.dart';

class ConversationTab extends StatelessWidget {
  final List transcription;

  const ConversationTab({super.key, required this.transcription});

  @override
  Widget build(BuildContext context) {
    String? currentSpeaker;
    return SingleChildScrollView(
      child: Column(
        children: transcription.expand<Widget>((paragraph) {
          var speaker = paragraph['speaker'].toString();
          var sentences = paragraph['sentences'];
          List<Widget> widgets = [];
          if(speaker != currentSpeaker) {
            widgets.add(ListTile(
              title: Text(
                'Speaker $speaker',
                style: const TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
            ));
            currentSpeaker = speaker;
          }
          widgets.addAll(sentences.map<Widget>((sentence) {
            var text = sentence['text'];
            return ListTile(
              subtitle: Text(text),
            );
          }).toList());
          return widgets;
        }).toList(),
      ),
    );
  }
}