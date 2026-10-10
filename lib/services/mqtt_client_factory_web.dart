import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Web: browser tidak bisa TCP, pakai WebSocket aman (wss) port 8084.
MqttClient buatMqttClient(String host, String clientId) =>
    MqttBrowserClient('wss://$host/mqtt', clientId)
      ..port = 8084
      ..websocketProtocols = MqttClientConstants.protocolsSingleDefault;
