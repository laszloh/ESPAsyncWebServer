// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright 2016-2025 Hristo Gochkov, Mathieu Carbou, Emil Muratov

//
// https://github.com/ESP32Async/ESPAsyncWebServer/discussions/23
//

#include <Arduino.h>
#include <AsyncTCP.h>
#include <WiFi.h>

#include <ESPAsyncWebServer.h>

static AsyncWebServer server(80);

void setup() {
  Serial.begin(115200);

  WiFi.mode(WIFI_AP);
  WiFi.softAP("esp-captive");

  server.begin();
  Serial.println("begin() - run: curl -v http://192.168.4.1/ => should succeed");
  delay(10000);

  Serial.println("end()");
  server.end();

  Serial.println("waiting before restarting server...");
  delay(100);

  server.begin();
  Serial.println("begin() - run: curl -v http://192.168.4.1/ => should succeed");
}

// not needed
void loop() {
  delay(100);
}
