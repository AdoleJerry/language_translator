import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

Future<void> startRecording(
    FlutterSoundRecorder recorder, Function(bool) setRecordingState) async {
  final micStatus = await Permission.microphone.status;

  if (!micStatus.isGranted) {
    throw RecordingPermissionException(
        'Permissions not granted. Please enable microphone permissions.');
  }

  final directory = await getTemporaryDirectory();
  final recordedFilePath = '${directory.path}/audio.aac';

  await recorder.startRecorder(
    toFile: recordedFilePath,
    codec: Codec.aacADTS,
    sampleRate: 16000,
    numChannels: 1,
  );

  setRecordingState(true);
}

Future<void> stopRecording(
    FlutterSoundRecorder recorder, Function(bool) setRecordingState) async {
  await recorder.stopRecorder();
  setRecordingState(false);
}

Future<void> importAudio(Function(String?) setFilePath) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
  );

  if (result != null && result.files.single.path != null) {
    setFilePath(result.files.single.path);
  } else {
    throw Exception("No audio file selected.");
  }
}

Future<String> uploadAudioToStorage(String filePath) async {
  try {
    final storageRef = FirebaseStorage.instance.ref();
    final audioRef =
        storageRef.child('audio_files/${DateTime.now().millisecondsSinceEpoch}.aac');

    // Upload the audio file
    await audioRef.putFile(File(filePath));

    // Get the download URL after the file is uploaded
    return await audioRef.getDownloadURL();
  } catch (e) {
    throw Exception("Error uploading audio to Firebase Storage: $e");
  }
}

Future<void> uploadToFirestore(String transcription, String translation,
    String audioUrl, String userUid) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Create a document in the "audio_translations" collection
    await firestore
        .collection('audio_translations')
        .doc(userUid)
        .collection('messages')
        .add({
      'transcription': transcription,
      'translation': translation,
      'audioUrl': audioUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw Exception("Error sending message: $e");
  }
}

Future<void> deleteAudioTranslations(String documentId, String userUid) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Delete the Firestore document
    await firestore
        .collection('audio_translations')
        .doc(userUid)
        .collection('messages')
        .doc(documentId)
        .delete();

  } catch (e) {
    throw Exception("Error deleting text message: $e");
  }
}

Future<void> deleteTextTranslations(String documentId, String userUid) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Delete the Firestore document
    await firestore
        .collection('text_to_text')
        .doc(userUid)
        .collection('messages')
        .doc(documentId)
        .delete();

  } catch (e) {
    throw Exception("Error deleting text message: $e");
  }
}

/// Deletes only the audio file from Firebase Storage.
Future<void> deleteAudioMessage(String? audioUrl) async {
  try {
    if (audioUrl != null) {
      final storageRef = FirebaseStorage.instance.refFromURL(audioUrl);

      // Delete the audio file from Firebase Storage
      await storageRef.delete();

    } else {
      throw Exception("Audio URL is null. Cannot delete audio.");
    }
  } catch (e) {
    throw Exception("Error deleting audio file: $e");
  }
}
