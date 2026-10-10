import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Android/iOS/desktop: TCP biasa ke port 1883.
MqttClient buatMqttClient(String host, String clientId) =>
    MqttServerClient(host, clientId)..port = 1883;
