#include <WiFi.h>
#include <PubSubClient.h>

// Kredensial Wi-Fi
const char* ssid = "NAMA_WIFI";         // ganti dengan nama WiFi
const char* password = "PASSWORD_WIFI"; // ganti dengan password WiFi

// Pengaturan MQTT Broker (Menggunakan EMQX Public Broker)
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "florapulse/pompa/kontrol";

// ---- Identitas alat (tampil di aplikasi) ----
const char* DEVICE_ID = "FP-Desa-01";
const char* DEVICE_NAME = "Kotak Kebun Utama";
const int VALVES = 1;        // jumlah jalur kran/pompa
const int RELAY_PIN = -1;    // isi pin relay (mis. 26) kalau sudah pasang relay, -1 = belum ada
// ---------------------------------------------

// Topik untuk aplikasi menemukan alat
const char* discover_topic = "florapulse/discover";
String status_topic = String("florapulse/device/") + DEVICE_ID + "/status";

WiFiClient espClient;
PubSubClient client(espClient);
bool pompaNyala = false;
unsigned long lastStatus = 0;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Menghubungkan ke ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi terhubung.");
}

// Kirim kabar ke aplikasi: alat hidup + datanya
void kirimStatus() {
  String json = String("{\"id\":\"") + DEVICE_ID +
                "\",\"name\":\"" + DEVICE_NAME +
                "\",\"online\":true" +
                ",\"valves\":" + VALVES +
                ",\"battery\":null" +            // belum ada sensor baterai
                ",\"rssi\":" + WiFi.RSSI() +
                ",\"pump\":" + (pompaNyala ? "true" : "false") + "}";
  client.publish(status_topic.c_str(), json.c_str());
  lastStatus = millis();
  Serial.print("Status terkirim: ");
  Serial.println(json);
}

void setPompa(bool nyala) {
  pompaNyala = nyala;
  if (RELAY_PIN >= 0) digitalWrite(RELAY_PIN, nyala ? HIGH : LOW);
}

// Fungsi ini menangani pesan yang masuk dari aplikasi/Node-RED
void callback(char* topic, byte* message, unsigned int length) {
  String pesanTemp;
  for (int i = 0; i < length; i++) {
    pesanTemp += (char)message[i];
  }

  // Aplikasi sedang mencari alat -> jawab
  if (String(topic) == discover_topic) {
    Serial.println("Ping dari aplikasi, membalas...");
    kirimStatus();
    return;
  }

  // Logika memunculkan teks di terminal
  if (String(topic) == mqtt_topic) {
    if(pesanTemp == "1"){
      setPompa(true);
      Serial.println(">>> POMPA NYALA <<<");
      kirimStatus();   // konfirmasi ke aplikasi
    }
    else if(pesanTemp == "0"){
      setPompa(false);
      Serial.println(">>> POMPA MATI <<<");
      kirimStatus();   // konfirmasi ke aplikasi
    } else {
      Serial.print("Pesan tidak dikenali: ");
      Serial.println(pesanTemp);
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Menghubungkan ke MQTT Broker...");
    // Membuat Client ID unik
    String clientId = "ESP32-FloraPulse-Tester-";
    clientId += String(random(0, 1000));

    // Pesan "wasiat": dikirim broker otomatis kalau ESP32 mati mendadak
    String wasiat = String("{\"id\":\"") + DEVICE_ID + "\",\"online\":false}";

    if (client.connect(clientId.c_str(), status_topic.c_str(), 1, false, wasiat.c_str())) {
      Serial.println("Terhubung!");
      // ESP32 "mendengarkan" topik
      client.subscribe(mqtt_topic);
      client.subscribe(discover_topic);
      kirimStatus();
    } else {
      Serial.print("Gagal, status=");
      Serial.print(client.state());
      Serial.println(" Coba lagi dalam 5 detik...");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  if (RELAY_PIN >= 0) pinMode(RELAY_PIN, OUTPUT);
  setPompa(false);
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setBufferSize(512);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Kabari aplikasi tiap 10 detik bahwa alat masih hidup
  if (millis() - lastStatus > 10000) {
    kirimStatus();
  }
}
