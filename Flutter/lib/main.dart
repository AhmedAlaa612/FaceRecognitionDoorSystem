import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iot/pages/home_page.dart';
import 'package:iot/pages/login_page.dart';
import 'package:iot/pages/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iot/services/mqtt_client_wrapper.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notifi_service.dart';

FirebaseAuth auth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final mqttService = MQTTService();
  await mqttService.initializeMqttClient();
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().initNotification();
  runApp(IOTApp(mqttService: mqttService));
}

class IOTApp extends StatefulWidget {
  final MQTTService mqttService;

  const IOTApp({Key? key, required this.mqttService}) : super(key: key);

  @override
  _IOTAppState createState() => _IOTAppState();
}

class _IOTAppState extends State<IOTApp> {
  String mqttMessage = 'No messages yet';
  Uint8List? receivedImageBytes;

  @override
  void initState() {
    super.initState();
    // _setupMqttCallbacks();
    _sub('notif');
  }

  // void _setupMqttCallbacks() {
  //   widget.mqttService.onMessageReceived = (String topic, String message) {
  //     log('Received message: $message from topic: $topic from here');

  //     // Check for a specific topic and trigger a notification
  //     print('checking notif condition');
  //     if (topic == 'notif') {
  //       print('Condition true');
  //       NotificationService().showNotification(
  //         title: 'MQTT Notification',
  //         body: 'Message: $message from topic: $topic',
  //       );
  //     }

  //     setState(() {
  //       mqttMessage = message;
  //     });
  //   };

  //   widget.mqttService.onImageReceived = (Uint8List imageBytes) {
  //     print('Image received. Byte length: ${imageBytes.length}');
  //     setState(() {
  //       receivedImageBytes = imageBytes;
  //     });
  //   };
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        LoginPage.id: (context) => const LoginPage(),
        RegisterPage.id: (context) => const RegisterPage(),
        HomePage.id: (context) => HomePage(mqttService: widget.mqttService),
      },
      home: LoginPage(),
    );
  }

  @override
  void dispose() {
    widget.mqttService.disconnect();
    super.dispose();
  }

  void _sub(String topic) {
    widget.mqttService.subscribe(topic);
  }
}
