#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <Keypad.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

const char* ssid = "Redmi Note 12";
const char* pass = "body123123";
// const char *mqtt_broker = "6652dc6c5c4d485187be6cee7aee930a.s1.eu.hivemq.cloud";
// const char *mqtt_username = "ed1234";
// const char *mqtt_password = "Ed123456";
const char *mqtt_broker = "d0016e1cc53c4b809d42197772564235.s1.eu.hivemq.cloud";
const char *mqtt_username = "serag";
const char *mqtt_password = "Asd123!@#";
const int mqtt_port = 8883;  // Using SSL


const char *topic_ir = "sensor/ir";  // Topic to publish IR sensor data
const char *topic_door = "servo/control";  // Topic to subscribe to for servo control
const char *topic_keypad = "keypass";
const char *topic_name = "person/name";
const char *topic_response = "door/response";
const char *topic_notif = "notif";
const char* topic_logs = "camera/logs";

WiFiClientSecure wifiClient;
PubSubClient client(wifiClient);
Servo servoMotor;

// Keypad setup
const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {12, 14, 27, 26};
byte colPins[COLS] = {25, 33, 32, 0};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);


String password = "1234";   // Pre-defined password
String inputPassword = "";  // User input

// LCD setup
LiquidCrystal_I2C lcd(0x27, 16, 2);

int buttonPin = 4;
int buzzerPin =23;
int ledPin = 2;
int buttonValue = 0;
int sensorValue = 0;
int servoAngle = 90;
int irpin = 34;
int servoPin = 13;

void callback(char* topic, byte* payload, unsigned int length);


void setup() {
    Serial.begin(115200);


    // Connect to Wi-Fi
    WiFi.begin(ssid, pass);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.println("Connecting to WiFi...");
    }
    Serial.println("Connected to WiFi");


    // Set up MQTT client
    wifiClient.setInsecure();
    client.setServer(mqtt_broker, mqtt_port);
    client.setCallback(callback);


    // Connect to MQTT broker
    while (!client.connected()) {
        String client_id = "esp32-client-" + String(WiFi.macAddress());
        if (client.connect(client_id.c_str(), mqtt_username, mqtt_password)) {
            Serial.println("Connected to MQTT Broker");
        } else {
            Serial.print("Failed, state: ");
            Serial.println(client.state());
            delay(2000);
        }
    }
    pinMode(buttonPin, INPUT);
    pinMode(buzzerPin, OUTPUT);
    pinMode(ledPin, OUTPUT);
    // Subscribe to the servo control topic
    client.subscribe(topic_name);
    client.subscribe(topic_door);
    client.subscribe(topic_response);

    // Initialize LCD
    lcd.init();
    lcd.backlight();
    lcd.setCursor(0, 0);
    lcd.print("enter password");


    // Initialize Servo
    servoMotor.attach(servoPin);

}


void loop() {
    client.loop();  // Ensure the MQTT client is actively checking for messages

    buttonValue = digitalRead(buttonPin);
    if (buttonValue == HIGH) {
        client.publish(topic_notif, "Someone is at the door");
        // set buzzer on
        digitalWrite(buzzerPin, HIGH);
        delay(2000);
        // set buzzer off
        digitalWrite(buzzerPin, LOW);
        delay(1000);
    }

    // password = "1234";
    char key = keypad.getKey();
    if (key) {
        if (key == '#') {  // Check password on '#'
            if (inputPassword == password) {
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("Password OK");
                client.publish(topic_keypad, "1");
                servoMotor.write(0);
                servoAngle = 0;
                delay(3000);
                servoMotor.write(90);
                servoAngle = 90;
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("enter password");
                inputPassword = "";
            } else {
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("Password Wrong");
                digitalWrite(buzzerPin, HIGH);
                digitalWrite(ledPin, HIGH);
                client.publish(topic_keypad, "0");
                inputPassword = "";
                delay(3000);
                digitalWrite(buzzerPin, LOW);
                digitalWrite(ledPin, LOW);
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("enter password");
            }
        } else if (key == '*') {
            inputPassword = "";  // Clear input on '*'
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("enter password");
        } else {
            inputPassword += key;  // Append key input to the password
            lcd.setCursor(0, 1);
            lcd.print(inputPassword);
    }
  }
    sensorValue = analogRead(irpin);
    if (sensorValue < 1000) {
        client.publish(topic_ir, "1");
        delay(2000);
    }

}
// Callback to handle incoming MQTT messages (for servo control)
void callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Message received in topic: ");
    Serial.println(topic);
    if (String(topic) == "servo/control") {


        char message[length + 1];
        memcpy(message, payload, length);
        message[length] = '\0';  // Null-terminate the payload

        int angle = atoi(message);  // Convert the payload to an integer (servo angle)
        if (angle == 90){
            servoMotor.write(90);
            servoAngle = 90;
        }
        else if (angle == 0){
            servoMotor.write(0);
            servoAngle = 0;
        }
    }
    if (String(topic) == topic_name){
        char message[length + 1];
        memcpy(message, payload, length);
        message[length] = '\0';  // Null-terminate the payload
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Hello, ");
        lcd.print(message);
        servoMotor.write(0);
        servoAngle = 0;
        delay(3000);
        servoMotor.write(90);
        servoAngle = 90;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("enter password");
    }
    if (String(topic) == topic_response){
        char message[length + 1];
        memcpy(message, payload, length);
        message[length] = '\0';  // Null-terminate the payload
        if (strcmp(message, "1") == 0){
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Welcome!");
            servoMotor.write(0);
            servoAngle = 0;
            delay(3000);
            servoMotor.write(90);
            servoAngle = 90;
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("enter password");
        }
        else if (strcmp(message, "0") == 0){
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Fuck off");
            delay(3000);
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("enter password");
        }
    }
}
