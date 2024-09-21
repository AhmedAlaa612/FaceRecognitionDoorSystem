
# Power Effecient Smart Door system with Facial Recognition ESP32-CAM


an IOT door system using

- ESP32
- ESP32-CAM
- openCV, face-recognition
- Flutter
- Firebase
- MQTT for communication
- HTTP for video streaming 



## Features
- door opens automatechly when someone is recognized
- enter door by password
- guests can click on a button to start a stream on owner's app so they can let guests in or tell them to leave
- complete log with pictures and date of everyone enters the door.
- control the door from the app and open live stream anytime
- get notifications when someone enters wrong password, or someone unknown is close to the door.


## Setup

1. upload the ESP32 code to an ESP32 board using platformIO
2. upload the espcam code to an ESP32-CAM
3. build the flutter app and run it
4. Run the Python face recognition script on a server (your computer, Raspberry Pi, or any other server) with the following command
```python
python faceRecognition.py
```




## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)

