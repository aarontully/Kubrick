import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kubrick/controllers/metadata_controller.dart';
import 'package:kubrick/models/metadata_class.dart';

Widget buildMetadataDialog(BuildContext context) {
  final dialogMetadata = Metadata();
  final formKey = GlobalKey<FormState>();
  final MetadataController metadataController = Get.put(MetadataController());

  return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(
          displayLarge:
              const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.oswald(
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
          bodyMedium: GoogleFonts.merriweather(),
          displaySmall: GoogleFonts.pacifico(),
        ),
      ),
      child: SingleChildScrollView(
        child: AlertDialog(
          title: const Text('Enter Recording Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: metadataController.shootday.value,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Shoot Day'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dialogMetadata.shoot_day = value!.toUpperCase();
                  },
                ),
                TextFormField(
                  initialValue: metadataController.interviewDay.value,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Interview Day'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dialogMetadata.interview_day = value!.toUpperCase();
                  },
                ),
                DropdownButtonFormField<String>(
                  value: metadataController.contestant.value,
                  decoration: const InputDecoration(labelText: 'Contestant'),
                  hint: const Text('Select a contestant'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a value';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dialogMetadata.contestant = value!.toUpperCase();
                  },
                  onChanged: (value) {
                    dialogMetadata.contestant = value as String;
                  },
                  isExpanded: true,
                  items: metadataController.contestants.map((String sdValue) {
                    return DropdownMenuItem<String>(
                      value: sdValue,
                      child: Text(sdValue),
                    );
                  }).toList(),
                ),
                TextFormField(
                  initialValue: metadataController.camera.value,
                  decoration: const InputDecoration(labelText: 'Camera'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dialogMetadata.camera = value!.toUpperCase();
                  },
                ),
                TextFormField(
                  initialValue: metadataController.audio.value,
                  decoration: const InputDecoration(labelText: 'Audio'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dialogMetadata.audio = value!.toUpperCase();
                  },
                ),
                DropdownButtonFormField<String>(
                  value: metadataController.producer.value,
                  decoration: const InputDecoration(labelText: 'Producer'),
                  hint: const Text('Select a producer'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a value';
                    }
                    return null;
                  },
                  onSaved: (value) => {
                    dialogMetadata.producer = value!.toUpperCase(),
                  },
                  onChanged: (value) {
                    dialogMetadata.producer = value as String;
                  },
                  isExpanded: true,
                  items: metadataController.producers.map((String prodValue) {
                    return DropdownMenuItem<String>(
                      value: prodValue,
                      child: Text(prodValue),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: () async {
                    var now = DateTime.now();

                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      dialogMetadata.timecode = now;

                      //set the metadata
                      metadataController.setMetadata(dialogMetadata);

                      Navigator.of(context).pop(dialogMetadata);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green[700],
                  ),
                  child: const Text('Start Record'),
                ),
              ],
            )
          ],
        ),
      ),
    );
}