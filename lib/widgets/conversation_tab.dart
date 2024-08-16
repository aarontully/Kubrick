import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kubrick/controllers/recording_controller.dart';
import 'package:kubrick/models/recording_class.dart';
import 'package:kubrick/services/database_helper.dart';
import 'package:kubrick/services/transcription_api_service.dart';

class ConversationTab extends StatefulWidget {
  final List transcription;
  final Recording recording;

  const ConversationTab({super.key, required this.transcription, required this.recording});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
  RecordingsController recordingsController = RecordingsController();
  Map<String, dynamic>? transcription;
  Map<String, dynamic>? metadata;
  List<dynamic>? speakers;

  @override
  void initState() {
    super.initState();

    transcription = widget.recording.transcription!;
    metadata = transcription!['data']['transcription']['result']['metadata'];

    if (metadata != null && widget.recording.speakers.isEmpty) {
      speakers = metadata!['speakers'];
    } else if (widget.recording.speakers.isNotEmpty) {
      speakers = widget.recording.speakers;
    } else {
      print('Speakers or metadata not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          SelectionArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.transcription.expand<Widget>((paragraph) {
                int paragraphSpeaker = paragraph['speaker'];
                var sentences = paragraph['sentences'];
                double paragraphStartTime = paragraph['start']; //2.1599998
                final createdTime = metadata!['created']; //"2024-08-16T02:13:25.471Z"
                int paragraphStartTimeMs = (paragraphStartTime * 1000).toInt();
                DateTime createdDateTime = DateTime.parse(createdTime);
                createdDateTime = createdDateTime.toLocal();
                DateTime newDateTime = createdDateTime.add(Duration(milliseconds: paragraphStartTimeMs));
                String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime);
                List<Widget> widgets = [];

                String speakerName = 'Unknown';
                int speakerNumber = -1;
                for (var speaker in speakers!) {
                  if (speaker['number'] == paragraphSpeaker) {
                    speakerName = speaker['name'];
                    speakerNumber = speaker['number'];
                    break;
                  }
                }

                widgets.add(
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final textController = TextEditingController();
                          textController.text = speakerName;
                          textController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: speakerName.length,
                          );
                          final editedSpeaker = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Edit Speaker'),
                              content: TextField(
                                controller: textController,
                                autofocus: true,
                                onChanged: (value) {
                                  setState(() {
                                    speakerName = value;
                                  });
                                }
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(speakerName),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (editedSpeaker != null && editedSpeaker.isNotEmpty) {
                            try {
                              final List<dynamic> updatedSpeakers = List.from(speakers!);
                              for (var i = 0; i < updatedSpeakers.length; i++) {
                                if (updatedSpeakers[i]['number'] == paragraphSpeaker) {
                                  updatedSpeakers[i]['name'] = editedSpeaker;
                                  break;
                                }
                              }

                              final success = await TranscriptionApiService().updateSpeakerName(
                                widget.recording.uploadId!,
                                widget.recording.transcriptionId!,
                                speakerName,
                                speakerNumber,
                              );

                              if(success) {
                                speakers = updatedSpeakers;
                                widget.recording.speakers = updatedSpeakers;
                                await DatabaseHelper.updateRecording(widget.recording);
                                setState(() {
                                  speakerName = editedSpeaker;
                                });
                              }
                            } catch (e) {
                              print(e);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 4.0),
                          child: Row(
                            children: [
                              Text(
                                formattedTime,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                ' - ',
                              ),
                              Text(
                                speakerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                    child: Text(
                      sentences.map((sentence) => sentence['text']).join(' '),
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  )
                );
                return widgets;
                }).toList(),
              ),
            )
          ),
        ],
      ),
    );
  }
}