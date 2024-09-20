import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:iot/services/mqtt_client_wrapper.dart';

class StreamPage extends HookWidget {
  static String id = '/StreamPage';
  final MQTTService mqttService;

  const StreamPage({Key? key, required this.mqttService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showStream = useState<bool>(true);

    void toggleStream() {
      showStream.value = !showStream.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance Stream'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: showStream.value
                  ? Mjpeg(
                      isLive: true,
                      error: (context, error, stack) {
                        print('Error: $error');
                        print('Stack Trace: $stack');
                        return Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.red),
                        );
                      },
                      stream: 'http://192.168.28.75:81/stream',
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  mqttService.publishMessage('door/response', '1'); 
                  print('Open Door pressed');
                },
                child: const Text('Let in'),
              ),
              ElevatedButton(
                onPressed: toggleStream,
                child: Text(showStream.value ? 'Hide Stream' : 'Show Stream'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  mqttService.publishMessage('door/response', '0');  
                  print('Don\'t Open Door pressed');
                },
                child: const Text("Reject"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
