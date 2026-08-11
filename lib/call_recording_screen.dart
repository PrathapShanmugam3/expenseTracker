import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // For baseUrl
import 'call_service.dart';

class CallRecordingScreen extends StatefulWidget {
  final String customerName;
  final String customerPhone;
  final int customerId;

  const CallRecordingScreen({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
  });

  @override
  State<CallRecordingScreen> createState() => _CallRecordingScreenState();
}

class _CallRecordingScreenState extends State<CallRecordingScreen> {
  final CallService _callService = CallService();
  bool _isCallInProgress = false;
  String? _recordingPath;
  String _status = "Ready to call";

  Future<void> _startCall() async {
    setState(() {
      _isCallInProgress = true;
      _status = "Calling ${widget.customerName}...";
    });

    final path = await _callService.makeCallWithRecording(
      widget.customerPhone,
      widget.customerName,
    );

    setState(() {
      _recordingPath = path;
      _status = "Recording in progress...";
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _status = "Stopping recording...";
    });

    final path = await _callService.stopRecording();
    
    setState(() {
      _isCallInProgress = false;
      _recordingPath = path;
      _status = path != null 
          ? "Recording saved!" 
          : "No recording available";
    });

    if (path != null) {
      _showRecordingOptions(path);
    }
  }

  void _showRecordingOptions(String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Call Recording Saved"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${widget.customerName}"),
            const SizedBox(height: 10),
            Text("File: ${path.split('/').last}"),
            const SizedBox(height: 20),
            const Text(
              "Note: To transcribe this audio, you need to integrate with OpenAI Whisper API.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, path); // Return path to previous screen
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Call & Record", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                child: Text(
                  widget.customerName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.customerName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.customerPhone,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _isCallInProgress ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCallInProgress ? Icons.fiber_manual_record : Icons.info_outline,
                      color: _isCallInProgress ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isCallInProgress ? Colors.red : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              if (!_isCallInProgress)
                ElevatedButton.icon(
                  onPressed: _startCall,
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text("Start Call & Record", style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text("Stop Recording", style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              const SizedBox(height: 30),
              const Text(
                "Recording will capture your microphone.\nOther party audio depends on your device.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
