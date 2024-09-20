import 'package:flutter/material.dart';
import 'package:iot/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iot/pages/login_page.dart';
import 'package:iot/pages/logs_page.dart';
import 'package:iot/pages/stream_page.dart';
import 'package:iot/services/mqtt_client_wrapper.dart';

class HomePage extends StatefulWidget {
  static const String id = '/HomePage';
  final MQTTService mqttService;

  const HomePage({Key? key, required this.mqttService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isLocked = true;  // Lock state

  void _onItemTapped(int index) {
    if (index == 3) {
      // Logout logic
      FirebaseAuth.instance.signOut().then((_) {
        Navigator.pushReplacementNamed(context, LoginPage.id);
      });
    } else {
      if (index == 2 && _selectedIndex != 2) {  // Going to StreamPage
        widget.mqttService.publishMessage('camera/stream', 'START');  // Send "START" when entering StreamPage
      } else if (_selectedIndex == 2 && index != 2) {  // Leaving StreamPage
        widget.mqttService.publishMessage('camera/stream', 'STOP');  // Send "STOP" when leaving StreamPage
      }
      setState(() {
        _selectedIndex = index;  // Update selected index
      });
    }
  }

  void _toggleLock() {
    final topic = 'servo/control'; 
    if (isLocked) {
      widget.mqttService.publishMessage(topic, '90');  // Unlock
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlocked: Message sent to topic: servo/control')),
      );
    } else {
      widget.mqttService.publishMessage(topic, '0');   // Lock
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locked: Message sent to topic: servo/control')),
      );
    }
    setState(() {
      isLocked = !isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Main Screen
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleLock,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked ? Colors.red : Colors.green,
                    ),
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLocked ? 'Locked' : 'Unlocked',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          LogsPage(mqttService: widget.mqttService),
          StreamPage(mqttService: widget.mqttService),  // Pass mqttService to StreamPage
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Surveillance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}