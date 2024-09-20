import paho.mqtt.client as mqtt
import cv2
from simple_facerec import SimpleFacerec
import os

# MQTT settings
# mqtt_server = "6652dc6c5c4d485187be6cee7aee930a.s1.eu.hivemq.cloud"
# mqtt_user = "ed1234"
# mqtt_password = "Ed123456"
mqtt_server = "d0016e1cc53c4b809d42197772564235.s1.eu.hivemq.cloud"
mqtt_user = "serag"
mqtt_password = "Asd123!@#"
mqtt_port = 8883  # SSL Port
topic_sub = "camera/pics"
topic_name = "person/name"
topic_face = "person/face"

# Initialize the face recognizer
sfr = SimpleFacerec()
sfr.load_encoding_images("images/")  # Load known faces

# MQTT Callbacks
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
        client.subscribe(topic_sub)
    else:
        print("Failed to connect, return code:", rc)

def on_message(client, userdata, msg):
    # Save the image received from ESP32-CAM
    image_path = "captured_image.jpg"
    with open(image_path, "wb") as f:
        f.write(msg.payload)
    print(f"Image saved as '{image_path}'")

    # Read the saved image for face recognition
    frame = cv2.imread(image_path)

    if frame is None:
        print(f"Error: Could not read image from {image_path}")
    else:
        # Detect Faces
        face_locations, face_names = sfr.detect_known_faces(frame)

        if face_names:
            print("Recognized faces:", face_names)

            # Send recognized name to MQTT
            for name in face_names:
                if name != "Unknown":
                    client.publish(topic_name, name)
                    client.publish('camera/logs', name)
                    print(f"Sent name: {name} to topic: {topic_name}")

            # Draw rectangles and names on the faces
            for face_loc, name in zip(face_locations, face_names):
                y1, x2, y2, x1 = face_loc[0], face_loc[1], face_loc[2], face_loc[3]
                cv2.putText(frame, name, (x1, y1 - 10), cv2.FONT_HERSHEY_DUPLEX, 1, (0, 0, 200), 2)
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 200), 4)

            # Save the image with recognized faces
            recognized_image_path = "recognized_image.jpg"
            cv2.imwrite(recognized_image_path, frame)

            # Check if all faces are unknown and send notification
            if all(name == "Unknown" for name in face_names):
                client.publish("notf", "Unknown person detected")
            # Send recognized faces to the log and face topic
            else:
                for name in face_names:
                    if name != "Unknown":
                        with open(recognized_image_path, "rb") as f:
                            image_bytes = f.read()
                            client.publish(topic_face, image_bytes)
                            client.publish('camera/logs', image_bytes)
                            print(f"Sent recognized face to topic: {topic_face}")
        else:
            print("No known faces recognized.")

# Setup MQTT client
client = mqtt.Client()
client.username_pw_set(mqtt_user, mqtt_password)
client.tls_set()  # Using TLS

client.on_connect = on_connect
client.on_message = on_message

# Connect to MQTT Broker
client.connect(mqtt_server, mqtt_port) 
client.loop_forever()
