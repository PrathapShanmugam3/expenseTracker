import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  static const MethodChannel _channel = MethodChannel('com.example.mobile/call');
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  /// Request all necessary permissions
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.phone,
      Permission.microphone,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Make a direct call (uses native Android ACTION_CALL)
  Future<bool> makeDirectCall(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod('makeCall', {'phoneNumber': phoneNumber});
      return result == true;
    } on PlatformException catch (e) {
      debugPrint("Error making call: ${e.message}");
      return false;
    }
  }

  /// Make a call and start recording
  Future<String?> makeCallWithRecording(String phoneNumber, String customerName) async {
    // Check permissions first
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      debugPrint("Permissions not granted");
      return null;
    }

    // Start recording
    await _startRecording(customerName);

    // Make the direct call using native code
    await makeDirectCall(phoneNumber);

    // Note: Recording will be stopped manually by user
    return _currentRecordingPath;
  }

  Future<void> _startRecording(String customerName) async {
    if (_isRecording) return;

    try {
      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'call_${customerName.replaceAll(' ', '_')}_$timestamp.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      // Check if can record
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _currentRecordingPath!,
        );
        _isRecording = true;
        debugPrint("Recording started: $_currentRecordingPath");
      } else {
        debugPrint("No recording permission");
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      debugPrint("Recording stopped: $path");
      return path;
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      return null;
    }
  }

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  void dispose() {
    _audioRecorder.dispose();
  }
}
