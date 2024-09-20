#include "esp_camera.h"
#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>

#include "esp_timer.h"
#include "img_converters.h"
#include "Arduino.h"
#include "fb_gfx.h"
#include "soc/soc.h" //disable brownout problems
#include "soc/rtc_cntl_reg.h"  //disable brownout problems
#include "esp_http_server.h"
// #include "esp32_l298n.h"

// Select camera model
#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

// Flash
#define LED_BUILTIN 4

// MQTT config
bool useMQTT = true;
const char* topic_PHOTO = "sensor/ir";
const char* topic_PUBLISH = "camera/pics";
const char* topic_FLASH = "FLASH";
const char* topic_STREAM = "camera/stream";
const char* topic_key = "keypass";
const char* topic_logs = "camera/logs";
const char* topic_notif = "notif";
const int MAX_PAYLOAD = 60000;

const char* ssid = "Redmi Note 12";
const char* password = "body123123";
// const char *mqttServer = "6652dc6c5c4d485187be6cee7aee930a.s1.eu.hivemq.cloud";
// const char *mqttUser = "ed1234";
// const char *mqttPassword = "Ed123456";
const char *mqttServer = "d0016e1cc53c4b809d42197772564235.s1.eu.hivemq.cloud";
const char *mqttUser = "serag";
const char *mqttPassword = "Asd123!@#";

const int mqtt_port = 8883;  // Using SSL

bool flash;
bool streamEnabled = false;

WiFiClientSecure espClient;
PubSubClient client(espClient);

void stopStream();
void startStream();

#define PART_BOUNDARY "123456789000000000000987654321"

static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

httpd_handle_t stream_httpd = NULL;

static esp_err_t stream_handler(httpd_req_t *req){
  camera_fb_t * fb = NULL;
  esp_err_t res = ESP_OK;
  size_t _jpg_buf_len = 0;
  uint8_t * _jpg_buf = NULL;
  char * part_buf[64];

  res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  if(res != ESP_OK){
    return res;
  }

  while(streamEnabled){
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      res = ESP_FAIL;
    } else {
      if(fb->width > 250){
        if(fb->format != PIXFORMAT_JPEG){
          bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
          esp_camera_fb_return(fb);
          fb = NULL;
          if(!jpeg_converted){
            Serial.println("JPEG compression failed");
            res = ESP_FAIL;
          }
        } else {
          _jpg_buf_len = fb->len;
          _jpg_buf = fb->buf;
        }
      }
    }
    if(res == ESP_OK){
      size_t hlen = snprintf((char *)part_buf, 64, _STREAM_PART, _jpg_buf_len);
      res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
    }
    if(res == ESP_OK){
      res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
    }
    if(res == ESP_OK){
      res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
    }
    if(fb){
      esp_camera_fb_return(fb);
      fb = NULL;
      _jpg_buf = NULL;
    } else if(_jpg_buf){
      free(_jpg_buf);
      _jpg_buf = NULL;
    }
    if(res != ESP_OK){
      break;
    }
  }
  return res;
}

void startCameraServer(){
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 81;
  httpd_uri_t index_uri = {
    .uri       = "/stream",
    .method    = HTTP_GET,
    .handler   = stream_handler,
    .user_ctx  = NULL
  };
  
  // Serial.printf("Starting web server on port: '%d'\n", config.server_port);
  if (httpd_start(&stream_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(stream_httpd, &index_uri);
  }
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.println();

  // Config Camera Settings
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  if(psramFound()){
    config.frame_size = FRAMESIZE_UXGA;
    config.jpeg_quality = 8;
    config.fb_count = 2;
  } else {
    config.frame_size = FRAMESIZE_SVGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  flash = true;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    return;
  }

  sensor_t * s = esp_camera_sensor_get();
  if (s->id.PID == OV3660_PID) {
    s->set_vflip(s, 1);
    s->set_brightness(s, 1);
    s->set_saturation(s, -2);
  }
  s->set_framesize(s, FRAMESIZE_QVGA);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");

  startCameraServer();

  Serial.print("Camera Ready! Use 'http://");
  Serial.print(WiFi.localIP());
  // Serial.println("' to connect");

  espClient.setInsecure();
  client.setServer(mqttServer, mqtt_port);
  client.setBufferSize(MAX_PAYLOAD);
  client.setCallback(callback);
}

void callback(String topic, byte* message, unsigned int length) {
  String messageTemp;
  Serial.println(topic);
  for (int i = 0; i < length; i++) {
    messageTemp += (char)message[i];
  }
  if (topic == topic_PHOTO) {
    take_picture(topic_PUBLISH);
  }
  if (topic == topic_FLASH) {
    set_flash();
  }
  if (topic == topic_STREAM) {
    if (messageTemp == "START") {
      startStream();
    } else if (messageTemp == "STOP") {
      stopStream();
    }
  }
  if (topic == topic_key){
    if (messageTemp == "1") {
      take_picture(topic_logs);
      client.publish(topic_logs, "password Entry");
    }
    else if (messageTemp == "0") {  
      client.publish(topic_notif, "Wrong password try");      
    }
  }  
}

void startStream() {
  if (!streamEnabled) {
    Serial.println("Starting stream...");
    streamEnabled = true;
    startCameraServer();  // Starts the camera server
  }
}

void stopStream() {
  if (streamEnabled) {
    Serial.println("Stopping stream...");
    streamEnabled = false;
    if (stream_httpd != NULL) {
      httpd_stop(stream_httpd);  // Stops the camera server
      stream_httpd = NULL;
    }
  }
}

void take_picture(const char* topic) {
  camera_fb_t * fb = NULL;
  if(flash){ digitalWrite(LED_BUILTIN, HIGH); };
  Serial.println("Taking picture");
  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    return;
  }
  Serial.println("Picture taken");
  digitalWrite(LED_BUILTIN, LOW);
  sendMQTT(topic, fb->buf, fb->len);
  esp_camera_fb_return(fb);
}

void set_flash() {
  flash = !flash;
  Serial.print("Setting flash to ");
  Serial.println(flash);
  if (!flash) {
    for (int i = 0; i < 6; i++) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  } else {
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(500);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  }
}

void sendMQTT(const char* topic, const uint8_t * buf, uint32_t len) {
  Serial.println("Sending picture...");
  if (len > MAX_PAYLOAD) {
    Serial.print("Picture too large, increase the MAX_PAYLOAD value");
  } else {
    Serial.print("Picture sent ? : ");
    Serial.println(client.publish(topic, buf, len, false));
  }
}

void reconnect() {
  while (!client.connected()) {
    String client_id = "esp32-client-" + String(WiFi.macAddress());
    if (client.connect(client_id.c_str(), mqttUser, mqttPassword)) {
      Serial.println("Connected to MQTT Broker");
      client.subscribe(topic_PHOTO);
      client.subscribe(topic_STREAM);
      client.subscribe(topic_key);
    } else {
      Serial.print("Failed, state: ");
      Serial.println(client.state());
      delay(2000);
    }
  }
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}
