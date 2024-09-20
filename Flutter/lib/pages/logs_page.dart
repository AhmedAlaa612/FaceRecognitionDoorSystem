import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot/pages/Log_prev.dart';
import 'package:iot/pages/stream_page.dart';
import 'package:iot/services/mqtt_client_wrapper.dart';
import 'package:iot/services/notifi_service.dart';

class LogsPage extends StatefulWidget {
  final MQTTService mqttService;

  const LogsPage({Key? key, required this.mqttService}) : super(key: key);

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<LogMessage> _messages = [];
  String? _pendingName;
  Uint8List? _pendingImage;

  @override
  void initState() {
    super.initState();
    _subscribeToTopic("camera/logs");
    _setupMqttListener();
  }

  void _subscribeToTopic(String topic) {
    widget.mqttService.subscribe(topic);
  }

  void _setupMqttListener() {
    widget.mqttService.onMessageReceived = _handleTextMessage;
    widget.mqttService.onImageReceived = _handleImageMessage;
  }

  void _handleTextMessage(String topic, String message) {
    if (topic == 'notif') {
      print('Condition true');
      NotificationService().showNotification(
        title: 'Camera Notificaiton',
        body: '$message',
      );
      // Navigate to the StreamPages
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => StreamPage(mqttService: widget.mqttService),
      //   ),
      // );
    } else if (_pendingImage != null) {
      _addMergedMessage(message, _pendingImage!);
      _pendingImage = null;
    } else {
      _pendingName = message;
      _checkAndMergeMessages();
    }
  }

  void _handleImageMessage(Uint8List imageBytes) {
    if (_pendingName != null) {
      _addMergedMessage(_pendingName!, imageBytes);
      _pendingName = null;
    } else {
      _pendingImage = imageBytes;
      _checkAndMergeMessages();
    }
  }

  void _checkAndMergeMessages() {
    if (_pendingName != null && _pendingImage != null) {
      _addMergedMessage(_pendingName!, _pendingImage!);
      _pendingName = null;
      _pendingImage = null;
    }
  }

  void _addMergedMessage(String name, Uint8List imageBytes) {
    setState(() {
      _messages.insert(0, PersonLogMessage(name: name, image: imageBytes));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logs')),
      body: _messages.isEmpty
          ? Center(child: Text('No messages received yet.'))
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageTile(_messages[index]),
            ),
    );
  }

  Widget _buildMessageTile(LogMessage message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          color: Colors.grey,
          child: ListTile(
            title: Text(
              message.displayContent,
              style: TextStyle(fontSize: 20),
            ),
            trailing: Text(
              DateFormat('dd MMM hh:mm a').format(DateTime.now()),
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              if (message is PersonLogMessage) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePreviewPage(
                      content: message.image,
                      description: 'Image of: ${message.name}',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

abstract class LogMessage {
  String get displayContent;
}

class PersonLogMessage extends LogMessage {
  final String name;
  final Uint8List image;

  PersonLogMessage({required this.name, required this.image});

  @override
  String get displayContent => "$name ";
}
