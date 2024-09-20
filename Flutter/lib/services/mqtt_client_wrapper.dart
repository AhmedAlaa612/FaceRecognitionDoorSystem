import 'dart:convert';
import 'dart:developer';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:typed_data/src/typed_buffer.dart';


class MQTTService {
  // Static instance of the class
  static final MQTTService _instance = MQTTService._internal();

  // Factory constructor to return the same instance
  factory MQTTService() {
    return _instance;
  }

  // Private named constructor
  MQTTService._internal({
    this.mqttServer = 'd0016e1cc53c4b809d42197772564235.s1.eu.hivemq.cloud',
    this.mqttUsername = 'serag',
    this.mqttPassword = 'Asd123!@#',
  });

  late MqttServerClient client;
  final String mqttServer;
  final String mqttUsername;
  final String mqttPassword;
  Function(String, String)? onMessageReceived;
  Function(Uint8List)? onImageReceived;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  Future<void> initializeMqttClient() async {
    _setupMqttClient();
    await _connectClient();
  }

  void _setupMqttClient() {
    client = MqttServerClient.withPort(mqttServer, mqttUsername, 8883);
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> _connectClient() async {
    try {
      print('MQTT client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(mqttUsername, mqttPassword);
    } catch (e) {
      print('Exception: $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('MQTT client connected');
    } else {
      print('ERROR MQTT client connection failed - disconnecting');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }


  void publishMessage(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic $topic');
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }

  void disconnect() {
    client.disconnect();
  }

// Future<void> publishImage(String topic, String imagePath) async {
//   try {
//     // Load image from assets or local file system
//     final ByteData byteData = await rootBundle.load(imagePath); // If it's an asset
//     final Uint8List imageBytes = byteData.buffer.asUint8List();

//     // Create a payload builder
//     final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    
//     // Add the image data as Uint8List using the extension
//     builder.addUint8List(imageBytes); // Use the extension method we created

//     // Publish the message to the specified topic
//     print('Publishing image to topic $topic');
//     client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
//   } catch (e) {
//     print('Error while publishing image: $e');
//   }
// }


  // void subscribe(String topic) {
  //   print('Subscribing to the $topic topic');
  //   client.subscribe(topic, MqttQos.atLeastOnce);

  //   client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
  //     final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
  //     final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

  //     print('Received message: $message from topic: ${c[0].topic}>');
  //     if (onMessageReceived != null) {
  //       onMessageReceived!(c[0].topic, message);
  //     }
  //   });
  // }

  // void subscribeToImage(String topic) {
  //   log('Subscribing to image topic: $topic');
  //   client.subscribe(topic, MqttQos.atLeastOnce);

  //   client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
  //     log('Received message on topic: ${c[0].topic}');
  //     final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
  //     log('Message type: ${recMess.header?.messageType}');
      
  //     final Uint8Buffer payload = recMess.payload.message;
  //     log('Payload length: ${payload.length}');
  //     log('First few bytes: ${payload.take(10).toList()}');

  //     // Convert Uint8Buffer to Uint8List
  //     final Uint8List imageBytes = Uint8List.fromList(payload.toList());

  //     if (onImageReceived != null) {
  //       log('Calling onImageReceived callback');
  //       onImageReceived!(imageBytes); // Pass the converted Uint8List instead
  //     } else {
  //       log('onImageReceived callback is null');
  //     }

  //   });
  // }

void subscribe(String topic) {
  print('Subscribing to topic: $topic');
  client.subscribe(topic, MqttQos.atLeastOnce);

  client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final Uint8Buffer payload = recMess.payload.message;

    print('Received message from topic: ${c[0].topic}');

    // Try to decode the payload as UTF-8
    String? decodedMessage;
    try {
      decodedMessage = utf8.decode(payload);
    } catch (e) {
      // If decoding fails, it's likely not a text message
      print('Failed to decode as text: $e');
    }

    if (decodedMessage != null && _isValidUtf8(decodedMessage)) {
      // Process as regular message
      print('Processing as text message');
      print('Received message: $decodedMessage');

      if (onMessageReceived != null) {
        onMessageReceived!(c[0].topic, decodedMessage);
      }
    } else {
      // Process as image data
      log('Processing as image data');
      log('Payload length: ${payload.length}');
      log('First few bytes: ${payload.take(10).toList()}');

      // Convert Uint8Buffer to Uint8List
      final Uint8List imageBytes = Uint8List.fromList(payload.toList());

      if (onImageReceived != null) {
        log('Calling onImageReceived callback');
        onImageReceived!(imageBytes);

      } else {
        log('onImageReceived callback is null');
      }
    }
  });
}

// Helper function to validate if a string is valid UTF-8
bool _isValidUtf8(String str) {
  try {
    utf8.encode(str);
    return true;
  } catch (e) {
    return false;
  }
}


}
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState {
  IDLE,
  SUBSCRIBED
}
extension PayloadBuilderExtension on MqttClientPayloadBuilder {
  void addUint8List(Uint8List imageBytes) {
    for (var byte in imageBytes) {
      addByte(byte);
    }
  }
}