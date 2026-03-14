// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright 2016-2026 Hristo Gochkov, Mathieu Carbou, Emil Muratov, Will Miles

//
// HTTP Method usage example and check compatibility with Arduino HTTP Methods
//

#include <Arduino.h>

#if !defined(ESP8266)
// simulate asyncws project being used with another library using Arduino HTTP Methods
#include <HTTP_Method.h>
#endif

#if defined(ESP32) || defined(LIBRETINY)
#include <AsyncTCP.h>
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#include <ESPAsyncTCP.h>
#elif defined(TARGET_RP2040) || defined(TARGET_RP2350) || defined(PICO_RP2040) || defined(PICO_RP2350)
#include <RPAsyncTCP.h>
#include <WiFi.h>
#endif

#define ASYNCWEBSERVER_NO_GLOBAL_HTTP_METHODS 1
#undef HTTP_ANY
#include <ESPAsyncWebServer.h>

static AsyncWebServer server(80);

#if ASYNC_JSON_SUPPORT == 1
// https://github.com/ESP32Async/ESPAsyncWebServer/issues/404
static void handlePostTest(AsyncWebServerRequest *req, JsonVariant &json) {
  AsyncWebServerResponse *response;
  if (req->method() == WebRequestMethod::HTTP_POST) {
    response = req->beginResponse(200, "application/json", "{\"msg\": \"OK\"}");
  } else {
    response = req->beginResponse(501, "application/json", "{\"msg\": \"Not Implemented\"}");
  }
  req->send(response);
}
#endif

void setup() {
  Serial.begin(115200);

#if ASYNCWEBSERVER_WIFI_SUPPORTED
  WiFi.mode(WIFI_AP);
  WiFi.softAP("esp-captive");
#endif

  // curl -v http://192.168.4.1/get-or-post
  // curl -v -X POST -d "a=b" http://192.168.4.1/get-or-post
  server.on("/get-or-post", WebRequestMethod::HTTP_GET | WebRequestMethod::HTTP_POST, [](AsyncWebServerRequest *request) {
    request->send(200, "text/plain", "Hello");
  });

  // curl -v http://192.168.4.1/any
  server.on("/any", WebRequestMethod::HTTP_ANY, [](AsyncWebServerRequest *request) {
    request->send(200, "text/plain", "Hello");
  });

#if ASYNC_JSON_SUPPORT == 1
  // curl -v http://192.168.4.1/test => Not Implemented
  // curl -v -X POST -H 'Content-Type: application/json' -d '{"name":"You"}' http://192.168.4.1/test => OK
  AsyncCallbackJsonWebHandler *testHandler = new AsyncCallbackJsonWebHandler("/test", handlePostTest);
  server.addHandler(testHandler);
#endif

  server.begin();
}

// not needed
void loop() {
  delay(100);
}
